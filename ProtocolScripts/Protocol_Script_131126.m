%% Targeted patch recordings of VT30609 - the suspected cell, 
% ie, 1.5 according to yesterday's recordings, top left bright one.
% Then cell attached once I have determined the sensitivity to sound

% Start the bitch 
A = Acquisition;

%% trode- use the resistance button

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% 2 nd time around do this
A.tag('TTX')
A.untag('TTX')

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)
systemsound('notify')


%% Hyperpolarized
% toggleCameraPref('on')
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Hyperpolarized')
A.run(3)
A.untag('Hyperpolarized')
systemsound('Notify');

%% Spiking, somewhere in between
% toggleCameraPref('on')
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Spiking')
A.run(5)
A.untag('Spiking')
systemsound('Notify');


%% Steps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
beep 


%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','Vm_id',0);
A.protocol.setParams('-q','cycles',10,'displacement',1);
A.run(5)
beep 

%% PiezoSine
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 ],'postDurInSec',1);
A.run(3)
beep

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4],'postDurInSec',1);
A.run(3)
beep

%% Backwards Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4],'postDurInSec',1);
A.run(3)
beep

%% Amplitude modulation of 100Hz stimulus


%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentSine');
A.protocol.setParams('-q',...
    'freqs',[25,50,100,200,400],'amps',[20],...
    'postDurInSec',1);
A.run(5)
systemsound('Notify');

%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.02,'steps',[-40, -80, -120]);
A.run(5)
systemsound('Notify');

%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.02,'steps',[10, 20, 30 40]);
A.run(5)
systemsound('Notify');


%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentSine');
A.protocol.setParams('-q',...
    'freqs',[25,50,100,200,400],'amps',[20],...
    'postDurInSec',1);
A.run(5)
systemsound('Notify');


%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.tag('Ringing')
A.protocol.setParams('-q','freqs',[50 100 200],...
    'displacement',[0.4],'displacements',[0.4],...
    'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.run(3)
A.untag('Ringing')
beep

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_{input}')
A.run
A.untag('R_{input}')

%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[50 100 200],'displacements',[0.4],'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.tag('Ringing')
A.run(10)
A.untag('Ringing')
beep

