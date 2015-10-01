%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;
%
%%
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',0); A.run(1)

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
A.run(5)
A.clearTags

% -60, -80, -20 0
% Then into voltage clamp -60 -80 -20 0

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
    'preDurInSec',2,...
    'freqStart',0.1,...
    'freqEnd',300,...
    'amps',[3 10]*1,... % [10 40]
    'postDurInSec',2);
A.run(3)


%% PiezoSteps

% A.setProtocol('PiezoStep');
% A.protocol.setParams('-q',...
%     'preDurInSec',.2,...
%     'displacements',[1],...
%     'stimDurInSec',0.2000,...
%     'postDurInSec',.2);
% A.tag% 
% A.run(1)

% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
% A.tag
A.run(4)
% A.clearTags

%% PiezoSine

A.setProtocol('PiezoSine');
%freqs = 25 * sqrt(2) .^ (0:2:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1  10] * .05,'postDurInSec',1);
% A.clearTags
%A.tag('Cd')
A.run(3)


%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0.1,...
    'freqEnd',400,...
    'displacements',[1  10] * .05,...
    'postDurInSec',2);
A.run(2)

% A.setProtocol('PiezoChirp','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'freqStart',0.1,...
%     'freqEnd',400,...
%     'displacements',[1  10] * .05,...
%     'postDurInSec',2);
% A.protocol.CalibrateStimulus(A)

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
% A.clearTags

%% PiezoSine

A.setProtocol('PiezoSine');
%freqs = 25 * sqrt(2) .^ (0:2:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 10] * .05,'postDurInSec',1);
%A.tag('Cd')
A.run(3)

%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-100 -80 -60 -40 -20 -10 -5  5 10 20 40]);          % tune this 
A.run(1)

%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[ 80 120 160]);          % tune this (-10:2:10))%
A.run(3)
systemsound('Notify');

%% Apply Histamine and go again!

%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-120 -100 -80 -60 -40 -20 20 40]);          % tune this (-10:2:10))%
A.run(3)
systemsound('Notify');

%% Sweep different holding currents
A.setProtocol('Sweep');
A.rig.setParams('testcurrentstepamp',0)

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',10); A.tag('10'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',20); A.tag('20'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',30); A.tag('30'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-20); A.tag('-20'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-40); A.tag('-40'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-60); A.tag('-60'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-80); A.tag('-80'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-100); A.tag('-100'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

%%
A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-120); A.tag('-120'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-140); A.tag('-140'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

A.protocol.setParams('-q','durSweep',.1,'holdingCurrent',-160); A.tag('-160'); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(1);
A.clearTags

%%
A.protocol.setParams('-q','durSweep',0.1,'holdingCurrent',0); A.run(1)

A.rig.applyDefaults;
