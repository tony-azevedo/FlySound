classdef Rig < handle
    
    properties (Constant, Abstract)
        rigName;
    end
    
    properties (Hidden, SetAccess = protected)
        TrialDisplay
    end
    
    properties (SetAccess = protected)
        devices
        aiSession
        aoSession
        outputs
        inputs
        params
    end
    
    properties (SetAccess = private)
    end
    
    events
        StimulusOutsideBounds
        StartRun
        StartTrial
        SaveData
    end
    
    methods
        function obj = Rig(varargin)
            obj.aiSession = daq.createSession('ni');
            obj.aoSession = daq.createSession('ni');            
            obj.defineParameters();
            obj.params = obj.getDefaults();
        end
        
        function addDevice(obj,devicekey,deviceclass)
            eval(['obj.devices.(devicekey) = ' deviceclass ';']);
            obj.setSessions(devicekey);
        end
        
        function in = run(obj,protocol,varargin)
            if nargin>2
                repeats = varargin{1};
            else
                repeats = 1;
            end
            obj.setDisplay([],[],protocol);

            obj.aiSession.Rate = protocol.params.sampratein;
            obj.aiSession.DurationInSeconds = protocol.params.durSweep;
            obj.aoSession.Rate = protocol.params.samprateout;
            notify(obj,'StartRun');
            for n = 1:repeats
                while protocol.hasNext()
                    obj.setAOSession(protocol);
                    notify(obj,'StartTrial');

                    %obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
                    %obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
                    % Run in foreground
                    obj.aoSession.startBackground; % Start the session that receives start trigger first
                    
                    % Collect input
                    in = obj.aiSession.startForeground; % both amp and signal monitor input
                    obj.transformInputs(in);
                    notify(obj,'SaveData');
                    obj.displayTrial(protocol);
                end
                protocol.reset;
            end
        end
                        
        function setAOSession(obj,protocol)
            % figure out what the stim vector should be
            obj.transformOutputs(protocol.next());
            obj.aoSession.wait;
            obj.aoSession.queueOutputData(obj.outputs.datacolumns);
        end
                        
        function transformOutputs(obj,out)
            
            % loop over devices, transforming data
            devs = fieldnames(obj.devices);
            for d = 1:length(devs)
                dev = obj.devices.(devs{d});
                if ~isempty(dev)
                    out = dev.transformOutputs(out);
                end
            end
            
            % make the stims the right size (keeping the array if it's the
            % same
            outnames = fieldnames(out);
            if size(obj.outputs.datacolumns,1) ~= length(out.(outnames{1}))
                if sum(obj.outputs.datavalues ~= obj.outputs.datacolumns(end,:))
                    obj.outputs.datavalues = obj.outputs.datacolumns(end,:);
                end
                % column array of outputs from the outvalues vector
                obj.outputs.datacolumns = repmat(obj.outputs.datavalues(:)',...
                    length(out.(outnames{1})),1);
            end
            
            % get outvals end values just in case
            if sum(obj.outputs.datavalues ~= obj.outputs.datacolumns(end,:))
                obj.outputs.datavalues = obj.outputs.datacolumns(end,:);
                for c = 1:size(obj.outputs.datacolumns,2)
                    obj.outputs.datacolumns(:,c) = obj.outputs.datavalues(c);
                end
            end
            
            for ol = 1:length(outnames)
                obj.outputs.datacolumns(:,strcmp(obj.outputs.labels,outnames{ol})) = out.(outnames{ol});
            end
        end
        
        function transformInputs(obj,in)
            for il = length(obj.inputs.labels):-1:1;
                obj.inputs.data.(obj.inputs.labels{il}) = in(:,il);
            end
            devs = fieldnames(obj.devices);
            for d = 1:length(devs)
                dev = obj.devices.(devs{d});
                if ~isempty(dev)
                    obj.inputs.data = dev.transformInputs(obj.inputs.data);
                end
            end
        end
                        
        function setParams(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                p.addParamValue(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                obj.params.(results{r}) = p.Results.(results{r});
            end
        end
        
        function defaults = getDefaults(obj)
            defaults = getpref(['defaults',obj.rigName]);
            if isempty(defaults)
                defaultsnew = [fieldnames(obj.params),struct2cell(obj.params)]';
                obj.setDefaults(defaultsnew{:});
                defaults = obj.params;
            end
        end
        
        function setDefaults(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                addOptional(p,names{i},obj.params.(names{i}));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                setpref(['defaults',obj.rigName],...
                    [results{r}],...
                    p.Results.(results{r}));
            end
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            scrsz = get(0,'ScreenSize');
            
            obj.TrialDisplay = figure(...
                'Position',[4 scrsz(4)/3 560 420],...
                'NumberTitle', 'off',...
                'Name', 'Rig Display');%,...'DeleteFcn',@obj.setDisplay);
            if nargin>3
                protocol = varargin{1};
                set(obj.TrialDisplay,'UserData',makeTime(protocol));
                %                 h = guidata(obj.TrialDisplay);
                %                 h.time = makeTime(protocol);
                %                 guidata(obj.TrialDisplay,h);
                %
            end
        end
        
    end
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
        end
        
        function setSessions(obj,varargin)
            % Establish all the output channels and input channels in one
            % place
            if nargin>1
                keys = varargin;
            else
                keys = fieldnames(obj.devices);
            end
            for k = 1:length(keys);
                dev = obj.devices.(keys{k});
                for i = 1:length(dev.outputPorts)
                    % configure AO
                    obj.aoSession.addAnalogOutputChannel('Dev1',dev.outputPorts(i), 'Voltage'); 
                    obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
                    obj.outputs.device{dev.outputPorts(i)+1} = dev;
                    % use the current vals to apply to outputs
                end
                obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
                obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
                obj.outputs.datacolumns = obj.outputs.datavalues;

                for i = 1:length(dev.inputPorts)
                    obj.aiSession.addAnalogInputChannel('Dev1',dev.inputPorts(i), 'Voltage'); 
                    obj.inputs.portlabels{dev.inputPorts(i)+1} = dev.inputLabels{i};
                    obj.inputs.device{dev.inputPorts(i)+1} = dev;
                    obj.inputs.data.(dev.inputLabels{i}) = [];
                end
                obj.inputs.labels = obj.inputs.portlabels(strncmp(obj.inputs.portlabels,'',0));
            end
        end
    
        
    end
end
