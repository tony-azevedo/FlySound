function [stim_vector] = generateTone(freq, samprate, dur, dr) 


%[stim_vector] = generateTone(freq, samprate, dur, dr)
%
%Function generates a single tone of user-determined frequency, output
%sample rate, and duration.  
%
%Inputs:
%   freq = stimulus frequency (in Hz)
%   samprate = output sample rate of stimulus (in Hz)
%   dur = duration of tone (in seconds)
%   dr = duration of ramp (set to 0 for default, which is dur/10)
%
%Outputs:
%   stim_vector = stimulus vector

sf = samprate;   % sample frequency (Hz)
stim_vector = zeros(1, (dur * sf));

%Make cos theta ramped pure tones at 160Hz and 320Hz

% 100Hz 1s tone
cf = freq;                  % carrier frequency (Hz)              
d = dur;                    % duration (s)
n = sf * d;                 % number of samples
s100 = (0:n-1) / sf;             % sound data preparation
s100 = sin(2 * pi * cf * s100);   % sinusoidal modulation

% prepare ramp
if dr==0
    dr = d / 10;
end
nr = floor(sf * dr);
r = sin(linspace(0, pi/2, nr));
r = [r, ones(1, n - nr * 2), fliplr(r)];

% make ramped sound
s100 = s100 .* r;

%add tones to stimulus vector
stim_vector = s100;
%stim_vector(100: (99 + length(s100))) = s100 * .6;
%wavwrite(stimulus_vector,sf,'200HzTone.wav');

%save output values
stim_freq = freq;
stim_samprate = samprate;
stim_dur = dur;