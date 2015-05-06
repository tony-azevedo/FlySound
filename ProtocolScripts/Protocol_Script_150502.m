%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, %close all
A = Acquisition;

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
A.tag
A.run(4)
A.clearTags

% Then hyperpolorize -60, -80, -20 0
% Then into voltage clamp -60 -80 -20 0

%% Just to compare to ArcLight Recordings
% switch to current clamp
A.setProtocol('VoltagePlateau');
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'stimDurInSec',0.02,...
    'plateaux',[-10 0 -20 0 -30 0 -40 0 -50 0 10 0 20 0 30],...
    'randomize',0);
A.run(3)

%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-80 -60 -40 -20 -10 -5  5 10 20 40]);          % tune this 
A.tag
A.run(2)

% %% Voltage Steps - Hyperpolarize to -80
% 
% A.setProtocol('VoltageStep');
% A.protocol.setParams('-q',...
%     'preDurInSec',0.5,...
%     'stimDurInSec',0.2,...
%     'postDurInSec',0.2,...
%     'steps',[-20 -10 -5  5 10 20 30 40]);          % tune this 
% A.tag
% A.run(3)

%% Sweep - in CurrentClamp

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(2)
A.clearTags
% Then down to -80, -60, up to -20

%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-100 -80 -60 -40 -20 -10 10 20 30 40]);          % tune this (-10:2:10))%
A.tag
A.run(2)
systemsound('Notify');

%% Current injection characterization: looking for spikes

A.setProtocol('CurrentPlateau');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'plateauDurInSec',.5,...
    'plateaux',[-50 -80 -100 -100 -95 -100 0],...
    'randomize',0);
A.tag
A.run(3)
systemsound('Notify');


%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[ -10 2 5 10 20]);          % tune this (-10:2:10))%
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
freqs = 25 * sqrt(2) .^ (0:2:10); 
%freqs = 25 * sqrt(2) .^ (-1:1:10); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[3 30] * .05,'postDurInSec',1);
A.clearTags
%A.tag('Cd')
A.run(2)
systemsound('Notify');

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(2)
A.clearTags

%% PiezoChirp - up
% A.setProtocol('PiezoChirp');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'freqStart',17,...
%     'freqEnd',800,...
%     'displacements',[1 10] *.1,...
%     'postDurInSec',2);
% A.run(3)
% systemsound('Notify');
% 
% %% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',400,...
    'displacements',[1 10] *.1,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

%% PiezoChirp - down

% A.setProtocol('PiezoChirp');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'freqStart',800,...
%     'freqEnd',17,...
%     'displacements',[1 10] *.1,...
%     'postDurInSec',2);
% A.run(3)
% systemsound('Notify');
% 
% %% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',400,...
    'freqEnd',0,...
    'displacements',[1 10] *.1,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');
