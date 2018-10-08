classdef CameraBaslerTwin < CameraBasler
        
    properties
    end

    methods
        function obj = CameraBaslerTwin(varargin)
            
            % This and the transformInputs function are hard coded
            obj.modelSerialNumber = 'acA1300-200um (22728403)';

            obj.videoInput = [];
            obj.source = [];
            obj.fileDestination = 'C:\Users\tony\Acquisition\fly_movement_videos';
            obj.fileName = 'default_name';
            obj.living = 0;
            obj.format = 'Mono8';
            
            % To determine obj.camPortID, use imaqhwinfo('gentl'), should
            % give 2 Ids for paired camera
            obj.setCamPortID;
            
            obj.digitalInputLabels = {'exposure2'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [3];
            % obj.digitalInputPorts = [26];
            
            obj.digitalOutputLabels = {'trigger2'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [2];
            % obj.digitalOutputPorts = [27];

            obj.setupDevice();
        end
        
        function out = transformOutputs(obj,out,varargin)
            % rig = varargin{1};
            if ~isfield(out,'trigger2')
                fns = fieldnames(out);
                out.trigger2 = out.(fns{1});
                out.trigger2(:) = 0;
            else
            end
            triggers = (0:round(obj.params.SampsPerFrameBurstTrigger):length(out.trigger(:)))+1;
            triggers = [triggers;triggers+3;triggers+6];
            triggers = triggers(:);
            out.trigger2(triggers) = 1;
        end
                                                            
        function setLogging(obj,filename)
            [fn,D] = strtok(fliplr(filename),filesep);
            obj.fileName = fliplr(fn);
            obj.fileName = sprintf(obj.fileName,[datestr(now,30) '_cam' num2str(obj.camPortID) '.avi']); % yyyymmddTHHMMSS;
            obj.fileDestination = fliplr(D(2:end));
            % UPDATE 181003: save videos on F:\ in grayscale AVI to speed
            % up saving
            diskLogger = VideoWriter([fullfile(obj.fileDestination,obj.fileName)], 'Grayscale AVI');
            % diskLogger = VideoWriter([fullfile(obj.fileDestination,obj.fileName)], 'Motion JPEG AVI');
            % diskLogger.Quality = 85;
            diskLogger.FrameRate = obj.params.framerate;
            
            obj.videoInput.DiskLogger = diskLogger;
        end
        
    end
   
end
