%% Whole cell current injections, trying to patch using the hamamatsu

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
A.tag('90 mM Sodium')
A.untag('90 mM Sodium')
A.tag('50 mM Sodium')
A.untag('50 mM Sodium')
A.tag('27 mM Sodium')
A.untag('27 mM Sodium')
A.tag('TTX')


%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)
beep 

%% hyperpolarize
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5,'Vm_ID',-3);
A.tag('Hyperpolarized')
A.run(5)
A.untag('Hyperpolarized')
beep 


%% Inject current to drive a spike
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,'postDurInSec',0.5,'stimDurInSec',0.005,'steps',[10,20,30]);
A.run(5)
beep 


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
A.tag('Seal')
A.run
A.untag('Seal')



%% %%%%%%%  TTX %%%%%%%%%
A.tag('TTX')

%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[50 100 200],'displacements',[0.4],'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.tag('Ringing')
A.run(10)
A.untag('Ringing')
beep

%% Courtship song TTX
A.setProtocol('PiezoCourtshipSong');
A.tag('TTX')
A.protocol.setParams('displacements',[0.1 0.2 0.4],'postDurInSec',1);
A.run(5)
beep

