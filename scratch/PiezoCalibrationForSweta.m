%% Piezo Stimulus Correction Script

% deliver 5 sine wave stimulus amplitudes using protocols as I will for the
% experiment {0.5, 1, 2, 4}.  Establishing only these amps and freqs as
% possibilities for now  

% This is a basic outline of the algorithm. You can find the original code at 
% https://raw.githubusercontent.com/tony-azevedo/FlySound/master/Rig%20Calibration/piezoChirpCalibration.m
% But it calls my functions for running trials, different from how you do
% it. So, below I just say, "get some data", then you can use the rest of
% the code as you see it here.

%% Run this until the correction is stable and the amplitude is accurate

% stim is what you plan to provide to the peizo, the target stim is what
% you hope it will do in response
% [~,stim,targetstim] = A.protocol.getStimulus;
stim = wavread('Name_of_Current_Stimulus_File.wav');

% make a time vector
t = makeInTime(A.protocol);
N = 3;

% pre allocate some space
trials = zeros(length(t),N);

for n = 1:N
    % Acquire three (N) trials worth of data
    A.run;
    % get  the strain gauge sensor signal (sgsmonitor)
    trials(:,n) = A.rig.inputs.data.sgsmonitor;
end
sgs = mean(trials,2);

f = figure(101);clf
ax = subplot(1,1,1,'parent',f); hold(ax,'on');

plot(ax,t,stim,'color',[.7 .7 .7])
plot(ax,t,targetstim,...
    'color',[1 0 0])

plot(ax,t,trials,'color',[.7 .7 1])
plot(ax,t,sgs,'color',[0 0 1])

% baseline correct the sgs
sgs = sgs - mean(sgs(10:2000));
stim = stim - stim(1);
targetstim = targetstim - targetstim(1);

% align your sgs and intended stim, don't worry about temporal offset as
% long as the shape is similar
[C, Lags] = xcorr(sgs,stim,'coeff');
figure(102);
plot(Lags,C);

i_del = Lags(C==max(C));
t_del = t(find(t==0)+i_del);
figure(103); %clf
plot(t(1:end-i_del),targetstim(1:end-i_del),'color',[.7 .7 .7]), hold on
plot(t(1:end-i_del),sgs(i_del+1:end)), hold off

% subtract the difference between you sgs and your targetstim
diff = targetstim(1:end-i_del)-sgs(i_del+1:end);
diff = diff/A.protocol.params.displacement;
diff = diff(t(1:end-i_del)>=0 & t(1:end-i_del)<A.protocol.params.stimDurInSec);

% add the 
[oldstim,fs,NBITS] = wavread('Name_of_Current_Stimulus_File.wav');
newstim = oldstim+diff;

figure(104),clf, hold on
plot(oldstim,'color',[.7 .7 .7])
plot(newstim,'r')
plot(diff),

%% go to the folder where these command signals are kept and save the old version and write the new version
cd C:\Users\Anthony' Azevedo'\Code\FlySound\Rig' Calibration'\
cur_cs_fn = length(dir('CourtshipSong_*.wav'));
copyfile('CourtshipSong.wav',['CourtshipSong_' num2str(cur_cs_fn) '.wav'],'f')

wavwrite(newstim,fs,NBITS,'Name_of_Current_Stimulus_File.wav');
