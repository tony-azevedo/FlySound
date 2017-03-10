classdef PGRCamera < Device
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
        videoInput
        source
        fileDestination
        fileName
        living
        cameraLocation
        format
        camPortID
        triggermode
        triggerpolarity
        dispFunc
    end
    
    properties
    end

    events
        %
    end
    
    methods
        function obj = PGRCamera(varargin)
            % This and the transformInputs function are hard coded
            
            obj.gaincorrection = [];
            obj.videoInput = [];
            obj.source = [];
            obj.fileDestination = 'C:\Users\tony\Acquisition\fly_movement_videos';
            obj.fileName = 'default_name';
            obj.living = 0;
            obj.cameraLocation = 'PGRCamDefaultLoc';
            obj.format = '';
            obj.camPortID = 0;
            obj.triggermode = '';
            obj.triggerpolarity = 'risingEdge';
        end
        
        function setup(obj,varargin)
            
            fprintf('Turn off FlyCap software');
            h = warndlg('Turn off FlyCap software');
            uiwait(h)
            % imaqreset
            fprintf('\n')

            obj.videoInput = videoinput('pointgrey', obj.camPortID, obj.format,'Tag',obj.cameraLocation);
            obj.source = getselectedsource(obj.videoInput);
            
            % Setup source and pulses etc
            triggerconfig(obj.videoInput, 'hardware', obj.triggerpolarity, obj.triggermode);
            obj.videoInput.TriggerRepeat = 0;
            obj.videoInput.FramesPerTrigger = 1;
            obj.videoInput.LoggingMode = 'disk';
            obj.living = 0;

        end
        
        function varargout = transformInputs(obj,inputstruct,varargin)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                if strcmp(inlabels{il},'exposure')
                    units = {'bit'};
                   
                    inputstruct.exposure = inputstruct.exposure > 0.5;
                    inputstruct.exposure = ...
                        [inputstruct.exposure(2:end) - inputstruct.exposure(1:end-1); 0];
                    inputstruct.exposure = inputstruct.exposure > 0;
                end
            end
            varargout = {inputstruct,units};
        end
        
        function out = transformOutputs(obj,out,varargin)
            rig = varargin{1};
            if ~isfield(out,'trigger')
                fns = fieldnames(out);
                out.trigger = out.(fns{1});
                out.trigger(:) = 0;
            else
            end
            dur = length(out.trigger)/rig.aoSession.Rate;
            frametime = 1/obj.params.framerate;
            Nframes = floor(dur/frametime);
            idxs = round(((1:Nframes)-1)*(frametime*rig.aoSession.Rate) + 1);
            out.trigger(idxs) = 1;
            out.trigger(idxs+1) = 1;
            out.trigger(idxs(2)) = 0;
            out.trigger(idxs(2)+1) = 0;
            out.trigger(idxs(3)) = 0;
            out.trigger(idxs(3)+1) = 0;
            out.trigger(end) = 0;
            
            %out.trigger = ~out.trigger;
            obj.params.Nframes = sum(out.trigger)/2;
            obj.videoInput.TriggerRepeat = obj.params.Nframes-1;
            obj.videoInput.TriggerFcn = {obj.dispFunc};
        end
    
        function live(obj)
            preview(obj.videoInput)
            obj.living = 1;
        end
        function dead(obj)
            stoppreview(obj.videoInput)
            obj.living = 0;

        end
        function start(obj)
            start(obj.videoInput);
            fprintf('Video started: %d of %d Triggers/Frames\n\tFilename:\t%s\n\tFilepath:\t%s\n',...
                obj.videoInput.FramesAcquired,obj.videoInput.TriggerRepeat+1,get(obj.videoInput.DiskLogger,'Filename'),get(obj.videoInput.DiskLogger,'Path'))
        end
        function stop(obj)
            fprintf('Triggers fired: %d of %d. Logger logged %d frames.\n',obj.videoInput.TriggersExecuted,obj.videoInput.TriggerRepeat+1,obj.videoInput.DiskLoggerFrameCount)
            stop(obj.videoInput)
        end
        
        function varargout = status(obj)
            s = sprintf('Triggers fired: %d of %d. Logger logged %d frames.\n',obj.videoInput.TriggersExecuted,obj.videoInput.TriggerRepeat+1,obj.videoInput.DiskLoggerFrameCount);
            missedFrames = obj.videoInput.TriggerRepeat+1 - obj.videoInput.TriggersExecuted;
            varargout = {obj.videoInput.Running,s,missedFrames};
        end
        
        function setLogging(obj,filename)
            [fn,D] = strtok(fliplr(filename),filesep);
            obj.fileName = fliplr(fn);
            obj.fileDestination = fliplr(D(2:end));
            diskLogger = VideoWriter([fullfile(obj.fileDestination,obj.fileName) '.avi'], 'Grayscale AVI');
            obj.videoInput.DiskLogger = diskLogger;
        end
        
    end
    
    methods (Access = protected)
        function setupDevice(obj)        
        end

        function defineParameters(obj)
            obj.params.setup = 'x Frames, write in the rest of the information';
            obj.params.framerate = 40;
            obj.params.Nframes = 30;
        end
    end
end
