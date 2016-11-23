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
