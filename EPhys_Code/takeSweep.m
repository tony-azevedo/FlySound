function [voltage,current] = takeSweep(recMode, durSweep, samprate)
% function [Vcomm, Imeas] = rampVoltage(durRamp, rangeRamp, samprate)
%
% Function takes a sweep (duration specified by input argument durSweep)
% of the voltage and current in either I-clamp or V-clamp (as specified 
% by the input argument recMode).

%% establish sweep timestamps
t = [0:durSweep*samprate-1]/samprate;

%% reset aquisition engines
daqreset;

%% configure analog input
AI = analoginput ('nidaq', 'Dev1');
addchannel (AI, 0:2);   % acquire from ACH0, ACH1, and ACH2, which contain 
                        % the 10Vm out, I out, and scaled output, respectively
set(AI, 'SampleRate', samprate);
set(AI, 'SamplesPerTrigger', inf);
set(AI, 'InputType', 'Differential');
set(AI, 'TriggerType', 'Manual');
set(AI, 'ManualTriggerHwOn','Trigger');

%% %% output voltage ramp and acquire currents
% start playback
start(AI);
trigger(AI);

% wait for playback/recording to finish
nsampin = AI.SamplesAcquired;
while (nsampin<length(t))
    nsampin = AI.SamplesAcquired;
end

% stop playback
stop(AI);

%% collect and analyse data(n)

% read data from engine
x = getdata(AI,length(t));

% record current-clamp or voltage-clamp data
if strcmp(recMode,'VClamp')
    voltage = x(:,1); voltage = voltage';  % acquire voltage from 10Vm (channel ACH0)
    current = x(:,3); current = current';  % acquire current from scaled output (channel ACH3)
elseif strcmp(recMode,'IClamp')
    current = x(:,2); current = current';
    voltage = x(:,3); voltage = voltage';
end




