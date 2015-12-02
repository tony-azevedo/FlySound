function song = songMaker(song_params,plot_and_play)
% Generates .wav files containing D. melanogaster pulse and sine song
%
% Inputs :: 
%      1) song parameters, discussed below.
%      2) plot_and_play, a boolean 
%
% Outputs ::
%      1) A struct containing lots information about the song.  In particular:
%          song.song is the the full song, compatible with .wav format.
%          song.group is the individual group.
%          song.pulse is a group of n pulses.
%
%       
%
% SONG PARAMETERS:: as a struct containing the following (optional) fields.
% If either the struct or any given field are omitted, the function
% defaults to the parameters shown. 
%
%        **  These defaults are not necessarily  **
%        **  biological, so be sure to set them  **
%        **     to something appropriate .       **
%
% .WAV PARAMETERS
% song_params.fs = 44100;                 % Sampling frequency
%
% SINE SONG PARAMETERS
% * Sine song always comes before pulse song.* 
% song_params.sineSongDuration            % in seconds.
% song_params.sineSongFundamental         % In hz
% song_params.sineSongAmplitude           % Amplitude of sine song, in +/- volts.
% song_params.sineSongRamp = 0.1;         % Ramp on/off time, in s. (triangular ramp)
% song_params.sinePulsePause              % Pause after sine song.
%
% PULSE TYPE
% song_params.pulseSongFundamental        % Fundamental, in hz. A surprisingly conroversial topic.
% song_params.pulseType                   % Windowing function - supports 'gaussian','sine'
% song_params.pulseBandwidth              % [0..1] For gaussian windowing.  Low = tightly windowed
% song_params.pulseLength                 % Tight cutoff to pulse length. If 0 and gaussian pulse, windowed by -40db cutoff.
% song_params.ipi                         % IPI, in s.
%
% PULSE GROUPS
% song_params.pulsePerGroup               % Pulses per group
% song_params.interGroupInterval          % Inter-group interval, in s.
% song_params.numGroups                   % Total groups of pulse song.
%
% TRAILING SILENCE
% song_params.leadingSilence              % Leading silence, in s.
% song_params.trailingSilence             % Trailing silence, in s.
%
%
%
% (C) Alex Vaughan, 2015

%% Process inputs.
    
if nargin >= 1
    song_params = song_params;
    if ~isstruct(song_params),
        error('Input is not a struct.')
    end
end

if nargin < 2,
    plot_and_play = 1;
end

%% Process default values and over-ride, if necessary.
% Default values for the necessary parameters.  Change these by putting
% them into a struct in the input.
song.fs = 44100;

song.sineSongDuration  = 1;      % Duration in s
song.sineSongFundamental = 160;  % Fundamental, in hz
song.sineSongAmplitude = 1;      % Amplitude scaling [0..1] - fairly arbitrary as pulse song amplitudes are not controlled.
song.sineSongRamp      = 0.1;    % Ramp on/off time, in s.
song.sinePulsePause    = 0.1;    % Pause between sine/pulse song, in s.

song.pulseSongFundamental = 260; % Pulse song fundamental, in hz
song.pulseType = 'gaussian';     % Supports 'gaussian','sine'
song.pulseBandwidth = 0.3;       % [0..1] Increases severity of on/off ramp.
song.pulseLength = 0;            % in seconds. If 0 and pulseType=='gaussian', uses a -40db width (see code).
song.ipi = 0.035;                % in seconds.

song.pulsePerGroup = 20;         % Pulses per group
song.interGroupInterval = 0.3;   % Inter-group interval, in seconds
song.numGroups = 10;             % Number of groups

song.leadingSilence  = 0.1;      % Leading silence, in seconds.
song.trailingSilence = 0.1;      % Trailing silence, in seconds.

% Overide these values with those from the input.
if nargin > 0,
    names = fieldnames(song_params);
    for n = 1:length(names);
        song.(names{n}) = song_params.(names{n});
    end
end


%% Pre-calculation of parameters

song.singleDuration = 5 * 1/song.pulseSongFundamental;   %The number of cycles of the original pulse we have, perhaps.
song.ipiSamples = song.ipi*song.fs;  %in samples
song.pulsePerGroupS = song.pulsePerGroup * song.ipi;    % Integrally related to song.pulsePerGroup, except a better way to count.
song.groupTrailingSilence = rem(song.pulsePerGroupS, song.ipi);  %Trailing silence, in ms.
song.groupTrailingSilenceSamples = song.groupTrailingSilence*song.fs;


%% Make sine song


song.sineSongFundamental = 160;

if song.sineSongDuration > 0
    % Generate sine song.
    sine_cycles = song.sineSongDuration*song.sineSongFundamental;
    sine_song = sin( linspace(0,2*pi*sine_cycles,song.sineSongDuration*song.fs));
    % Ramp on/off
    ramp_length = round(song.fs*song.sineSongRamp);
    sine_song(1:ramp_length) = sine_song(1:ramp_length) .* linspace(0,1,ramp_length);
    sine_song(end-ramp_length+1:end) = sine_song(end-ramp_length+1:end) .* linspace(1,0,ramp_length);
    % Scale amplitude
    sine_song = 2 * sine_song / range(sine_song);
    sine_song = sine_song * song.sineSongAmplitude;
else
    sine_song = [];
end
song.sine_song = sine_song;


%% Make a single pulse

if strcmp(song.pulseType,'gaussian')
    
    if song.pulseLength > 0
        % Note here that the bandwidth should be set by eye.
        t = linspace( -song.pulseLength/2,song.pulseLength/2,song.fs*song.pulseLength)
        song.pulse = gauspuls( t ,song.pulseSongFundamental, song.pulseBandwidth)
        
    else
        %%% Another option - returns the limits for a -30db dropoff
        %%% However, this approach makes a pulse of arbitary length.
        song.pulseCutoff = gauspuls('cutoff', song.pulseSongFundamental , song.pulseBandwidth, [],-30);
        t = -song.pulseCutoff: 1/song.fs : song.pulseCutoff;
        %Generate the actual pulse.
        song.pulse = gauspuls(t , song.pulseSongFundamental , 0.5);
        song.pulseLength = length(song.pulse);  %in samples
    end
    
elseif strcmp(song.pulseType,'sine')
    
%%
    if song.pulseLength == 0
        % Default to 3 cycles.
       song.pulseLength =  (1/song.pulseSongFundamental * 3);
    end
    % Sin
    cycles = song.pulseLength*song.pulseSongFundamental;
    %The underlying sine wave.
    s = sin( linspace(0,2*pi*cycles,song.pulseLength*song.fs) );
    %The sine window
    song.pulse = s .* sin( linspace(0,pi,song.pulseLength*song.fs));
    
    plot(song.pulse)
else
    error('Wrong Pulse Type, mate.')
end

%Check length of pulse, and trim if necessary.
if length(song.pulse) > song.pulseLength*song.fs,
    fprintf('Trimming pulse to expected size.')
    dif = length(song.pulse) - song.pulseLength*song.fs;
    song.pulse = song.pulse(  floor(dif/2) : floor(dif/2) + song.pulseLength*song.fs );
end



%% Make a group of pulses.

%Create a vector of zeros the length of the total sound from beginning to
%end of group.  This is ipi * #ofPulses-1 + onelastsong.  This makes a
%group that starts and ends with the pulses, with no trailing silence.
song.group = zeros(    ceil( song.ipiSamples*(song.pulsePerGroup) + song.groupTrailingSilenceSamples), 1  );
warning off
for i = 1:song.pulsePerGroup
    song.group( (1+(i-1)*song.ipiSamples) : (((i-1)*song.ipiSamples)+length(song.pulse))) = song.pulse;
end
warning on
song.groupLength = length(song.group);


%% Make a whole song.

song.leadingSilenceSamples = song.leadingSilence * song.fs;

song.song = zeros(  song.leadingSilenceSamples + ...
                    song.sineSongDuration * song.fs + ...
                    song.sinePulsePause  * song.fs  + ...
                    song.groupLength * song.numGroups + ...
                    (song.numGroups-1)*song.interGroupInterval*song.fs  + ...
                    song.trailingSilence*song.fs,1);

% Insert sine song
if song.sineSongDuration > 0,
    song.song(song.leadingSilenceSamples + [1:song.sineSongDuration*song.fs]) = song.sine_song;
    % For some reason this suffers floating point errors
    pulseStartIndex = round((song.leadingSilence+song.sineSongDuration+song.sinePulsePause)*song.fs);
else
    pulseStartIndex = 0;
end

% Insert pulses
for  i = 1:song.numGroups,
    song.song(  pulseStartIndex + 1 + (i-1)*song.groupLength+(i-1)*song.interGroupInterval*song.fs :...
        pulseStartIndex + (i-1)*song.groupLength+(i-1)*song.interGroupInterval*song.fs + song.groupLength ) = song.group;
end

% Convert song.song to single for .wav format.
song.song = single(song.song);


%% Play song?
if plot_and_play
    
    subplot(2,2,1)
    plot((1:length(song.pulse))/song.fs,song.pulse)
    axis tight
    title('Pulse')
    
    subplot(2,2,2)
    plot((1:length(song.group))/song.fs,song.group)
    axis tight
    title('Group')
    
    subplot(2,2,3:4)
    plot((1:length(song.song))/song.fs,song.song)
    axis tight
    title('Song')
    xlabel('Time (s)')
    title('Generated song')
    
    disp('Playing song!')
    audio_player = audioplayer(song.song,song.fs);
    play(audio_player)
    
    keyboard
end

