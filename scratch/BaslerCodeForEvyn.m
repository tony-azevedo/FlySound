%% setup camera
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

%% Some other parameters
% assign your appropriate number of frames somehow
% obj.params.Nframes = floor(obj.params.framerate*protocol.params.durSweep)-1;
obj.videoInput.FramesPerTrigger = obj.params.Nframes;
obj.params.SampsPerFrameBurstTrigger = ceil(double(obj.source.AcquisitionBurstFrameCount)/obj.params.framerate * protocol.params.samprateout);

%% using the burst frame feature, so the triggers occur after a previous burst has occured

triggers = (0:obj.params.SampsPerFrameBurstTrigger:length(out.trigger(:)))+1;
triggers = [triggers;triggers+3;triggers+6];
triggers = triggers(:);
out.trigger(triggers) = 1;

%% Now you have to load Triggers onto the daq

%% Start the camera to wait for triggers

start(obj.videoInput);
obj.living = 1;
fprintf('\n\t\t\tVideo started: %d of %d Triggers/Frames\n\t\t\t\tFilename:\t%s\n\t\t\t\tFilepath:\t%s\n',...
    obj.videoInput.FramesAcquired,obj.videoInput.TriggerRepeat+1,get(obj.videoInput.DiskLogger,'Filename'),get(obj.videoInput.DiskLogger,'Path'))

%% Start the daq

%% Stop the camera following a recording
fprintf('\t\t\tTriggers fired: %d of %d. Logger logged %d frames.\n',obj.videoInput.TriggersExecuted,obj.videoInput.TriggerRepeat+1,obj.videoInput.DiskLoggerFrameCount)
stop(obj.videoInput)
obj.living = 0;
