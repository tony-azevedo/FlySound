function [voltage,current] = takeSweep(recMode, durSweep, samprate)
% function [Vcomm, Imeas] = rampVoltage(durRamp, rangeRamp, samprate)
%
% Function takes a sweep (duration specified by input argument durSweep)
% of the voltage and current in either I-clamp or V-clamp (as specified 
% by the input argument recMode).



%% reset aquisition engines
% configure session
aiSession = daq.createSession('ni');
aiSession.addAnalogInputChannel('Dev1',0, 'Voltage');
aiSession.Rate = samprate;
aiSession.DurationInSeconds = durSweep;

% configure AO
aoSession = daq.createSession('ni');
aoSession.addAnalogOutputChannel('Dev1',0:2, 'Voltage');
aoSession.Rate = samprate;

aiSession.addTriggerConnection('Dev1/PFI1','External','StartTrigger');
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');

x = aiSession.startForeground; %plot(x); drawnow
aiSession.stop

% pause()
% 
% close all

%% collect and analyse data(n)

% record current-clamp or voltage-clamp data
if strcmp(recMode,'VClamp')
    voltage = x(:,1); voltage = voltage';  % acquire voltage from 10Vm (channel ACH0)
    current = x(:,3); current = current';  % acquire current from scaled output (channel ACH3)
elseif strcmp(recMode,'IClamp')
    current = x(:,2); current = current';
    voltage = x(:,3); voltage = voltage';
end




