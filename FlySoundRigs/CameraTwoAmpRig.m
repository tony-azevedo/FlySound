classdef CameraTwoAmpRig < TwoAmpRig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig
    %       -> TwoAmpRig -> TwoTrodeRig
    %                   -> Epi2TRig
    %                   -> CameraTwoAmpRig    -> CameraEpi2TRig
    %                                         -> Camera2TRig
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    methods
        function obj = CameraTwoAmpRig(varargin)
            obj.addDevice('camera','Camera');
            obj.aiSession.addTriggerConnection('External','Dev1/PFI0','StartTrigger') % start trigger from the camera
            obj.aiSession.ExternalTriggerTimeout = 60; % start trigger from the camera
            
%             rigDev = getpref('AcquisitionHardware','rigDev');
%             triggerChannelIn = getpref('AcquisitionHardware','triggerChannelIn');
%             triggerChannelOut = getpref('AcquisitionHardware','triggerChannelOut');
            
            addlistener(obj,'StartTrial',@obj.readyCamera);
            addlistener(obj,'EndTrial',@obj.stopCameraTriggering);
        end

        function in = run(obj,protocol,varargin)
            dur = protocol.params.durSweep;
            frametime = 1/obj.devices.camera.params.framerate;
            Nframes = floor((dur-.25)/frametime);
            str = sprintf('%s\n%s\n%s%s\n\n%s\n%s\n\n%s%.1f sec, %d frames',...
                'Ready the camera:',...
                ' - Set Directory',...
                ' - Set Prefix: ',...
                [protocol.protocolName '_Image'],...
                'Mode: 0, Trigger polarity high, raw 8',...
                'Video, streaming, m-jpeg, 85 quality',...
                ' - Acq for ',...
                protocol.params.durSweep,...
                Nframes);
            

            clipboard('copy',[protocol.protocolName '_Image']);
            h = msgbox(str,'CAMERA SETUP');
            pos = get(h,'position');
            set(h, 'position',[696 125 pos(3) pos(4)])
            uiwait(h);
            
            in = run@TwoAmpRig(obj,protocol,varargin{:});
        end
        
        function readyCamera(obj,fig,evnt,varargin)
            
            dur = evnt.protocol.params.durSweep;
            frametime = 1/obj.devices.camera.params.framerate;
            Nframes = floor((dur-.25)/frametime);

            str = sprintf('Rig ready for trigger:\n%.5f frames',Nframes);
            h = msgbox(str,'CAMERA','replace');
            pos = get(h,'position');
            set(h, 'position',[600 178 pos(3) pos(4)])
            
            %clipboard('copy',sprintf('%d',Nframes));

            uiwait(h);

        end
        
        function stopCameraTriggering(obj,fig,evnt,varargin)
            
            str = sprintf('Stop the triggering;\nThen wait for frame acquisition to finish');
            h = msgbox(str,'CAMERA','replace');
            pos = get(h,'position');
            %set(h, 'position',[1280 700 pos(3) pos(4)])
            set(h, 'position',[600 178 pos(3) pos(4)])
            
            %clipboard('copy',sprintf('%d',Nframes));

            uiwait(h);

        end

                

    end
    
    methods (Access = protected)
    end
end
