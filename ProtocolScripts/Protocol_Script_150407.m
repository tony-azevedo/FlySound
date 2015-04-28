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
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

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
systemsound('Notify');


%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',300,...
    'amps',[3 10]*1,... % [10 40]
    'postDurInSec',2);
A.tag
A.run(4)
systemsound('Notify');

%% Inject current to hyperpolarize 
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-4 -3 -2 -1    1 2 3 4]);          % tune this
A.tag
A.run(5)
systemsound('Notify');


%% Inject current to drive spikes
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-10 10 20 40]);          % tune this
A.run(5)
systemsound('Notify');

%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
% A.tag
A.run(4)
systemsound('Notify');
% A.clearTags

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
A.run(6)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
A.run(6)
systemsound('Notify');

%% Long Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Pulses
A.setProtocol('PiezoStimulus');
A.protocol.setParams('-q',...
    'stimulusName','PulseSongRepeat',...
    'preDurInSec',2,...
    'displacements',[-2 -.6325 -.2 .2 .6325 2],...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (-1:10); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[3 10 30] * .05,'postDurInSec',1);
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

%% PiezoNoise - same seed

A.setProtocol('PiezoNoise');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'seed',25,...
    'randomseed',0,...
    'stimDurInSec',20,...
    'displacements',1,...
    'postDurInSec',2);
A.run(10)
systemsound('Notify');

% [39, 94, 123, 169, 186, 222, 368, 396, 436, 440, 449]
% %%
% A.setProtocol('PiezoNoise','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'seed',25,...
%     'randomseed',0,...
%     'stimDurInSec',20,...
%     'displacements',1,...
%     'postDurInSec',2);
% A.protocol.CalibrateStimulus(A)

%% PiezoNoise - random seed

A.setProtocol('PiezoNoise');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'seed',25,...
    'randomseed',1,...
    'stimDurInSec',20,...
    'displacements',[1],...
    'postDurInSec',2);
A.run(5)
systemsound('Notify');

% [436, 292, 140, 93, 206, 59, 368, 396, 436, 440, 449]
%%
% A.setProtocol('PiezoNoise','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'seed',39,...
%     'randomseed',0,...
%     'stimDurInSec',20,...
%     'displacements',1,...
%     'postDurInSec',2);
% A.protocol.CalibrateStimulus(A)


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

