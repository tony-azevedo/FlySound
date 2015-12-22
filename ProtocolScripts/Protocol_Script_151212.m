%% Whole cell voltage clamp, Cs internal, para,

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;
%

%% Sweep - record the break-in

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',15);
A.tag('break-in')
A.run(1)
A.clearTags


%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)


%% Switch to voltage clamp

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)

%% Voltage Steps 
A.rig.applyDefaults;
A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.12,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 15]);          % tune this 
A.run(6)

%% PiezoSteps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(8)

%% PiezoSine 
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (-1:1:9); 
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

%% VoltageSines
amps = [2.5 7.5];
freqs = [25 100 141 200];

A.setProtocol('VoltageSine');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'amps',amps,... % [10 40]
    'freqs',freqs,... % [10 40]
    'postDurInSec',.1)
A.run(12)

%% VoltageRamp 
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'postDurInSec',0.2,...
    'stimulusName','VoltageRamp_m50_p12_h_0_5s');
A.run(5)
systemsound('Notify');

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

%% PiezoSteps

A.rig.setParams('testcurrentstepamp',0)
A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(5)

%% PiezoSine 
A.rig.applyDefaults;
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:2:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
amps = [1  10] * .05;
% amps = [.3 1 3 10] * .05;

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',amps);
A.run(4)


%% curare
A.tag


%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)

%% Voltage Steps 
A.rig.applyDefaults;
A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.12,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 15]);          % tune this 
A.run(6)


%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
A.run(6)

%% PiezoSine 
A.rig.applyDefaults;
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ [4 5 6]; 
%freqs = 25 * sqrt(2) .^ [4 5 6]; 
amps = [3] * .05;

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',amps);
A.run(4)

%% VoltageSines
amps = [2.5 7.5];
freqs = [25 100 141 200];

A.setProtocol('VoltageSine');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'amps',amps,... % [10 40]
    'freqs',freqs,... % [10 40]
    'postDurInSec',.1)
A.run(12)


%% VoltageRamp 
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'postDurInSec',0.2,...
    'stimulusName','VoltageRamp_m50_p12_h_0_5s');
A.run(5)
systemsound('Notify');

%% TTX and Onward

A.tag

