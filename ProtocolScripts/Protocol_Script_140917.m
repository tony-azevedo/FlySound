%% Whole cell voltage clamp, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;

% 64x64 on images on 1x to allow more light in.  This works better.  Procedure is:
% Before dropping the electrode in, start the baseline imaging routine.
% Check the camera properties
% Set up the directory
% Paste the images name
% check the frame rate
% Bring in the trode, make sure it's unblocked, etc.
% Patch the cell,
% move the 2x to 1x
% adjust the image scale
% stop live
% move to start trigger
% hit start on the camera
% start on the epoch


%% Seal
setpref('AcquisitionHardware','cameraToggle','off')
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Try to break in while imaging  Go to -50 mV (or -25 mV)
setpref('AcquisitionHardware','cameraToggle','off')
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Current Clamp, break in')
A.run(6)
A.untag('Current Clamp, break in')
systemsound('Notify');

%% Weird Ramping stimulus
% switch to current clamp
setpref('AcquisitionHardware','cameraToggle','on')

A.setProtocol('CurrentPlateau');
plateaux = [(-5:-5:-80), repmat(-80,1,6),-40,repmat(-80,1,6)];
A.protocol.setParams('-q','preDurInSec',1.5,...
    'postDurInSec',1.5,'plateauDurInSec',0.05,'plateaux',plateaux,'randomize',0);
A.run(3)
systemsound('Notify');

%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.5,...
    'steps',40);          % tune this
A.tag('Depolarizing steps')
A.run(5)
A.untag('Depolarizing steps')
systemsound('Notify');


%% CurrentChirp - up
A.setProtocol('CurrentChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',400,...
    'amps',[20],... % [10 40]
    'postDurInSec',1);
A.run(3)
systemsound('Notify');


