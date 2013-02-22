function [mode] = readMode()
% [voltage,current] = readGain(recMode, durSweep, samprate)
%

global global_modeSession
if isempty(global_modeSession)
   global_modeSession = daq.createSession('ni');
   global_modeSession.addAnalogInputChannel('Dev1',2, 'Voltage');
   global_modeSession.Channels(1).TerminalConfig = 'SingleEndedNonReferenced';
   global_modeSession.Rate = 10000;  % 10 kHz
   global_modeSession.DurationInSeconds = .02; % 2ms
end

mode_voltage = global_modeSession.startForeground; %plot(x); drawnow
mode_voltage = mean(mode_voltage);

if mode_voltage < 1.75
    mode = 'IClamp_fast';
elseif mode_voltage < 2.75
    mode = 'IClamp';
elseif mode_voltage < 3.75
    mode = 'I=0';
elseif mode_voltage < 4.75
    mode = 'Track';
elseif mode_voltage < 6.75
    mode = 'VClamp';
end


