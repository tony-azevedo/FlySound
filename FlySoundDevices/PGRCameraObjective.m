classdef PGRCameraObjective < PGRCamera
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    properties
        deviceName = 'PGRCameraObjective';
    end

    events
        %
    end
    
    methods
        function obj = PGRCameraObjective(varargin)
            % This and the transformInputs function are hard coded
            
            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [4];
            obj.digitalOutputLabels = {'trigger'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [7];
            
            obj.cameraLocation = 'Objective';
            obj.format = 'F7_Mono16_1280x1024_Mode0'; %'F7_Mono8_1280x1024_Mode0', 'F7_Raw8_1280x1024_Mode0'
            obj.camPortID = 1;
            obj.triggermode = 'externalTriggerMode0-Source0';
            obj.triggerpolarity = 'risingEdge';         
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
                pi = propinfo(obj.source,'Shutter');
                if max(pi.ConstraintValue)<20
                    error('Shutter constraint is too low')
                end

                set(obj.source,'FrameRatePercentageMode','Manual');
                set(obj.source,'FrameRatePercentage',100)
                set(obj.source,'GainMode','Manual')
                set(obj.source,'ExposureMode','Manual')
                set(obj.source,'ShutterMode','Manual')
            end
            set(obj.source,'Shutter',20);
            obj.source.Strobe3 = 'On'; %% turn this on at the last minute
            obj.source.Strobe3Polarity = 'High';
%             obj.live()
%             pause
%             obj.dead()

        end
        
        function setLogging(obj,filename)
            
            % for the chameleon objective camera, the Mono16 format allows
            % long shutter durations which work with the trigger. That
            % requires using the motion jpeg format that supports a bit
            % depth of 16.
            
            [fn,D] = strtok(fliplr(filename),filesep);
            obj.fileName = fliplr(fn(5:end));
            obj.fileDestination = fliplr(D(2:end));
            diskLogger = VideoWriter([fullfile(obj.fileDestination,obj.fileName)], 'Motion JPEG 2000');
            obj.videoInput.DiskLogger = diskLogger;
        end
    
    end
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.setup = 'x Frames, write in the rest of the information';
            obj.params.framerate = 30;
            obj.params.Nframes = 30;
        end
    end

end
        
%             obj.digitalInputLabels = {'exposure'};
%             obj.digitalInputUnits = {'Bit'};
%             obj.digitalInputPorts = [0];
%             obj.digitalOutputLabels = {'trigger'};
%             obj.digitalOutputUnits = {'Bit'};
%             obj.digitalOutputPorts = [2];
% 
%             obj.videoInput = videoinput('pointgrey', 2, 'Mono8_640x480','Tag','SubStage');
        
