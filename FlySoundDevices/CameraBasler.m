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
            
            obj.videoInput = [];
            obj.source = [];
            obj.fileDestination = 'C:\Users\tony\Acquisition\fly_movement_videos';
            obj.fileName = 'default_name';
            obj.living = 0;
            obj.format = 'Mono8';
            obj.camPortID = 1;
            
            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [3];
            
            obj.digitalOutputLabels = {'trigger'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [2];

            obj.setupDevice();
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

            fprintf('\t\t\tTriggers fired: %d of %d. Logger logged %d frames.\n',obj.videoInput.TriggersExecuted,obj.videoInput.TriggerRepeat+1,obj.videoInput.DiskLoggerFrameCount)
            stop(obj.videoInput)
            obj.living = 0;
        end
        
        function quickpeak(obj)
            frame =  peekdata(obj.videoInput,1);
            % Set up a display window
            displayf = findobj('type','figure','tag','cam_snapshot');
            if isempty(displayf)
                displayf = figure;
                displayf.Position = [40 2 640 530];
                displayf.Tag = 'cam_snapshot';
            end
            acquire_sandbox_dispax = findobj(displayf,'type','axes','tag','dispax');
            if isempty(acquire_sandbox_dispax)
                acquire_sandbox_dispax = axes('parent',displayf,'units','pixels','position',[0 0 640 512],'tag','dispax');
                acquire_sandbox_dispax.Box = 'off'; acquire_sandbox_dispax.XTick = []; acquire_sandbox_dispax.YTick = []; acquire_sandbox_dispax.Tag = 'dispax';
                colormap(acquire_sandbox_dispax,'gray')
            end
            
            imshow(frame/(0.5*max(frame(:))),'initialmagnification',50,'parent',acquire_sandbox_dispax);
            %acquire_sandbox_dispax.CLim = [0 10];
            drawnow
            imshow(frame,'initialmagnification',50,'parent',acquire_sandbox_dispax);
            %acquire_sandbox_dispax.CLim = [0 255];          

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
            diskLogger = VideoWriter([fullfile(obj.fileDestination,obj.fileName)], 'Motion JPEG AVI');
            diskLogger.FrameRate = obj.params.framerate;
            diskLogger.Quality = 85;
            obj.videoInput.DiskLogger = diskLogger;
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
            
            
            % Setup source and pulses etc
            triggerconfig(obj.videoInput, 'hardware');
            obj.videoInput.TriggerRepeat = 0;
            obj.videoInput.FramesPerTrigger = obj.params.Nframes;
            obj.videoInput.LoggingMode = 'disk&memory';
            
            % Set up for
            obj.source.LineSelector = 'Line3';             % brings up settings for line3
            obj.source.LineMode = 'output';                % should be 'output'
            obj.source.LineInverter = 'True';                % should be 'output'
            obj.source.LineSource = 'ExposureActive';

            obj.source.LineSelector = 'Line4';             % brings up settings for line3
            obj.source.LineMode = 'input';                % should be 'output'
            
            obj.source.TriggerSelector = 'FrameStart';
            obj.source.TriggerMode = 'Off';
            
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
        end
    end
end
