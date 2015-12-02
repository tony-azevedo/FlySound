%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;
%

%% Sweep - record the break-in

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',25);
A.tag('break-in')
A.run(1)
A.clearTags


%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(2)

%% Voltage Steps 
A.rig.applyDefaults;
A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.12,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 15]);          % tune this 
A.run(6)

%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)

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


%% PiezoSteps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'displacementOffset',5,...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(8)

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'displacementOffset',8,...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(8)

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'displacementOffset',2,...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(8)

%% PiezoSine
A.rig.setParams('testcurrentstepamp',0)
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
A.run(5)

%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0.1,...
    'freqEnd',400,...
    'displacements',[1  10] * .05,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


%% PiezoAM
% A.setProtocol('PiezoAM','modusOperandi','Cal');
% A.protocol.CalibrateStimulus(A)
A.setProtocol('PiezoAM');
A.run(2)


%% Courtship song
% A.setProtocol('PiezoCourtshipSong');
% A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
% A.run(6)
% systemsound('Notify');

% %% Courtship song
% A.setProtocol('PiezoBWCourtshipSong');
% A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
% A.run(6)
% systemsound('Notify');

% Long Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.protocol.setParams('-q','displacements',[-1 -.3 .3 1],'postDurInSec',1);
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

