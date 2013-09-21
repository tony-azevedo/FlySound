%% Cell-attached recordings
% Start the bitch
A = Acquisition;

%% trode
A.setProtocol('SealAndLeak');
A.tag('Trode')
A.run
A.untag('Trode')

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Trode')
A.run
A.untag('Trode')

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.run(5)
beep 

%% Steps
A.setProtocol('PiezoStep');
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% PiezoSine
A.setProtocol('PiezoSine');
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 ],'postDurInSec',1.5);
A.run(3)
beep

%% Amplitude modulation of 100Hz stimulus


%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('displacements',[0.1 0.2 0.4],'postDurInSec',1.5);
A.run(5)
beep

%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.tag('Ringing')
%A.tag('TTX at rest')
A.protocol.setParams('freqs',[50 100 200],'displacements',[0.4],'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.run(10)
A.untag('Ringing')
beep

%% %%%%%%%  TTX %%%%%%%%%
A.tag('TTX')

%% PiezoSine ringing test
A.setProtocol('PiezoSine');

%A.tag('TTX at rest')
A.protocol.setParams('freqs',[50 100 200],'displacements',[0.4],'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.run(10)
A.untag('Ringing')
beep


