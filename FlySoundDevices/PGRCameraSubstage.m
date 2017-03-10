classdef PGRCameraSubstage < PGRCamera
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    properties
        deviceName = 'PGRCameraSubstage';
    end

    events
        %
    end
    
    methods
        function obj = PGRCameraSubstage(varargin)
            % This and the transformInputs function are hard coded
            
            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [0];
            obj.digitalOutputLabels = {'trigger'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [2];
            
            obj.cameraLocation = 'Substage';
            obj.format = 'Mono8_640x480';
            obj.camPortID = 2;
            obj.triggermode = 'externalTriggerMode0-Source0';
            obj.dispFunc = @display_frame;
            obj.setup;
        end
        
        function setup(obj,varargin)
            obj.videoInput = imaqfind('Tag',obj.cameraLocation);
            if ~isempty(obj.videoInput)
                obj.videoInput = obj.videoInput{1};
                obj.source = getselectedsource(obj.videoInput);
            else
                setup@PGRCamera(obj,varargin)
                set(obj.source,'FrameRate','60');
                obj.source.Strobe1 = 'On'; %% turn this on at the last minute
                obj.source.Strobe1Polarity = 'High';
            end
        end

    end
end
        
