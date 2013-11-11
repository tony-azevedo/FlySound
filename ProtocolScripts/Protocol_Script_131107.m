%% Whole cell current injections, trying to patch using the hamamatsu

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% R_input
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)
systemsound('Notify');

%% Resting potential and oscillations - Hyperpolarized
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Hyperpolarized')
A.run(5)
systemsound('Notify');

%% Inject current to drive a spike
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,'postDurInSec',0.5,'stimDurInSec',0.005,'steps',[10,20,30]);
A.run(5)
systemsound('Notify');

%% Move the Antenna
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','cycles',10,'displacement',1);
A.run(5)
systemsound('Notify');


%% PiezoSine 
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 ],'postDurInSec',1);

A.run(3)
beep
