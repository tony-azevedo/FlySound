function AM_signal = amp_mod(m,fm,fc,dutycycle,samprate,stimdur,sine_env,directions)

% AM_signal = amp_mod(m,fm,fc,dutycycle,samprate,stimdur,sine_env)
%
% Generates an amplitude-modulated sine wave based on the function
% AM_signal = [1 + m*sin(2*pi*fm*t)]*sin(2*fc*t)
%
% Input:
%     (1) m - modulation depth (0<=m<=1)
%     (2) fm - modulation frequency (in Hz)
%     (3) fc - carrier frequency (in Hz)
%     (4) dutycycle - duty cycle (fraction of period spent in active state)
%     (5) samprate - sampling rate (typically between 32000 and 45000 Hz
%     for a sound stimulus)
%     (6) stimdur - duration of signal (in seconds)
%     (7) sine_env - is the AM envelope sinusoidal? (1=yes,0=no)
%     (8) directions - 'pulse' or 'pause' (pertains to stimuli in which the
%     duty cycle is varied)
%
% Output:
%     (1) AM_signal - amplitude modulated sine wave

%% check inputs 
if m>1 || m<0
    disp('Enter a value for m that is between 0 and 1!');
end

% if dutycycle>1 || dutycycle<0
%     disp('Enter a value for dutycycle that is between 0 and 1!');
% end
% 
% if(~isreal(fc) || ~isscalar(fc) || fc<=0 || ~isnumeric(fc) )
%     disp('fc must be a real, positive scalar!');
% end
% 
% if(~isreal(fm) || ~isscalar(fm) || fc<=0 || ~isnumeric(fm) )
%     disp('fm must be a real, positive scalar!');
% end
% 
% if(~isreal(samprate) || ~isscalar(samprate) || samprate<=0 || ~isnumeric(samprate))
%     disp('samprate must be a real, positive scalar!');
% end
% 
% % check that Fs must be greater than 2*Fc
% if(samprate<2*fc)
%     disp('Error: Fs must be at least 2*Fc! (NYQUIST!!)');
% end

%% generate signal
AM_signal = zeros(1,(stimdur*samprate));
if sine_env==1
    t_temp = stimdur*samprate + samprate/fm; % extra samprate/fm is added
                                             % to the initial signal
                                             % that will later be cut out
                                             % (in order to get a
                                             % ramped, uniform signal)
    t_temp = 0:(1/samprate):t_temp/samprate-(1/samprate);

    % generate AM waveform (generate envelope and then multiply by carrier)
    envelope = [1+m*sin(2*pi*fm*t_temp)];
    if strcmp(directions,'envelope')
        temp_AMsignal = envelope;
    else
        temp_AMsignal =  envelope.*sin(2*pi*fc*t_temp);
    end
    
    % find first and last minima so that the signal can be clipped
    % at these two points
    [env_min ind_min] = find(envelope==min(envelope));
    ind_min = ind_min-1;
    clip(1) = (samprate/fm)-(length(envelope)-ind_min(end));
    clip(2) = ind_min(end); 
    disp(['fm = ',num2str(fm),', clips = ',num2str(clip)]);
    
    % if clip(1) is negative, shift the clip frame by one envelope cycle
    if clip(1)<0
        clip = clip+samprate/fm;
    end

    % if the clip length is longer or more than 10% shorter than the 
    % desired stimulus length, display an error
    if diff(clip)>(stimdur*samprate)
        disp('Stimulus is too long!');
    elseif diff(clip)<(.90*stimdur*samprate)
        disp('Stimulus is much too short!');
    elseif clip(2)>length(envelope) % if the second clip exceeds the envelope length, display an error
        disp('Clip exceeds envelope length!');
    end
    
    % clip AM_signal and normalize so that the peak amplitude is 1
    AM_signal = temp_AMsignal(clip(1):clip(2)-1);
    AM_signal = AM_signal.*(1/max(AM_signal));  % normalizes so that amplitude is -1
    
elseif sine_env==0   % NOTE: WHEN VARYING THE DUTY CYCLE, THE ENVELOPE IS NO LONGER SINUSOIDAL
    %     AM_signal(floor((dutycycle*(samprate/fm))/2):floor(samprate/fm):floor(stimdur*samprate)) = 1;
    %     AM_sigfilt = hanningsmooth(AM_signal,dutycycle*(samprate/fm));
    %     norm_factor = 1/max(AM_sigfilt);
    %     AM_sigfiltnorm = AM_sigfilt*norm_factor;
    %     if length(AM_sigfiltnorm)~=stimdur*samprate
    %         signal_diff = length(AM_sigfiltnorm)-(stimdur*samprate);
    %         if signal_diff==1
    %             AM_sigfiltnorm(end) = [];
    %         elseif signal_diff>1
    %             disp('signal length is more than 2 indices too long');
    %         end
    %     end
    %     s = AM_sigfiltnorm.*sin(2*pi*fc*t);
    %     AM_signal = s;
    t=[0:1/samprate:stimdur-(1/samprate)];
    min_pulse = 1/(fm/.25);  % the minimum pulse duration used in the dutycycle stimulus 
                             % set is determined by the 25% duty cycle
    if strcmp(directions,'pulse')
        pulse_dur = 1/(fm/dutycycle);
        pause_dur = (pulse_dur/dutycycle)-pulse_dur;
        pulsepluspause = pulse_dur+pause_dur;
        numones = (pulse_dur-min_pulse)*samprate; % determines number of samples in "plateau portion" of pulse
        for z = (min_pulse/2*samprate):(ceil(pulsepluspause*samprate)):ceil(length(AM_signal)-(min_pulse/2)*samprate)
%             if z==min_pulse/2*samprate
                AM_signal(floor(z):floor(z+floor(numones))) = 1;
%             else
%                 AM_signal(floor(z-numones/2):floor((z+numones/2)-1)) = 1;
%             end
        end
    elseif strcmp(directions,'pause')
        % all stimuli using pause duration to vary the dutycycle will
        % keep the same pulse duration (which is the pulse dur set with the
        % minimum dutycycle, 25%)
        pause_dur = (min_pulse/dutycycle)-min_pulse;
        pulsepluspause = min_pulse+pause_dur;
        AM_signal((min_pulse/2)*samprate:(ceil(pulsepluspause*samprate)):ceil(length(AM_signal)-(min_pulse/2)*samprate)) = 1;   
    end
    
    filtwindow = min_pulse*samprate; % for all duty cycle stimuli, the filter window
                                     % will be the size of the shortest pulse   
    AM_sigfilt = hanningsmooth(AM_signal,filtwindow); 
    norm_factor = 1/max(AM_sigfilt);
    AM_sigfiltnorm = AM_sigfilt*norm_factor;
    if length(AM_sigfiltnorm)~=stimdur*samprate
        signal_diff = length(AM_sigfiltnorm)-(stimdur*samprate);
        if signal_diff==1
            AM_sigfiltnorm(end) = [];
        elseif signal_diff>1
            disp('signal length is more than 2 indices too long');
        end
    end
    AM_signal = AM_sigfiltnorm.*sin(2*pi*fc*t);
    figure; plot(AM_signal);
end
    