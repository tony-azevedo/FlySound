%% daq setup
d = daq.getDevices;

aoSession = daq.createSession('ni');
aiSession = daq.createSession('ni');

aoSession.addAnalogOutputChannel('Dev1',1,'Voltage');
aoSession.addAnalogOutputChannel('Dev1',2,'Voltage');
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
aoSession.Rate = 50000;

% http://www.mathworks.com/help/releases/R2012b/daq/ref/daq.session.adddigitalchannel.html
aiSession.addAnalogInputChannel('Dev1',0,'Voltage');
aiSession.addAnalogInputChannel('Dev1',5,'Voltage');
aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
aiSession.Rate = 50000;

%%
t_out = 1/aoSession.Rate*(0:aoSession.Rate-1)';
t_in = 1/aiSession.Rate*(0:aiSession.Rate-1)';

trigtime = .002;
triggers = zeros(size(t_out));
triggers(trigtime*aoSession.Rate) = 1;
triggers(end) = 0;

outcolumns(:,1) = 7.5*triggers;

piezostim = zeros(size(t_out));

pre = .2;
post = .2;
stim = 1-pre-post;
offset = 4;
a = 2;

stimpnts = round(aoSession.Rate*pre+1:...
    aoSession.Rate*(pre+stim));

%sin
f = 25;
ramp = .1;
w = window(@triang,2*ramp*aoSession.Rate);
w = [w(1:ramp*aoSession.Rate);...
    ones(length(stimpnts)-length(w),1);...
    w(ramp*aoSession.Rate+1:end)];

piezostim(stimpnts) = w;
outcolumns(:,2) = a * piezostim .* sin(2*pi*f*t_out) + offset;

% step
cycles = 5;
steps = reshape(stimpnts,length(stimpnts)/(2*cycles),2*cycles);
steps(:,1:2:2*cycles) = -1;
steps(:,2:2:2*cycles) = 1;
steps = reshape(steps,length(stimpnts),1);

piezostim(stimpnts) = steps;
outcolumns(:,2) = a * piezostim + offset;

figure(2)
set(gcf,'Name','Out');
subplot(2,1,1), title('AO 1')
plot(t_out,outcolumns(:,1));

subplot(2,1,2), title('AO 2')
plot(t_out,outcolumns(:,2));

% Collect input
aoSession.queueOutputData(outcolumns);
aoSession.startBackground; % Start the session that receives start trigger first
in = aiSession.startForeground; % both amp and signal monitor input

figure(3)
set(gcf,'Name','In');
subplot(2,1,1), title('AI 0')
plot(t_in,in(:,1));

subplot(2,1,2), title('AO 5')
plot(t_in,in(:,2));


%%
set(vid,'FramesPerTrigger',1)
set(vid,'TriggerRepeat',sum(triggers)-1)
set(vid,'FramesAcquiredFcnCount',5);
set(vid,'FramesAcquiredFcn',@sillydisplay);

figure(2)
set(gcf,'Name','Out');
subplot(2,1,1), title('AO 1')
plot(t_out,outcolumns(:,1));

subplot(2,1,2), title('AO 2')
plot(t_out,outcolumns(:,2));

%set(vid,'Timeout',10)
start(vid)

% Collect input
aoSession.queueOutputData(outcolumns);
aoSession.startBackground; % Start the session that receives start trigger first
in = aiSession.startForeground; % both amp and signal monitor input
disp('1');

wait(vid)
stop(vid)
fprintf('%d Frames\n',vid.FramesAcquired)

figure(3)
set(gcf,'Name','In');
subplot(2,1,1), title('AI 0')
plot(t_in,in(:,1));

subplot(2,1,2), title('AO 5')
plot(t_in,in(:,2));

%% Look at timing of frames

% wait(vid,2)
% 

[imframes, timeStamp] = getdata(vid,frames);
evntlog = get(vid,'EventLog');

captures = zeros(size(t_in));
for i = 1:length(timeStamp)
    ind = find(abs(t_in-timeStamp(i))==min(abs(t_in-timeStamp(i))));
    captures(ind) = 1;
end

figure(4)
clf
set(gcf,'Name','TriggerAlignment');
subplot(1,1,1), title('AI 0')
plot(t_out,triggers); hold on
plot(t_in,captures,'g');

trigger_times = t_out(logical(triggers));
capture_times = t_in(logical(captures));
jitters = (trigger_times - capture_times);

% vid.DiskLoggerFrameCount

%% show the movie

figure(6)
set(gcf,'Name','Movie');
for k = 1:size(imframes,4)
    imshow(imframes(:,:,k))
    pause(1/framerate);
    drawnow
end

%% Frame numbers
figure(1);
dockedax = subplot(1,1,1);
framerate = 30;
frames = 5;
deltaT = round(1/framerate * aoSession.Rate);
triggers = zeros(size((0:1000-1)'));
triggers(1:deltaT:frames*deltaT) = 1;
triggers(end) = 0;

outcolumns = 7.5*triggers;
plot(dockedax,outcolumns);

%%
aoSession.queueOutputData(outcolumns);
aoSession.startBackground; % Start the session that receives start trigger first
in = aiSession.startForeground; % both amp and signal monitor input
plot(dockedax,in)

%%
set(vid,'FramesPerTrigger',15)
set(vid,'TriggerRepeat',0)
set(vid,'FramesAcquiredFcnCount',5);
set(vid,'FramesAcquiredFcn',{@disp(vid.FramesAvailable)});

%set(vid,'Timeout',10)
start(vid)

% Collect input
aoSession.queueOutputData(outcolumns);
aoSession.startBackground; % Start the session that receives start trigger first
in = aiSession.startForeground; % both amp and signal monitor input
plot(dockedax,in)

stop(vid)
[imframes, timeStamp] = getdata(vid,5);
vid.FramesAcquired

evntlog = get(vid,'EventLog');

vid.DiskLoggerFrameCount



%% Calculate difference image and display it.
figure
% Start acquiring frames.
frameslogged = get(vid, 'FramesAcquired')

data = getdata(vid,1);
imshow(data,[min(min(data)),max(max(data))])

% while(vid.FramesAvailable >= 4)
%     data = getdata(vid,4); 
%     mean_im = imadd(data(:,:,:,1),data(:,:,:,2));
%     mean_im = imadd(mean_im,data(:,:,:,3));
%     mean_im = imadd(mean_im,data(:,:,:,4));
%     mean_im = mean_im/4;
%     
%     imshow(mean_im);
%     drawnow     % update figure window
% end

stop(vid)

% Tutorials
%     demoimaq_AccessDevices      - Accessing an image acquisition device.
%     demoimaq_Acquisition        - Acquiring image data to memory.
%     demoimaq_Callbacks          - Using image acquisition callbacks.
%     demoimaq_DiskLog            - Logging image data to an AVI file.
%     demoimaq_Events             - Working with image acquisition events.
%     demoimaq_GetSnapshot        - Acquiring a single image in a loop.
%     demoimaq_IdentifyDevices    - Determining available image acquisition 
%                                   hardware.
%     demoimaq_Objects            - Managing image acquisition objects.
%     demoimaq_Properties         - Working with image acquisition properties.
%     demoimaq_Triggers           - Working with image acquisition triggers.
%  
%   Application Demos.
%     demoimaq_AcquisitionRate    - Calculating the acquisition rate.
%     demoimaq_AlphaBlending      - Alpha blending image data as it is acquired.
%     demoimaq_AlphaBlendingIPT   - Alpha blending image data as it is acquired,
%                                   using the Image Processing Toolbox.
%     demoimaq_Averaging          - Averaging image data as it is acquired and 
%                                   saving results to disk.
%     demoimaq_IntervalLogging    - Acquiring image data at a constant interval.
%     demoimaq_Pendulum           - Calculating the gravitational constant using a 
%                                   pendulum.
%     demoimaq_NI_RTSI_IMAQ_IMAQ  - Synchronizing two National Instruments
%                                   frame grabbers via RTSI.
%     demoimaq_NI_RTSI_IMAQ_DAQ   - Synchronizing a National Instruments
%                                   frame grabber and data acquisition board
%                                   via RTSI.