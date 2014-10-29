% Fly song sample construction.
% Uses the songs from Mala's work.

testsong = load('1mintestsong');
easy = testsong.easy;
Fs_easy = testsong.Fs;
x_easy = (0:length(easy)-1)/Fs_easy;

[song0,Fs0] = wavread('CourtshipSong.wav');

song = interp(easy,round(Fs0/Fs_easy));
Fs = Fs0;
x = (0:length(song)-1)/Fs;


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
songLP = songLP/max(abs(songLP));

figure
plot(x(x>8 & x<=20),songLP,'color',[1 1 1]*.7), hold on;


%% Save the song for use with the Piezo
cd C:\Users\Anthony' Azevedo'\Code\FlySound\Rig' Calibration'

audiowrite(['LongCourtshipSong_Standard','.wav'],...
    songLP,...
    Fs,...
    'BitsPerSample',32);

