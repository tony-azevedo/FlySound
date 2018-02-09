classdef CameraBaslerTwoAmpRig < TwoAmpRig
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
    %                   -> CameraBaslerTwoAmpRig    -> CameraBaslerEpi2TRig
    %                                               -> CameraBasler2TRig
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    methods
        function obj = CameraBaslerTwoAmpRig(varargin)
            obj.addDevice('camera','CameraBasler');            
            addlistener(obj,'StartTrialCamera',@obj.readyCamera);
            addlistener(obj,'EndTrial',@obj.resetCamera);
        end

        function in = run(obj,protocol,varargin)
            obj.devices.camera.setup(protocol);
            in = run@TwoAmpRig(obj,protocol,varargin{:});
        end
        
        function readyCamera(obj,fig,evnt,varargin)
            obj.devices.camera.start()
        end
        
        function resetCamera(obj,fig,evnt,varargin)
            obj.devices.camera.stop()
        end     

    end
    
    methods (Access = protected)
    end
end
