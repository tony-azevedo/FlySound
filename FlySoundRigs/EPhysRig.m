classdef EPhysRig < Rig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    
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
            % setpref('AcquisitionHardware','Amplifier','MultiClamp700A') %
            % setpref('AcquisitionHardware','Amplifier','AxoPatch200B_2P') %
            % AxoPatch200B % AxoClamp2B % MultiClamp700B % AxoPatch200B_2P
            
            ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
            p = inputParser;
            p.PartialMatching = 0;
            p.addParameter('amplifier1Device','MultiClamp700A',@ischar);            
            parse(p,varargin{:});
            
            acqhardware = getpref('AcquisitionHardware');
            if isfield(acqhardware,'Amplifier') ...
                    && ~strcmp(acqhardware.Amplifier,'MultiClamp700B')...
                    && ~strcmp(acqhardware.Amplifier,'AxoPatch200B_2P');
                obj.addDevice('amplifier',acqhardware.Amplifier);
            elseif ~isfield(acqhardware,'Amplifier')
                ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
                obj.addDevice('amplifier',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            elseif strcmp(acqhardware.Amplifier,'AxoPatch200B_2P')
                obj.addDevice('amplifier',acqhardware.Amplifier,'Session',obj.aiSession);
            elseif strcmp(acqhardware.Amplifier,'MultiClamp700B')
                obj.addDevice('amplifier',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
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
        function changeSessionsFromMode(obj,amplifier,evnt)
            for i = 1:length(amplifier.outputPorts)
                % configure AO
                for c = 1:length(obj.aoSession.Channels)
                    if strcmp(obj.aoSession.Channels(c).ID,['ao' num2str(amplifier.outputPorts(i))])
                        ch = obj.aoSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.outputLabels{i};
                obj.outputs.portlabels{amplifier.outputPorts(i)+1} = amplifier.outputLabels{i};
                obj.outputs.device{amplifier.outputPorts(i)+1} = amplifier;
                % use the current vals to apply to outputs
            end
            
            for i = 1:length(amplifier.inputPorts)
                for c = 1:length(obj.aiSession.Channels)
                    if strcmp(obj.aiSession.Channels(c).ID,['ai' num2str(amplifier.inputPorts(i))])
                        ch = obj.aiSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.inputLabels{i};
                obj.inputs.portlabels{amplifier.inputPorts(i)+1} = amplifier.inputLabels{i};
                obj.inputs.device{amplifier.inputPorts(i)+1} = amplifier;
                obj.inputs.data.(amplifier.inputLabels{i}) = [];
            end
            obj.sessionColumnsAndIndices();
        end
    end
end
