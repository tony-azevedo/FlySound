classdef TwoPhotonRig < EPhysRig
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    methods
        function obj = TwoPhotonRig(varargin)
            obj.addDevice('twophoton','TwoPhotonSystem');
            obj.aiSession.addTriggerConnection('Dev3/PFI6','External','StartTrigger'); % Note, the 2P has a Dev3 nidaq, not Dev1
            obj.aoSession.addTriggerConnection('External','Dev3/PFI2','StartTrigger');
            addlistener(obj,'StartTrial',@obj.readyTwoPhoton);
        end

        function in = run(obj,protocol,varargin)
            str = sprintf('%s\n%s\n%s%s\n\n%s\n%s\n\n%s%.4f sec',...
                'Ready the TwoPhoton:',...
                ' - Set Directory',...
                ' - Set Prefix: ',...
                [protocol.protocolName '_Image_'],...
                'Capture Mode: External Start Trigger',...
                '{OUT TRIG Source, polarity, Kind} = {Exposure, positive, Exposure}',...
                ' - Acq for ',...
                protocol.params.durSweep - 0.002);
            
            clipboard('copy',[protocol.protocolName '_Image_']);
            h = msgbox(str,'2P SETUP');
            pos = get(h,'position');
            %set(h, 'position',[1280 600 pos(3) pos(4)])
            set(h, 'position',[5 658 pos(3) pos(4)])
            uiwait(h)
            
            in = run@EPhysRig(obj,protocol,varargin{:});
        end
        
        function readyTwoPhoton(obj,fig,evnt,varargin)
            % The loop function on the 2P obviates this function
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            error('This routine should never run')
        end
        
        function displayTrial(obj,protocol)
            error('This routine should never run')
        end

    end
    
    methods (Access = protected)
        function setSessions(obj,varargin)
            % Establish all the output channels and input channels in one
            % place
            % The TwoPhotonRigs use a Dev3 device.
            if nargin>1
                keys = varargin;
            else
                keys = fieldnames(obj.devices);
            end
            for k = 1:length(keys);
                dev = obj.devices.(keys{k});
                for i = 1:length(dev.outputPorts)
                    % configure AO
                    ch = obj.aoSession.addAnalogOutputChannel('Dev3',dev.outputPorts(i), 'Voltage');
                    ch.Name = dev.outputLabels{i};
                    obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
                    obj.outputs.device{dev.outputPorts(i)+1} = dev;
                    % use the current vals to apply to outputs
                end
                % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
                obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
                obj.outputs.datacolumns = obj.outputs.datavalues;
                
                for i = 1:length(dev.inputPorts)
                    ch = obj.aiSession.addAnalogInputChannel('Dev3',dev.inputPorts(i), 'Voltage');
                    ch.InputType = 'SingleEnded';  %%????
                    ch.Name = dev.inputLabels{i};
                    obj.inputs.portlabels{dev.inputPorts(i)+1} = dev.inputLabels{i};
                    obj.inputs.device{dev.inputPorts(i)+1} = dev;
                    % obj.inputs.data.(dev.inputLabels{i}) = [];
                end
            end
        end

    end
end
