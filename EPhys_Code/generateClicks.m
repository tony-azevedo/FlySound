function [stim_vector] = generateClick(numclicks, samprate, dur) 


%[stim_vector] = generateTone(numclicks, samprate, dur)
%
%Function generates a single click or user-determined train of clicks, 
%sample rate, and duration.  
%
%Inputs:
%   numclicks = number of clicks over 
%   samprate = output sample rate of stimulus (in Hz)
%   dur = duration of tone (in seconds)
%
%Outputs:
%   stim_vector = stimulus vector

sf = samprate;   % sample frequency (Hz)
stim_vector = zeros(1, (dur * sf));

% generate 8 ms click
cf = 62.5;                        % carrier frequency (Hz); 62.5 gives an 8 ms click             
dur_click = .008;                 % duration of stimulus (not individual clicks) (s)
n = sf * dur_click;               % number of samples
s100 = (1:n) / sf;                % sound data preparation
s100(n/2) = 1;                    % click stimulus (0V to 1V)

% create appropriate number of clicks over stimulus period
if numclicks > 1
    interclickinterval = floor(((dur*samprate)-(dur_click*samprate))/numclicks);
    for click_onset = 1:interclickinterval:(dur*samprate-dur_click*samprate)
        stim_vector(click_onset:(click_onset+dur_click*samprate-1)) = s100;
    end
elseif numclicks == 1
    stim_vector(1:dur_click*samprate) = s100;
end

