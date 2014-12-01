%% Construction of Stimuli sample construction.
[song0,Fs0] = audioread('CourtshipSong.wav');
x = 0:Fs0-1/Fs0;
y = zeros(size(x));
for start = 0:2:8;
    y(start*Fs0/10+1:(start+1)*Fs0/10) = 1;
end

plot(x,y);

% cd C:\Users\Anthony' Azevedo'\Code\FlySound\StimulusWaves\
% 
% audiowrite(['Basic_Standard','.wav'],...
%     y,...
%     Fs0,...
%     'BitsPerSample',32);

%% Uses the songs from Mala's work.

testsong = load('1mintestsong');
easy = testsong.easy;
Fs_easy = testsong.Fs;
x_easy = (0:length(easy)-1)/Fs_easy;

[song0,Fs0] = audioread('CourtshipSong.wav');

song = interp(easy,round(Fs0/Fs_easy));
Fs = Fs0;
x = (0:length(song)-1)/Fs;

figure
plot(x,song)
xlabel('Time (s)'), ylabel('A.U.'), title('''Easy'' song')
set(gcf,'name','Easy_song_ArthurEtAl')


%% spectrogram of easy song
df = 800/256;
f = df:df:800;

figure;
ax = subplot(1, 1,1,'parent',gcf);
[S,F,T,P] = spectrogram(song-mean(song),2048,1024,f,Fs);

P(P< mean(P(end,:))) = mean(P(end,:));
colormap(ax,'jet') % 'Hot'

%pcolor(ax,T,F,10*log10(P));
h = pcolor(T,F,abs(S));
set(h,'EdgeColor','none');


%% Filter Design
rad_per_sample = 2*pi/Fs;
Fp_Hz = 2000;
Fp_rad_per_samp = Fp_Hz * rad_per_sample;
Fst_Hz = 2500;
Fst_rad_per_samp = Fst_Hz * rad_per_sample;
Allowable_ripple = .5; %DB
Attenuation = 60; %DB

d=fdesign.lowpass('Fp,Fst,Ap,Ast',...
    Fp_rad_per_samp,...
    Fst_rad_per_samp,...
    Allowable_ripple,...
    Attenuation);

designmethods(d)

Hd = design(d,'butter');
fvtool(Hd);

[gd,w] = grpdelay(Hd);
plot(w,gd)

%%

songLP = filter(Hd,song);

figure
subplot(2,1,1)
plot(x_easy,easy), hold on;
plot(x,song,'color',[1 1 1]*.7), hold on;
xlabel('Time (s)'), ylabel('A.U.'), title('Easy song, interpolated')

subplot(2,1,2)
plot(x,song,'color',[0 0 1]), hold on;
plot(x,songLP,'color',[1 1 1]*.7), hold on;
xlabel('Time (s)'), ylabel('A.U.'), title('Easy song, filtered')

linkaxes([subplot(2,1,1), subplot(2,1,2)]);
set(gcf,'name','Interpolation_and_filtering')


%% Select a snippet

songLP = songLP(x>8 & x<=20);
x_LP = x(x>8 & x<=20)-8;
figure
plot(x(x>8 & x<=20),songLP,'color',[1 1 1]*.7), hold on;
xlabel('Time (s)'), ylabel('A.U.'), title('Chosen Song Snippet')
set(gcf,'name','Chosen_Song_Snippet')

%% spectrogram of LP easy
df = 800/256;
f = df:df:800;

figure;
ax = subplot(1, 1,1,'parent',gcf);
[S,F,T,P] = spectrogram(songLP-mean(songLP),2048,1024,f,Fs);

P(P< mean(P(end,:))) = mean(P(end,:));
colormap(ax,'jet') % 'Hot'

%pcolor(ax,T,F,10*log10(P));
h = pcolor(T,F,abs(S));
set(h,'EdgeColor','none');

xlabel('Time (S)'), ylabel('Hz'), title('Chosen Snippet Spectrogram')
set(gcf,'name','Chosen_Song_Spectrogram')

%% Save the song for use with the Piezo
sound(songLP,Fs)
% cd C:\Users\Anthony' Azevedo'\Code\FlySound\StimulusWaves\
% 
% audiowrite(['LongCourtshipSong_Standard','.wav'],...
%     songLP,...
%     Fs,...
%     'BitsPerSample',32);

%%

%% Isolate some pulses.
% use those isolated 
close all;

Pulses = songLP(4.28381E5:4.48202E5);
x_Pulses = x_LP(4.28381E5:4.48202E5) - x_LP(4.28380E5);

%% Find the analytic signal (hilbert transform)
figure
set(gcf,'name','Hilbert Transform')
X_Pulses = hilbert(Pulses);
env_Pulses = abs(X_Pulses);
phase_Pulses = angle(X_Pulses);

subplot(3,1,[1 2])
plot(x_Pulses,Pulses),hold on
plot(x_Pulses,env_Pulses,'r');

ylabel('A.U.'), title('Chosen Snippet (blue), Envelope (red)')

subplot(3,1,3)
plot(x_Pulses,phase_Pulses,'g');


xlabel('Time (S)'), ylabel('radians'), title('Rotation in complex space')

linkaxes([subplot(3,1,[1 2]), subplot(3,1,3)],'x');

%% It'd be nice to see the angular velocity of the Hilbert transform

%% Measure the frequency of the envelope
figure
f = Fs/length(env_Pulses)*[0:length(env_Pulses)/2]; f = [f, fliplr(f(2:end-1))];

semilogx(f,real(abs(fft(env_Pulses-mean(env_Pulses)))),'linewidth',1); hold on;
xlim([1 800])
spectrum_Env = real(abs(fft(env_Pulses-mean(env_Pulses))));
f_max = f(spectrum_Env == max(spectrum_Env));
f_max = f_max(1)

xlabel('Frequency (Hz)'), ylabel('A.U.'), title('Envelope Spectrum'), 
set(gcf,'name','Envelope_Spectrum')

%% Find the snippet of pulses with the right length (integer times env_freq)
DeltaT = 1/f_max;

N_pulses = x_Pulses(end)/DeltaT
DeltaT_N = floor(N_pulses) * DeltaT;

x_Pulses_1 = x_Pulses(x_Pulses<=DeltaT_N);
Pulses_1 = Pulses(x_Pulses<=DeltaT_N);
Pulses_1(1:50) = (0:49)'/49 .* Pulses_1(1:50);
Pulses_1(end-50+1:end) = (49:-1:0)'/49 .* Pulses_1(end-50+1:end);

figure
plot(x_Pulses_1,Pulses_1);

xlabel('Frequency (Hz)'), ylabel('A.U.'), title('Snippet of Pulses (tapered ends)'), 
set(gcf,'name','Pulse_Snippet')

%% 
Cycles = 10;
x_Pulses_N = 0:Cycles*length(Pulses_1)-1;
x_Pulses_N = x_Pulses_N/length(Pulses_1);
Pulses_N = repmat(Pulses_1,Cycles,1);
Pulses_N = Pulses_N/max(abs(Pulses_N));

figure

plot(x_Pulses_N,Pulses_N);

xlabel('Frequency (Hz)'), ylabel('A.U.'), title('Repeated Pulse Snippet'), 
set(gcf,'name','Pulse_Repeat')

%sound(Pulses_N,Fs)

%% Save the song for use with the Piezo
sound(Pulses_N,Fs)

% cd C:\Users\Anthony' Azevedo'\Code\FlySound\StimulusWaves\
% 
% audiowrite(['PulseSongRepeat_Standard','.wav'],...
%     Pulses_N,...
%     Fs,...
%     'BitsPerSample',32);


%%
[Pxx,F,pxxc] =pwelch(Pulses_N,'',[],[],Fs);
semilogx(F(2:end),10*log10(Pxx(2:end)),'linewidth',1); hold on;
semilogx(F(2:end),10*log10(pxxc(2:end,:)),'r--','linewidth',.5);



%% VaughanSong
% Synthetic song Synthetic pulse song was generated as a series of Gaussianwindowed
% pulses with a 260hz intrapulse frequency (IPF) and a half-width of
% 6ms, with bursts of 5 pulses presented at 30% duty cycle. Variant songs using
% other IPIs preserved the number of pulses within each burst as well as the burst
% duty cycle, and therefore varied in the duration of each burst. For “scrambled
% song” controls, IPIs within a burst were uniformly distributed between
% approximately 0 and 70ms.

N_pulses = 5; 
w_pulse = .006/2.355; % ms
Dutycycle = .3;
Cycles = 10;
IPIs = [.02, .03 , .04, .05 .06]; %ms
for IPI = IPIs
    FullCycle = 5*IPI * (1+.7/Dutycycle);
    pulse_ind = FullCycle*(1-Dutycycle)/2-IPI/2+(IPI:IPI:5*IPI); %ms
    
    x_VS = (0:FullCycle*Fs-1)/Fs;
    
    F_IPF = 260; % Hz
    
    env_VS = zeros(size(x_VS));
    for p_ind = 1:length(pulse_ind)
        env_VS = env_VS + normpdf(x_VS,pulse_ind(p_ind),w_pulse);
    end
    
    env_VS = env_VS/max(env_VS);
    
    IPF = sin(F_IPF*2*pi*x_VS);
    
    VaughanSong = IPF.*env_VS;
    
    %     plot(x_VS,env_VS); hold on;
    %     plot(x_VS,VaughanSong,'r');
    
    VaughanSongLong = repmat(VaughanSong,1,Cycles);

    audiowrite(['VaughanSong_' num2str(IPI*1000) '_Standard','.wav'],...
        VaughanSongLong,...
        Fs,...
        'BitsPerSample',32);
    
    %
    %pause
end
figure
plot(x_VS,env_VS,'r'); hold on;
plot(x_VS,VaughanSong,'b');
xlabel('Frequency (Hz)'), ylabel('A.U.'), title('Vaughan Song (synthetic pulses)'), 
set(gcf,'name','Vaughan_Song')


sound(VaughanSong,Fs)

