% pulse is generated as a Gabor wavelet: sin(2pfT+phi)*gaussian
pulseDur = 16;%ms, pulse duration
pulsePau = 20;%ms - pause between pulses - IPI is pulseDur+pulsePau
Fs = 10000;%Hz, stimulus sampling frequency
trainDuration = 4;%seconds, pulse train duration
pulsePauses = [4 20 40 60 80];%ms
pulseCar = 250;%Hz, pulse carrier frequency
T = (1:pulseDur*Fs/1000)'/Fs;
car = sin(2*pi*T*pulseCar + pi/4);% sinusoid with pulse duration and pulse carrier frequency
env = gausswin(pulseDur*Fs/1000,3.5);% envelope generating the pulse amplitude profile
pulse = env.*car;%scale such that max=1, use: normalizeMax(env.*car)*sqrt(2)/1000;to scale such that peak rms=1

for pau = 1:length(pulsePauses)
   pulseSingle = [pulse; zeros(pulsePauses(pau)*Fs/1000,1)];% append pulse pause to pulse
   pulseTrain = repmat(pulseSingle,trainDuration*ceil(Fs/length(pulseSingle)),1);% concatenate multiple pulses
   
   subplot(length(pulsePauses), 4, (pau-1)*4 + 1)
   plot((1:length(pulseSingle))/Fs*1000, pulseSingle,'k','LineWidth',2)
   xlabel('time [ms]'), ylabel('voltage'), title('single pulse w/ pause')
   axis(gca,'tight')
   set(gca,'XLim',[1 100])
   
   subplot(length(pulsePauses), 4, (pau-1)*4 + (2:4))
   plot((1:length(pulseTrain))/Fs*1000, pulseTrain,'k','LineWidth',2)
   xlabel('time [ms]'), ylabel('voltage'), title('pulse train')
   axis(gca,'tight')
   
   stim = pulseTrain;% for the playback software we need a 1xT vector called 'stim'
   % save pulse parameters
   pulseParam.pulseDuration = pulseDur;
   pulseParam.pulsePause = pulsePauses(pau);
   pulseParam.pulseCarrier = pulseCar;
   
   save(['pulseTrain_' int2str(pulseDur+pulsePauses(pau)) 'IPI'], 'stim','pulseParam');
end
