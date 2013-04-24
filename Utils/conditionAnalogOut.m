function out = conditionAnalogOut(out,channel)
% Input is a waveform to be loaded onto the DAQ, correct for offsets

switch channel
    case 0
    case 1
    case 2
    case 3
        out = out-0.00306;
    otherwise
        out = out;
end

% voltage offset on input 1 = 0.008mV

