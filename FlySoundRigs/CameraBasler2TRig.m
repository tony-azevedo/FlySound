classdef CameraBasler2TRig < CameraBaslerTwoAmpRig
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
    %                                               -> CameraBaslerPiezoEpi2TRig    
    properties (Constant)
        rigName = 'CameraBasler2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = CameraBasler2TRig(varargin)
        end

    end
    
    methods (Access = protected)
    end
end
