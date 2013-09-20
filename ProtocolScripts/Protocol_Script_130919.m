%% Cell-attached recordings
% Start the bitch
A = Acquisition;

%% trode
A.setProtocol('SealAndLeak');
A.comment('Trode')
A.run

%% Seal
A.setProtocol('SealAndLeak');
A.comment('Seal')
A.run

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('durSweep',5);
A.comment('Resting potential and oscillations ')
A.run(5)
beep 

%% Steps
A.setProtocol('PiezoStep');
A.comment('At rest (5x5 sec)')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% Big Step
A.setProtocol('PiezoSquareWave');
A.comment('At rest (5x5 sec)')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% PiezoSine
A.setProtocol('PiezoSine');
A.comment('At rest')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 ],'postDurInSec',1.5);
A.run(3)
beep

%% Amplitude modulation of 100Hz stimulus


%% Courtship song



%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.comment('At rest')
%A.comment('TTX at rest')
A.protocol.setParams('freqs',[50 100 200],'displacements',[0.4],'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.run(10)
beep
