%% Whole cell voltage clamp, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  

setpref('AcquisitionHardware','cameraToggle','on')

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

need = [-50 -25 -50 -35]


%% Try to break in while imaging  Go to -50 mV (or -25 mV)
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',15);
A.tag('Voltage Clamp, break in')
A.run(1)
A.untag('Voltage Clamp, break in')

%% Immediately go to different plateaus to measure ArcLight 
% switch to current clamp

A.setProtocol('VoltagePlateau');
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'plateauDurInSec',0.2,...
    'plateaux',[-10 0 -20 0 -30 0 -40 0 -50 0 10 0 20 0 30],'randomize',0);
A.run(6)
systemsound('Notify');

%% Voltage Steps 
A.rig.applyDefaults;
A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.12,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 15 25]);          % tune this 
A.run(4)

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')


%% Turn the camera off
setpref('AcquisitionHardware','cameraToggle','off')


%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqStart',0,...
    'freqEnd',300,...
    'amps',[5]*1,... % [3 10]
    'postDurInSec',.5);
A.run(4)

%% Current Step 
A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.1,...
    'steps',[-10 5 10 20 40],... % [3 10]
    'postDurInSec',.1);
A.run(4)


%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(7)

%% PiezoSine 
A.rig.applyDefaults;
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:2:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
amps = [1  10] * .05;
amps = [.3 1 3 10] * .05;

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',amps);
A.run(4)


%% %%%%%%% 
% Hyperpolarize the cell
A.tag('Hyperpolarized')

%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(7)

%% PiezoSine 
A.rig.applyDefaults;
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:2:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
amps = [1  10] * .05;
amps = [.3 1 3 10] * .05;

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',amps);
A.run(4)

%% %%%%%%% Un hyperpolarize
% Hyperpolarize the cell
A.untag('Hyperpolarized')


%% PiezoAM
% A.setProtocol('PiezoAM','modusOperandi','Cal');
% A.protocol.CalibrateStimulus(A)
A.setProtocol('PiezoAM');
A.run(4)

%% Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.protocol.setParams('-q','displacements',[-1  1],'postDurInSec',1);
A.run(1)

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[-3 3] * .05,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[-3 3] * .05,'postDurInSec',1);
A.run(3)
systemsound('Notify');


