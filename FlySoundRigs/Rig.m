classdef Rig < handle
    
    properties (Constant, Abstract)
        rigName
        IsContinuous;
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
            obj.aiSession.NumberOfScans = length(protocol.x);
            obj.aoSession.Rate = protocol.params.samprateout;
            notify(obj,'StartRun');
            for n = 1:repeats
                while protocol.hasNext()
                    obj.setAOSession(protocol);
                    notify(obj,'StartTrial');
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
            
            for ch = 1:length(obj.aoSession.Channels)
                if isfield(out,obj.aoSession.Channels(ch).Name)
                    obj.outputs.datacolumns(:,ch) = out.(obj.aoSession.Channels(ch).Name);
                end
            end
        end
        
        function transformInputs(obj,in)
            for ch = 1:length(obj.aiSession.Channels)
                obj.inputs.data.(obj.aiSession.Channels(ch).Name) = in(:,ch);
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
            if isempty(obj.TrialDisplay) || ~ishghandle(obj.TrialDisplay) 
                scrsz = get(0,'ScreenSize');
                obj.TrialDisplay = figure(...
                    'Position',[4 scrsz(4)/3 560 420],...
                    'NumberTitle', 'off',...
                    'Name', 'Rig Display');%,...'DeleteFcn',@obj.setDisplay);
            end
        end
        
        function rigStruct = getRigStruct(obj)
            rigStruct.rigConstructor = str2func(obj.rigName);
            rigStruct.outputs = obj.outputs.portlabels;
            rigStruct.inputs = obj.inputs.portlabels;
            rigStruct.devices = obj.devices;
            rigStruct.timestamp = now;
        end
        
        function delete(obj)
            obj.aiSession.release;
            obj.aoSession.release;
            delete@handle(obj)
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
                    ch = obj.aoSession.addAnalogOutputChannel('Dev1',dev.outputPorts(i), 'Voltage');
                    ch.Name = dev.outputLabels{i};
                    obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
                    obj.outputs.device{dev.outputPorts(i)+1} = dev;
                    % use the current vals to apply to outputs
                end
                % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
                obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
                obj.outputs.datacolumns = obj.outputs.datavalues;

                for i = 1:length(dev.inputPorts)
                    ch = obj.aiSession.addAnalogInputChannel('Dev1',dev.inputPorts(i), 'Voltage'); 
                    ch.Name = dev.inputLabels{i};
                    obj.inputs.portlabels{dev.inputPorts(i)+1} = dev.inputLabels{i};
                    obj.inputs.device{dev.inputPorts(i)+1} = dev;
                    obj.inputs.data.(dev.inputLabels{i}) = [];
                end
                %obj.inputs.labels = obj.inputs.portlabels(strncmp(obj.inputs.portlabels,'',0));
            end
        end
        
        function chNames = getChannelNames(obj)
            for ch = 1:length(obj.aoSession.Channels)
                chNames.out{ch} = obj.aoSession.Channels(ch).Name;
            end
            for ch = 1:length(obj.aiSession.Channels)
                chNames.in{ch} = obj.aiSession.Channels(ch).Name;
            end
        end
    end
end
