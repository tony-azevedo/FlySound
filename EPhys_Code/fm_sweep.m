function FM_signal = fm_sweep(fc,F1,samprate,stimdur)

% FM_signal = fm_sweep(fc,F1,samprate,stimdur)
%
% Generates a linear frequency-modulated signal from frequency fc to
% frequency F1 over a defined time period (stimdur)
%
% Input:
%     (1) fc - start frequency (in Hz)
%     (2) F1 - end frequency (in Hz)
%     (2) samprate - sampling rate (typically between 32000 and 45000 Hz
%     for a sound stimulus)
%     (3) stimdur - duration of signal (in seconds)
%     
%
% Output:
%     (1) FM_signal - frequency modulated signal

%% check inputs 
if(~isreal(fc) || ~isscalar(fc) || fc<=0 || ~isnumeric(fc) )
    disp('fc must be a real, positive scalar!');
end

if(~isreal(F1) || ~isscalar(F1) || F1<=0 || ~isnumeric(F1) )
    disp('fm must be a real, positive scalar!');
end

if(~isreal(samprate) || ~isscalar(samprate) || samprate<=0 || ~isnumeric(samprate))
    disp('samprate must be a real, positive scalar!');
end

% check that Fs must be greater than 2*Fc
if(samprate<2*fc)
    disp('Error: Fs must be at least 2*Fc!');
end

%% generate FM signal
t=[0:1/samprate:stimdur-(1/samprate)];
FM_signal = zeros(1,(stimdur*samprate));
s=chirp(t,fc,stimdur,F1);

dur_ramp = stimdur/10;
numsamps_ramp = floor(samprate*dur_ramp);
ramp = sin(linspace(0, pi/2, numsamps_ramp));
ramp = [ramp, ones(1, length(t)-numsamps_ramp * 2), fliplr(ramp)];

% make ramped sound
s = s .* ramp;
FM_signal(100: (99 + length(s))) = s * .6;
