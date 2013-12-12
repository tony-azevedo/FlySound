%% Whole cell current injections, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  

% Image initial activity (2ms exposure time)
% Image Stimulus evoked activity (2ms exposure time)

% Sweep and image while breaking in (long exposures) 20ms
% (50Hz)

% Image changes in flourescence through the CurrentPlateau protocol

% Image single elicited spikes. Image single spikes
% Image spiking through hyperpolarization
% Image spiking through hyperpolarization

% Image stimulus evoked activity

setpref('AcquisitionHardware','cameraToggle','on')

% Start the bitch 
clear all, close all
A = Acquisition;

%% Collect images in HCImageLive
% (2ms exposure time)

%% PiezoSine - Attempt to stimulate
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[25,50,100,200,400],'displacements',[0.4],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Try to break in while imaging!
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',15);
A.tag('Voltage Clamp, break in')
A.run(1)
A.untag('Voltage Clamp, break in')
systemsound('Notify');

%% Immediately go to different plateaus to measure ArcLight 
% switch to current clamp

A.setProtocol('CurrentPlateau');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.02,'plateaux',[-40 0 -80 0 -120],'randomize',0);
A.run(3)
systemsound('Notify');

%% Hyperpolarize and inject current to drive a spike
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.01,'steps',[40]);  % tune this
A.tag('Hyperpolize')
A.run(5)
A.untag('Hyperpolize')
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
A.setProtocol('CurrentStep');
A.protocol.setParams('-q','preDurInSec',0.2,...
    'postDurInSec',0.5,'stimDurInSec',0.01,'steps',[-80]);
A.run(5)
systemsound('Notify');


%% R_input 
% switch back to voltage clamp
A.setProtocol('SealAndLeak');
A.tag('R_{input}')
A.run
A.untag('R_{input}')

%% Then run TTX to try to eliminate spiking

A.tag('TTX')

%% Inject current to drive a spike
% toggleCameraPref('on')
A.setProtocol('CurrentSine');
freqs = 25 * sqrt(2) .^ (0:10); 
%freqs = freqs([1 3 5 6 7 9 10]); %  25 50 70.7107  100 141.4214  200 400
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'amps',[2.5 5 10 ],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% PiezoSine
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:10); 
%freqs = freqs([1 3 5 6 7 9 10]); %  25 50 70.7107  100 141.4214  200 400
A.protocol.setParams('-q','freqs',freqs,'displacements',[0.1 0.2 0.4],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Steps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
systemsound('Notify');


%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','Vm_id',0);
A.protocol.setParams('-q','cycles',10,'displacement',1);
A.run(5)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4],'postDurInSec',1);
A.run(3)
systemsound('Notify');

