%% Piezo Amplitude Correction Script

% deliver 5 sine wave stimulus amplitudes using protocols as I will for the experiment {0.5, 1, 2, 4}.  Establishing only these amps and freqs as possibilities for now

A = Acquisition; 
A.setProtocol('PiezoCourtshipSong','modusOperandi','Cal');
stem = regexprep(A.getRawFileStem,'\\','\\\');

%% Run this until the correction is stable and the amplitude is accurate
A.run;
[~,stim,targetstim] = A.protocol.getStimulus;

t = makeInTime(A.protocol);
N = 3;

trials = zeros(length(A.rig.inputs.data.sgsmonitor),N);

for n = 1:N;
    A.run;
    trials(:,n) = A.rig.inputs.data.sgsmonitor;
end
sgs = mean(trials,2);

f = figure(101);clf
ax = subplot(1,1,1,'parent',f); hold(ax,'on');

plot(ax,A.protocol.x,stim,'color',[.7 .7 .7])
plot(ax,A.protocol.x,targetstim,...
    'color',[1 0 0])
plot(ax,t,trials,'color',[.7 .7 1])
plot(ax,t,sgs,'color',[0 0 1])


sgs = sgs - mean(sgs(10:2000));
stim = stim - stim(1);
targetstim = targetstim - targetstim(1);

[C, Lags] = xcorr(sgs,stim,'coeff');
figure(102);
plot(Lags,C);

i_del = Lags(C==max(C));
t_del = t(find(t==0)+i_del);
figure(103); %clf
plot(t(1:end-i_del),targetstim(1:end-i_del),'color',[.7 .7 .7]), hold on
plot(t(1:end-i_del),sgs(i_del+1:end)), hold off

diff = targetstim(1:end-i_del)-sgs(i_del+1:end);
diff = diff/A.protocol.params.displacement;
diff = diff(t(1:end-i_del)>=0 & t(1:end-i_del)<=A.protocol.params.stimDurInSec);

[oldstim,fs,NBITS] = wavread('CourtshipSong.wav');
newstim = oldstim+diff;

figure(104),clf, hold on
plot(oldstim,'color',[.7 .7 .7])
plot(newstim,'r')
plot(diff),

%%
cd C:\Users\Anthony' Azevedo'\Code\FlySound\Rig' Calibration'\
cur_cs_fn = length(dir('CourtshipSong_*.wav'));
copyfile('CourtshipSong.wav',['CourtshipSong_' num2str(cur_cs_fn) '.wav'],'f')

wavwrite(newstim,fs,NBITS,'CourtshipSong.wav');