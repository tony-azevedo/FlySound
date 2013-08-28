classdef Rig < handle
    
    properties (Constant, Abstract)
        rigName;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        devices
        aiSession
        aoSession
        outputs
        inputs
        params
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
            % obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            % obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
            obj.createRigParameters();
        end
        
        function addDevice(obj,devicekey,deviceclass)
            eval(['obj.devices.(devicekey) = ' deviceclass]);
            obj.setSessions(devicekey);
        end
        
        function in = run(obj,protocol)
            obj.aiSession.Rate = protocol.params.sampratein;
            obj.aiSession.DurationInSeconds = protocol.params.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;
            
            notify(obj,'StartRun');
            while protocol.hasNext()
                notify(obj,'StartRun');
                
                obj.setAOSession(protocol);
                obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
                obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
                % Run in foreground
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                
                % Collect input
                in = obj.aiSession.startForeground; % both amp and signal monitor input
                obj.transformInputs(in);
                notify(obj,'SaveData');
            end
        end
                        
        function setAOSession(obj)
            % figure out what the stim vector should be
            obj.transformOutputs(protocol.next());
            obj.aoSession.wait;
            obj.aoSession.queueOutputData(obj.outputs.datacolumns);
        end
                        
        function transformOutputs(obj,out)
            
            % loop over devices, transforming data
            for d = 1:length(obj.outputs.dev)
                dev = obj.outputs.dev{d};
                out = dev.transformOutputs(out);
            end
            
            % make the stims the right size (keeping the array if it's the
            % same
            if size(obj.outputs.dataarray,1) ~= length(out.(obj.outputs.labels{1}))
                if sum(obj.outputs.outvalues ~= obj.outputs.datacolumns(end,:))
                    obj.outputs.outvalues = obj.outputs.datacolumns(end,:);
                end
                % column array of outputs from the outvalues vector
                obj.outputs.datacolumns = repmat(obj.outputs.outvalues(:)',...
                    obj.outputs.outvalues,1);
            end
            
            % get outvals end values just in case
            if sum(obj.outputs.outvalues ~= obj.outputs.datacolumns(end,:))
                obj.outputs.outvalues = obj.outputs.datacolumns(end,:);
                for c = 1:size(obj.outputs.datacolumns)
                    obj.outputs.datacolumns(:,c) = obj.outputs.outvalues(c);
                end
            end
            
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                obj.outputs.datacolumns(:,strcmp(obj.outputs.labels,outlabels{ol})) = out.(outlabels{ol});
            end
        end
        
        function transformInputs(obj,in)
            for il = 1:length(obj.input.labels)
                obj.inputs.data.(obj.inputs.labels{il}) = in(:,il);
            end
            for d = 1:length(obj.inputs.dev)
                dev = obj.inputs.dev{d};
                obj.inputs.data = dev.transformInputs(obj.inputs.data);
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
            obj.setupStimulus
            obj.showParams
        end
        
        function saveRigParams()
            
        end
    end
    
    methods (Access = protected)
        
        function createRigParameters(obj)
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
