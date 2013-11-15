%% Whole cell current injections, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4 Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  Once through all the routines first, then acquire images second
% time through by toggling the camera


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

%%
toggleCameraPref('off')
toggleCameraPref('on')

%% Resting potential and oscillations (5x5 sec) Minimize current
% toggleCameraPref('on')
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('')
A.run(5)

systemsound('Notify');


%% Hyperpolarized
% toggleCameraPref('on')
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Hyperpolarized')
A.run(5)
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


%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.005,'steps',[20]);
A.run(5)
systemsound('Notify');

%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentPlateaux');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.005,'plateaux',[20]);
A.run(5)
systemsound('Notify');


