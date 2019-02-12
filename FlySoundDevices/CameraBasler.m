classdef CameraBasler < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        videoInput
        source
        fileDestination
        fileName
        camPortID
        format
        living
        modelSerialNumber
        exampleframe
        snapshotax
        snapshotfigure
        dwnsamp
        displayimgobject
    end
    
    properties
        deviceName = 'CameraBasler';
    end

    events
        %
    end
    
    methods
        function obj = CameraBasler(varargin)
            % This and the transformInputs function are hard coded
            
            obj.modelSerialNumber = 'acA1300-200um (22366722)'; % Stable identifier of the camera

            obj.videoInput = [];
            obj.source = [];
            obj.fileDestination = 'C:\Users\tony\Acquisition\fly_movement_videos';
            obj.fileName = 'default_name';
            obj.living = 0;
            obj.format = 'Mono8';
            
            % Use the modelSerialNumber to get the camportID
            obj.setCamPortID;
            
            % Current setup at time of writing 181011:
            % Gray cable is going to camerabaslerTwin
            % Black cable with elbow connection going to CameraBasler
            % Gray cable controls the following lines, either here or in Pylonviewer:
            %   Line 3 - exposure output from camera - input to dac - brown cable - port 3 (jack 68)
            %   Line 4 - trigger input to camera - output from dac - green cable - port 2 (jack 67)
            % Black cable controls the following lines, either here or in Pylonviewer:
            %   Line 3 - exposure output from camera - input to dac - grey cable - port 26 (jack 117)
            %   Line 4 - trigger input to camera - output from dac - green cable - port 27 (jack 119)
            
            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            % UPDATE 181003: This becomes [26] when a second camera is
            % added
            % obj.digitalInputPorts = [3];
            obj.digitalInputPorts = [26];
            
            obj.digitalOutputLabels = {'trigger'};
            obj.digitalOutputUnits = {'Bit'};
            % UPDATE 181003: This becomes [26] when a second camera is
            % added
            % obj.digitalOutputPorts = [2];
            obj.digitalOutputPorts = [27];
            if ~isa(obj,'CameraBaslerTwin')
                obj.setupDevice();
            end
        end
        
        function setCamPortID(obj)
            % To determine obj.camPortID, use imaqhwinfo('gentl'), should
            % give 2 Ids for paired camera
            % each camera subclass should specify it's modelSerialNumber
            hwi = imaqhwinfo('gentl');
            devinfo = false(size(1:numel(hwi.DeviceInfo)));
            for idx = 1:length(devinfo)
                devinfo(idx) = strcmp(hwi.DeviceInfo(idx).DeviceName,obj.modelSerialNumber);
            end
            obj.camPortID = find(devinfo);
        end

        function obj = setup(obj,protocol)
            obj.params.Nframes = floor(obj.params.framerate*protocol.params.durSweep)-1;
            obj.videoInput.FramesPerTrigger = obj.params.Nframes;
            obj.params.SampsPerFrameBurstTrigger = ceil(double(obj.source.AcquisitionBurstFrameCount)/obj.params.framerate * protocol.params.samprateout);
        end
        
        function varargout = transformInputs(obj,inputstruct,varargin)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                if strcmp(inlabels{il},'exposure')
                    units = {'bit'};
                   
                    % currently keeping this raw, decide what to do postHoc
                    % inputstruct.exposure = inputstruct.exposure > 0.5;
                    % inputstruct.exposure = ...
                    %     [inputstruct.exposure(2:end) - inputstruct.exposure(1:end-1); 0];
                    % inputstruct.exposure = inputstruct.exposure > 0;
                end
            end
            varargout = {inputstruct,units};
        end
        
        function out = transformOutputs(obj,out,varargin)
            % rig = varargin{1};
            if ~isfield(out,'trigger')
                fns = fieldnames(out);
                out.trigger = out.(fns{1});
                out.trigger(:) = 0;
            else
            end
            triggers = (0:round(obj.params.SampsPerFrameBurstTrigger):length(out.trigger(:)))+1;
            triggers = [triggers;triggers+3;triggers+6];
            triggers = triggers(:);
            out.trigger(triggers) = 1;
        end
    
        function live(obj)    
            preview(obj.videoInput)
            obj.living = 1;
            obj.source.TriggerMode = 'off';
        end
        
        function dead(obj)
            obj.source.TriggerMode = 'on';
            stoppreview(obj.videoInput)
            obj.living = 0;
        end
        
        function start(obj)
            if obj.living && strcmp(obj.videoInput.preview,'on')
                obj.dead;
            end
            if ~isa(obj,'CameraBaslerTwin')
                
                set(obj.videoInput,'FramesAcquiredFcnCount',20);
                set(obj.videoInput,'FramesAcquiredFcn',@display_cam1_frame)
                display_cam1_frame(obj.videoInput,[],obj.exampleframe,obj.snapshotax,obj.displayimgobject);
                % test persistence of variables
                % display_cam1_frame(obj.videoInput,[],obj.exampleframe);
            end
            figure(obj.snapshotfigure);
            start(obj.videoInput);
            obj.living = 1;
            fprintf('\n\t\t\tVideo started: %d of %d Triggers/Frames\n\t\t\t\tFilename:\t%s\n\t\t\t\tFilepath:\t%s\n',...
                obj.videoInput.FramesAcquired,obj.videoInput.TriggerRepeat+1,get(obj.videoInput.DiskLogger,'Filename'),get(obj.videoInput.DiskLogger,'Path'))
        end
        
        function stop(obj)
            if obj.videoInput.FramesAcquired ~= obj.videoInput.DiskLoggerFrameCount
                fprintf('Logging Video:')
                while ( obj.videoInput.FramesAcquired ~= obj.videoInput.DiskLoggerFrameCount)
                    fprintf('.')
                    pause(.05);
                end
                fprintf('\n');
            end

            fprintf('\t\t\tCam %d - Triggers fired: %d of %d. Logger logged %d frames.\n',obj.camPortID, obj.videoInput.TriggersExecuted,obj.videoInput.TriggerRepeat+1,obj.videoInput.DiskLoggerFrameCount)
            stop(obj.videoInput)
            obj.living = 0;
        end
        
        function quickpeak(obj)
            frame = getExampleFrame(obj);
            obj.displayimgobject.CData(:) = frame(obj.dwnsamp);
            drawnow
        end

        function varargout = status(obj)
            s = sprintf('Triggers fired: %d of %d. Logger logged %d frames.\n',obj.videoInput.TriggersExecuted,obj.videoInput.TriggerRepeat+1,obj.videoInput.DiskLoggerFrameCount);
            missedFrames = obj.videoInput.TriggerRepeat+1 - obj.videoInput.TriggersExecuted;
            varargout = {obj.videoInput.Running,s,missedFrames};
        end
        
        function setLogging(obj,filename)
            [fn,D] = strtok(fliplr(filename),filesep);
            obj.fileName = fliplr(fn);
            obj.fileName = sprintf(obj.fileName,[datestr(now,30) '.avi']); % yyyymmddTHHMMSS;
            obj.fileDestination = fliplr(D(2:end));
            % UPDATE 181003: save videos on F:\ in grayscale AVI to speed
            % up saving
            diskLogger = VideoWriter(fullfile(obj.fileDestination,obj.fileName), 'Grayscale AVI');
            % diskLogger = VideoWriter([fullfile(obj.fileDestination,obj.fileName)], 'Motion JPEG AVI');
            % diskLogger.Quality = 85;
            diskLogger.FrameRate = obj.params.framerate;
            
            obj.videoInput.DiskLogger = diskLogger;
        end
        
        function frame = getExampleFrame(obj)
            obj.source.TriggerSelector = 'FrameBurstStart';
            obj.source.TriggerMode = 'Off';
            triggerconfig(obj.videoInput, 'manual')
            obj.exampleframe = getsnapshot(obj.videoInput);
            
            triggerconfig(obj.videoInput, 'hardware');

            obj.source.TriggerSelector = 'FrameBurstStart';
            obj.source.TriggerMode = 'On';
            frame = obj.exampleframe;
        end

    end
    
    methods (Access = protected)
        function setupDevice(obj)        
            
            % Only start a new video object if this one still exists.
            [~,result] = system('tasklist /FI "imagename eq PylonViewerApp.exe" /fo table /nh');
            if ~isempty(regexp(result,'PylonViewerApp','once'))
                fprintf('Turn off Pylon software');
                h = warndlg('Turn off Pylon software');
                uiwait(h)
                fprintf('\n')
                % imaqreset
                [~,result] = system('tasklist /FI "imagename eq PylonViewerApp.exe" /fo table /nh');
                if ~isempty(regexp(result,'PylonViewerApp','once'))
                    fprintf('Pylon software still on\n');
                    beep
                end
            end
            imaqs = imaqfind('DeviceID',obj.camPortID);
            if isempty(obj.videoInput) && ~isempty(imaqs)
                for dev = 1:length(imaqs)
                    delete(imaqs{dev});
                end
            end
            obj.videoInput = videoinput('gentl', obj.camPortID, obj.format); %vid = videoinput('gentl', 1, 'Mono8');
            obj.source = getselectedsource(obj.videoInput);

            % Set up ROIs
            obj.source.CenterX = obj.params.ROICenterX;
            obj.source.CenterY = obj.params.ROICenterY;
            obj.videoInput.ROIPosition = [obj.params.ROIOffsetX obj.params.ROIOffsetY obj.params.ROIWidth obj.params.ROIHeight];

            if isa(obj,'CameraBaslerTwin')
                obj.source.ReverseX = 'True';
            end

            % Get a frame to set other properties of the cameraBasler
            % object
            obj.source.TriggerSelector = 'FrameStart';
            obj.source.TriggerMode = 'Off';
            obj.source.TriggerSelector = 'FrameBurstStart';
            obj.source.TriggerMode = 'Off';
            triggerconfig(obj.videoInput, 'manual');
            obj.exampleframe = getsnapshot(obj.videoInput);
            
            % Setup source and pulses etc
            triggerconfig(obj.videoInput, 'hardware');
            obj.videoInput.TriggerRepeat = 0;
            obj.videoInput.FramesPerTrigger = obj.params.Nframes;
            obj.videoInput.LoggingMode = 'disk&memory';
            
            % Set up for triggering and exposure signals
            obj.source.LineSelector = 'Line3';             % brings up settings for line3
            obj.source.LineMode = 'output';                % should be 'output'
            obj.source.LineInverter = 'True';                % should be 'output'
            obj.source.LineSource = 'ExposureActive';

            obj.source.LineSelector = 'Line4';             % brings up settings for line3
            obj.source.LineMode = 'input';                % should be 'output'
                        
            obj.source.TriggerSelector = 'FrameBurstStart';
            obj.source.TriggerSource = 'Line4';
            obj.source.AcquisitionBurstFrameCount = 255;
            obj.source.TriggerActivation = 'RisingEdge';
            
            obj.source.TriggerMode = 'On';
            
            obj.source.GainAuto = 'Once';
            
            obj.source.AcquisitionFrameRateEnable = 'True';
            obj.source.AcquisitionFrameRate = obj.params.framerate;
            obj.source.ExposureTime = 1E6/obj.source.AcquisitionFrameRate-300;            
            obj.params.framerate = obj.source.ResultingFrameRate;

            
            obj.living = 0;

            obj.dwnsamp = obj.exampleframe;
            obj.dwnsamp(:) = 0;
            Cmap = 4:4:size(obj.dwnsamp,1);
            Rmap = 4:4:size(obj.dwnsamp,2);
            obj.dwnsamp(Cmap,Rmap) = 1;
            shrunk = obj.dwnsamp(Cmap,Rmap);
            obj.dwnsamp = logical(obj.dwnsamp);
            
            shrunk(:) = obj.exampleframe(obj.dwnsamp);
            
            obj.snapshotfigure = findobj('type','figure','tag',['cam' num2str(obj.camPortID) '_snapshotfigure']);
            if isempty(obj.snapshotfigure)
                obj.snapshotfigure = figure;
                obj.snapshotfigure.Position = [400+320*(obj.camPortID-1) 2 320 266];
                obj.snapshotfigure.Tag = ['cam' num2str(obj.camPortID) '_snapshotfigure'];
                obj.snapshotfigure.MenuBar = 'none';
                obj.snapshotfigure.ToolBar = 'none';
                obj.snapshotfigure.NumberTitle = 'off';
            end
            obj.snapshotax = findobj(obj.snapshotfigure,'type','axes','tag',['cam' num2str(obj.camPortID) '_snapshotax']);
            if isempty(obj.snapshotax)
                obj.snapshotax = axes('parent',obj.snapshotfigure,'units','pixels','position',[0 0 320 256]);
            else 
                obj.snapshotax.Position = [obj.source.AutoFunctionROIOffsetX/4 obj.source.AutoFunctionROIOffsetY/4 obj.source.AutoFunctionROIWidth/4 obj.source.AutoFunctionROIHeight/4];
            end
            figure(obj.snapshotfigure)
            
            obj.displayimgobject = imshow(shrunk,'parent',obj.snapshotax);
            obj.displayimgobject.ButtonDownFcn = {@CameraBaslerSnapshotAxFcn,obj};

            obj.snapshotax.Position = [obj.source.AutoFunctionROIOffsetX/4 obj.source.AutoFunctionROIOffsetY/4 obj.source.AutoFunctionROIWidth/4 obj.source.AutoFunctionROIHeight/4];
            obj.snapshotax.Box = 'off'; obj.snapshotax.XTick = []; obj.snapshotax.YTick = []; obj.snapshotax.Tag = ['cam' num2str(obj.camPortID) '_snapshotax'];
            colormap(obj.snapshotax,'gray')

            fprintf(...
                'SetupDevice: Camera Basler will record\n\t%d frames at %.2f Hz with %g us exposure time and %g gain\n',...
                obj.videoInput.FramesPerTrigger,...
                obj.params.framerate,...
                obj.source.ExposureTime,...
                obj.source.Gain);


            
        end

        function defineParameters(obj)
            obj.params.framerate = 169.2906;
            obj.params.Nframes = 30;
            obj.params.SampsPerFrameBurstTrigger = ceil(255/obj.params.framerate * 10000);
            obj.params.ROIHeight = 1024;
            obj.params.ROIWidth = 1280;
            obj.params.ROIOffsetX = 0;
            obj.params.ROIOffsetY = 0;
            obj.params.ROICenterX = 'True';
            obj.params.ROICenterY = 'True';
            obj.params.ROISelector = 'ROI1';
        end
    end
end

