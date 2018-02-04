function [gain] = readGain()
% [voltage,current] = readGain(recMode, durSweep, samprate)
%

global global_gainSession
if isempty(global_gainSession)
   global_gainSession = daq.createSession('ni');
   global_gainSession.addAnalogInputChannel('Dev1',1, 'Voltage');
   global_gainSession.Rate = 10000;  % 10 kHz
   global_gainSession.DurationInSeconds = .02; % 2ms
end

gain_voltage = global_gainSession.startForeground; %plot(x); drawnow
gain_voltage = mean(gain_voltage);

if gain_voltage < 2.2
    gain = 0.5;
elseif gain_voltage < 2.7
    gain = 1;
elseif gain_voltage < 3.2
    gain = 2;
elseif gain_voltage < 3.7
    gain = 5;
elseif gain_voltage < 4.2
    gain = 10;
elseif gain_voltage < 4.7
    gain = 20;
elseif gain_voltage < 5.2
    gain = 50;
elseif gain_voltage < 5.7
    gain = 100;
elseif gain_voltage < 6.2
    gain = 200;
elseif gain_voltage < 6.7
    gain = 500;
end


