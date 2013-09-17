classdef EPhysRig < Rig
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = EPhysRig(varargin)
            % setpref('AcquisitionHardware','Amplifier','AxoPatch200B') % AxoClamp2B
            acqhardware = getpref('AcquisitionHardware');
            if isfield(acqhardware,'Amplifier')
                obj.addDevice('amplifier',acqhardware.Amplifier);
            else
                obj.addDevice('amplifier','AxoPatch200B');
            end
            addlistener(obj.devices.amplifier,'ModeChange',@obj.changeSessionsFromMode);
        end
        
        function in = run(obj,protocol,varargin)
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            in = run@Rig(obj,protocol,varargin{:});
        end
    end
    
    methods (Access = protected)
        function changeSessionsFromMode(obj,src,evnt)
            for i = 1:length(src.outputPorts)
                % configure AO
                for c = 1:length(obj.aoSession.Channels)
                    if strcmp(obj.aoSession.Channels(c).ID,['ao' num2str(src.outputPorts(i))])
                        ch = obj.aoSession.Channels(c);
                        break
                    end
                end
                ch.Name = src.outputLabels{i};
                obj.outputs.portlabels{src.outputPorts(i)+1} = src.outputLabels{i};
                obj.outputs.device{src.outputPorts(i)+1} = src;
                % use the current vals to apply to outputs
            end
            % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
            obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
            obj.outputs.datacolumns = obj.outputs.datavalues;
            
            for i = 1:length(src.inputPorts)
                for c = 1:length(obj.aiSession.Channels)
                    if strcmp(obj.aiSession.Channels(c).ID,['ai' num2str(src.inputPorts(i))])
                        ch = obj.aiSession.Channels(c);
                        break
                    end
                end
                ch.Name = src.inputLabels{i};
                obj.inputs.portlabels{src.inputPorts(i)+1} = src.inputLabels{i};
                obj.inputs.device{src.inputPorts(i)+1} = src;
                obj.inputs.data.(src.inputLabels{i}) = [];
            end
        end
    end
end
