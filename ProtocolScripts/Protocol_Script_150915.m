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
A.run(2)
A.clearTags

%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)

%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(20)

%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:2:8); 
%freqs = 25 * sqrt(2) .^ (-1:1:9); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 10] * .05,'postDurInSec',1);
A.run(6)

%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0.1,...
    'freqEnd',400,...
    'displacements',[1  10] * .05,...
    'postDurInSec',2);
A.run(2)
systemsound('Notify');

%% Switch to voltage clamp

%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.15,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 20 40]);          % tune this 
A.run(4)

%% VoltageSines
amps = [2.5 7.5];
freqs = [25 100 141 200];

A.setProtocol('VoltageSine');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'stimDurInSec',.3,...
    'amps',amps,... % [10 40]
    'freqs',freqs,... % [10 40]
    'postDurInSec',.2)
A.run(12)


%% VoltageRamp Short
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'postDurInSec',0.2,...
    'stimulusName','VoltageRamp_m60_p40_h_0_5s');
A.run(5)
systemsound('Notify');


%% Switch to Current Clamp

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


%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-120 -100 -80 -60 -40 -20 -10 10 20 40]);          % tune this (-10:2:10))%
A.run(1)
systemsound('Notify');

