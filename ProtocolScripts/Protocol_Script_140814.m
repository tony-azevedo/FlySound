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


%% Collect images in HCImageLive
% (2ms exposure time)

A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.tag('baseline fluorescence')
A.run(1)
A.untag('baseline fluorescence')
systemsound('Notify');

%% PiezoChirp - Attempt to stimulate
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[0.2],'postDurInSec',1);
A.run(3)
systemsound('Notify');

% %% PiezoChirp - Attempt to stimulate
% A.setProtocol('PiezoChirp');
% A.protocol.setParams('-q',...
%     'freqStart',800,...
%     'freqEnd',17,...
%     'displacements',[0.2],'postDurInSec',1);
% A.run(3)
% systemsound('Notify');

% %% Calibration settings
% A.setProtocol('PiezoChirp','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'freqStart',800,...
%     'freqEnd',17,...
%     'displacements',[0.8],...
%     'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)

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
A.run(1)
A.untag('Current Clamp, break in')
systemsound('Notify');

%% Immediately go to different plateaus to measure ArcLight 
% switch to current clamp
setpref('AcquisitionHardware','cameraToggle','on')

A.setProtocol('VoltagePlateau');
A.protocol.setParams('-q','preDurInSec',1.5,...
    'postDurInSec',1.5,'stimDurInSec',0.02,'plateaux',[-10 0 -20 0 -30 0 -40 0 -50 0 10 0 20 0 30],'randomize',0);
A.run(6)
systemsound('Notify');

%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.4,...
    'postDurInSec',0.5,...
    'steps',-65);          % tune this
A.tag('Hyperpolarizing steps')
A.run(5)
A.untag('Hyperpolarizing steps')
systemsound('Notify');


%% Turn the camera off
setpref('AcquisitionHardware','cameraToggle','off')

%% PiezoSteps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
systemsound('Notify');

%% Turn the camera on
setpref('AcquisitionHardware','cameraToggle','on')

%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[0.2 .8],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Turn the camera off
setpref('AcquisitionHardware','cameraToggle','off')

%% PiezoChirp - down
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[0.2 .8],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% CurrentChirp - up
A.setProtocol('CurrentChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',800,...
    'amps',[2.5 10],... % [10 40]
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% CurrentChirp - down
A.setProtocol('CurrentChirp');
A.protocol.setParams('-q',...
    'freqStart',800,...
    'freqEnd',17,...
    'amps',[2.5 10],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% %%%%%%% 
% Hyperpolarize the cell
A.tag('Hyperpolarized')

%% Inject current to hyperpolarize and cause rebound spike-like activity
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
A.protocol.setParams('-q','Vm_id',0);
A.run(10)
systemsound('Notify');

%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[0.2 .8],...
    'postDurInSec',1);
A.run(2)
systemsound('Notify');

%% PiezoChirp - down
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[0.2 .8],...
    'postDurInSec',1);
A.run(2)
systemsound('Notify');

%% CurrentChirp - up
A.setProtocol('CurrentChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',800,...
    'amps',[10],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% CurrentChirp - down
A.setProtocol('CurrentChirp');
A.protocol.setParams('-q',...
    'freqStart',800,...
    'freqEnd',17,...
    'amps',[10, 40],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');


%% %%%%%%% 
% Go to voltage clamp
A.untag('Hyperpolarized')
A.tag('VClamp')

%% R_input - switch back to voltage clamp - hold at nominal resting potential
A.setProtocol('SealAndLeak');
A.tag('R_{input}')
A.run
A.untag('R_{input}')

%% PiezoSteps
A.setProtocol('PiezoStep');
A.run(5)
systemsound('Notify');

%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[0.2 .8],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% PiezoChirp - down
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[0.2 .8],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Play time
A.untag('VClamp')

%% PiezoSine
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:10); 
A.protocol.setParams('-q','freqs',freqs,'displacements',[0.1 0.2 0.4],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% PiezoSine VClamp adaptation protocol
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:10); 
A.protocol.setParams('-q',...
    'freqs',freqs(4:8),...
    'displacements',[0.1 0.2 0.4],...
    'stimDurInSec',2,...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');


%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Then run TTX to try to eliminate spiking
A.tag('Curare 5uM')

