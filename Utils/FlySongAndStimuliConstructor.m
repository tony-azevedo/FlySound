% Fly song sample construction.
% Uses the songs from Mala's work.

testsong = load('1mintestsong');
easy = testsong.easy;
Fs_easy = testsong.Fs;
x_easy = (0:length(easy)-1)/Fs_easy;

[song0,Fs0] = audioread('CourtshipSong.wav');

song = interp(easy,round(Fs0/Fs_easy));
Fs = Fs0;
x = (0:length(song)-1)/Fs;

%% spectrogram of easy song
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

subplot(2,1,2)
plot(x,song,'color',[0 0 1]), hold on;
plot(x,songLP,'color',[1 1 1]*.7), hold on;

linkaxes([subplot(2,1,1), subplot(2,1,2)]);

%% Select a snippet

songLP = songLP(x>8 & x<=20);

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


%% Save the song for use with the Piezo
cd C:\Users\Anthony' Azevedo'\Code\FlySound\Rig' Calibration'

audiowrite(['LongCourtshipSong_Standard','.wav'],...
    songLP,...
    Fs,...
    'BitsPerSample',32);

%%
sound(songLP,Fs)

%% Isolate some pulses.
% use those isolated 
Pulses = songLP(4.28401E5:4.482E5);

%% Find the frequency of the envelope 
figure
X_Pulses = hilbert(Pulses);
env_Pulses = abs(X_Pulses);

plot(Pulses),hold on
plot(env_Pulses,'r')

%%
figure
% [Pxx,F,pxxc] = pwelch(env_Pulses-mean(env_Pulses),'',[],[],Fs);
% semilogx(F(2:end),10*log10(Pxx(2:end)),'linewidth',1); hold on;
% semilogx(F(2:end),10*log10(pxxc(2:end,:)),'r--','linewidth',.5);

f = Fs/length(env_Pulses)*[0:length(env_Pulses)/2]; f = [f, fliplr(f(2:end-1))];

semilogx(f,real(abs(fft(env_Pulses-mean(env_Pulses)))),'linewidth',1); hold on;
xlim([1 800])
spectrum_Env = real(abs(fft(env_Pulses-mean(env_Pulses))));
f_max = f(spectrum_Env == max(spectrum_Env));
f_max = f_max(1);

%% 
Cycles = 10;
Pulses = repmat(Pulses,Cycles,1);
plot(Pulses)

sound(Pulses,Fs)

%%
[Pxx,F,pxxc] =pwelch(Pulses,'',[],[],Fs);
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
    
    plot(x_VS,env_VS); hold on;
    plot(x_VS,VaughanSong,'r');
    
    VaughanSong = repmat(VaughanSong,1,Cycles);

    audiowrite(['VaughanSong_' num2str(IPI) '_Standard','.wav'],...
        songLP,...
        Fs,...
        'BitsPerSample',32);
    
    sound(VaughanSong,Fs)
    pause
end

