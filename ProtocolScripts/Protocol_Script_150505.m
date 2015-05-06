%% Whole cell voltage clamp, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  

setpref('AcquisitionHardware','cameraToggle','on')

% Start the bitch 
% clear all, close all
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



%% Try to break in while imaging  Go to -50 mV (or -25 mV)
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',15);
A.tag('Voltage Clamp, break in')
A.run(1)
A.untag('Voltage Clamp, break in')
systemsound('Notify');

%% Immediately go to different plateaus to measure ArcLight 
% switch to current clamp

A.setProtocol('VoltagePlateau');
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'stimDurInSec',0.02,...
    'plateaux',[-10 0 -20 0 -30 0 -40 0 -50 0 10 0 20 0 30],...
    'randomize',0);
A.run(6)
systemsound('Notify');

%% Turn the camera off
setpref('AcquisitionHardware','cameraToggle','off')

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Sweep

A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(4)
systemsound('Notify');


%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-40 -30 -20 -10 -5  5 10 20 30 40]);          % tune this 
A.tag
A.run(3)
A.clearTags

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',300,...
    'amps',[3 10]*.5,... % [10 40]
    'postDurInSec',2);
A.tag
A.run(3)
A.clearTags

%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-4 -3 -2 -1    1 2 3 4]);          % tune this
A.tag
A.run(5)
A.clearTags


%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-10 10 20 40]);          % tune this
A.run(5)

%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.tag
A.run(5)
A.clearTags
 

%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (-1:10); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[3 10 30] * .05,'postDurInSec',1);
A.tag
A.run(3)
systemsound('Notify');
A.untag

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[3  30]*.0667,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[3  30]*.0667,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Long Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.protocol.setParams('-q','displacements',[3 10 30]*.0667,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[3 10 30] *.0667,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[3 10 30] *.0667,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

%% Pulses
A.setProtocol('PiezoStimulus');
A.protocol.setParams('-q',...
    'stimulusName','PulseSongRepeat',...
    'preDurInSec',2,...
    'displacements',[-30 -10 -3 3 10 30]*.0667,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

%% PiezoSteps to record motion!

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-3],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags

