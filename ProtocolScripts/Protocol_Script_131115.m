%% Whole cell current injections, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  

% Image initial activity

% Image spiking through hyperpolarization

% Image single elicited spikes.  Apply TTX, Image single spikes
% Image changes in flourescence through the CurrentPlateau protocol

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
A.tag('R_{input}')
A.run
A.untag('R_{input}')

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
A.setProtocol('CurrentPlateau');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.005,'plateaux',[-30 -20 -10 0 10 20 30]);
A.run(1)
systemsound('Notify');


