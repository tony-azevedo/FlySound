%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
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
A.run(2)
A.clearTags

% -60, -80, -20 0
% Then into voltage clamp -60 -80 -20 0


%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-100 -80 -60 -40 -20 -10 -5  5 10 20 40]);          % tune this 
A.tag
A.run(2)

%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(2)
A.clearTags

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',300,...
    'amps',[10]*1,... % [10 40]
    'postDurInSec',2);
A.tag
A.run(3)


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

%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (1:1:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 3 10] * .05,'postDurInSec',1);
A.clearTags
%A.tag('Cd')
A.run(3)
systemsound('Notify');

%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',400,...
    'displacements',[1  10] *.05,...
    'postDurInSec',2);
A.run(2)
systemsound('Notify');


%% Switch to voltage clamp

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

%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (1:1:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 3 10] * .05,'postDurInSec',1);
A.clearTags
%A.tag('Cd')
A.run(3)
systemsound('Notify');


%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',400,...
    'displacements',[1  10] * .05,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(2)
A.clearTags

%% Sweep different holding potentials
A.setProtocol('Sweep');
A.rig.setParams('testvoltagestepamp',0)

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',10); A.tag('10'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',30); A.tag('20'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',30); A.tag('30'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',-10); A.tag('-10'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',-20); A.tag('-20'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',-30); A.tag('-30'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',-40); A.tag('-40'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',-50); A.tag('-50'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingPotential',0); A.run(1)

%%
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'stimulusName','VoltageRamp_m100_p20');
A.run(2)
systemsound('Notify');


%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(1)
A.clearTags

%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-120 -100 -80 -60 -40 -20 -10 10 20 40]);          % tune this (-10:2:10))%
A.tag
A.run(3)
systemsound('Notify');

%% Current injection characterization: looking for spikes

A.setProtocol('CurrentPlateau');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'plateauDurInSec',.5,...
    'plateaux',[-50 -80 -100 -100 -100 -89 -100 0],...
    'randomize',0);
A.tag
A.run(3)
systemsound('Notify');


%% Sweep different holding potentials
A.setProtocol('Sweep');
A.rig.setParams('testcurrentstepamp',0)

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',10); A.tag('10'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',20); A.tag('20'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',30); A.tag('30'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-20); A.tag('-20'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-40); A.tag('-40'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-60); A.tag('-60'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-80); A.tag('-80'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-100); A.tag('-100'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags
%%
A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-120); A.tag('-120'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-140); A.tag('-140'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.25,'holdingCurrent',-160); A.tag('-160'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',0.25,'holdingCurrent',0); A.run(1)

A.rig.applyDefaults;

%% Current injection characterization
A.rig.applyDefaults;
A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.05,...
    'postDurInSec',0.5,...
    'steps',[-10 5 10 15 20]);          % tune this (-10:2:10))%
A.tag
A.run(3)
systemsound('Notify');


%%% Current injection characterization: looking for spikes

% A.setProtocol('CurrentPlateau');
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',1.5,...
%     'postDurInSec',1.5,...
%     'plateauDurInSec',.5,...
%     'plateaux',[-50 -80 -80 -80 -80 -61 -80 0],...
%     'randomize',0);
% A.tag
% A.run(1)
% systemsound('Notify');


%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',400,...
    'freqEnd',0,...
    'displacements',[1 10] *.1,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


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


