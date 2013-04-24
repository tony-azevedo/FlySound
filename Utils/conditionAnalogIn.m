function in = conditionAnalogIn(in,channel)
% Input is a waveform to be loaded onto the DAQ, correct for offsets

switch channel
    case 0
        in = in+0.0082735;
    case 1
    case 2
    case 3
        in = in+0.0082735;
    otherwise
        in = in+0.0082735;
end

% voltage offset on input 1 = 0.008mV

