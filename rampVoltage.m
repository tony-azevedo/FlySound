function [Vcomm, Vmeas, Imeas, trigdiff] = rampVoltage(durRamp, rangeRamp, samprate)
% function [Vcomm, Imeas] = rampVoltage(durRamp, rangeRamp, samprate)
%
% Function takes the duration of a voltage ramp, the range of the voltage
% ramp ([startVoltage endVoltage]), and the sample rate (should be around
% 10000 Hz) and executes a smooth voltage ramp while acquiring the
% resulting currents.  The final voltage ramp will last a few seconds, and
% it will be preceded by .5 seconds of the startVoltage as well as followed
% by .5 seconds of the endVoltage.

%% create voltage ramp
% create smooth voltage ramp
sampsRamp = durRamp*samprate;
Vcomm = [rangeRamp(1):(rangeRamp(2)-rangeRamp(1))/sampsRamp:rangeRamp(2)-1/sampsRamp];

% flank the voltage ramp by .5 seconds of the startVoltage (rangeRamp(1))
% and .5 seconds of the endVoltage (rangeRamp(2))
Vcomm = [rangeRamp(1)*ones(1,.5*samprate) Vcomm rangeRamp(2)*ones(1,.5*samprate)];

% establish the timestamps for the voltage ramp (.5 s + durRamp + .5 s)
t = [0:(.5+durRamp+.5)*samprate-1]/samprate;

%% reset aquisition engines
daqreset;

%% configure analog input
AI = analoginput ('nidaq', 'Dev1');
addchannel (AI, 0:2);
set(AI, 'SampleRate', samprate);
set(AI, 'SamplesPerTrigger', inf);
set(AI, 'InputType', 'Differential');
set(AI, 'TriggerType', 'Manual');
set(AI, 'ManualTriggerHwOn','Trigger');

%% configure analog output
AO = analogoutput ('nidaq', 'Dev1');
addchannel (AO, 1);
% addchannel (AO, 0);
set(AO, 'SampleRate', samprate);
set(AO, 'TriggerType', 'Manual');

%% create and load stimulus (zero-pad by 100 samples)
ch1out = [Vcomm';zeros(100,1)];
putdata(AO, ch1out);
% putdata(AO,[ch0out]);

%% %% output voltage ramp and acquire currents
% start playback
start([AI AO]);
trigger([AI AO]);

% wait for playback/recording to finish
nsampin = AI.SamplesAcquired;
nsampout = AO.SamplesOutput;
while (nsampin<length(t))
    nsampin = AI.SamplesAcquired;
    nsampout = AO.SamplesOutput;
end

% stop playback
stop([AI AO]);

%% collect and analyse data(n)
% record difference in AI/AO start times
trigdiff = AO.InitialTriggerTime-AI.InitialTriggerTime;

% read data from engine
x = getdata(AI,length(t));
Vmeas = x(:,1); Vmeas = Vmeas';
Imeas = x(:,3); Imeas = Imeas';



