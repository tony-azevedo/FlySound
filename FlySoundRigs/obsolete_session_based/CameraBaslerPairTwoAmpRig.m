classdef CameraBaslerPairTwoAmpRig < TwoAmpRig
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
        function obj = CameraBaslerPairTwoAmpRig(varargin)
            obj.addDevice('camera','CameraBasler');            
            obj.addDevice('cameratwin','CameraBaslerTwin');            
            addlistener(obj,'StartTrialCamera',@obj.readyCamera);
            addlistener(obj,'EndTrial',@obj.resetCamera);
        end

        function in = run(obj,protocol,varargin)
            obj.devices.camera.setup(protocol);
            obj.devices.cameratwin.setup(protocol);
            in = run@TwoAmpRig(obj,protocol,varargin{:});
        end
        
        function readyCamera(obj,fig,evnt,varargin)
            obj.devices.camera.start()
            obj.devices.cameratwin.start()
        end
        
        function resetCamera(obj,fig,evnt,varargin)
            obj.devices.camera.stop()
            obj.devices.cameratwin.stop()
            obj.devices.camera.quickpeak()
            obj.devices.cameratwin.quickpeak()
        end     

    end
    
    methods (Access = protected)
    end
end
