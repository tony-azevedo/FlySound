setpref('AcquisitionHardware','PGRCameraToggle','off')

% Start the bitch 
% clear all, close all
clear A
A = Acquisition;
%

%% Sweep - record the break-in

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',10);
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
A.protocol.setParams('-q','durSweep',15);
A.run(1)



%% Switch to current clamp

%% Sweep
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)

%% Current Step 
A.setProtocol('CurrentStep');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.1,...
    'stimDurInSec',.1,...
    'steps',4*[-2 5 10 15 20],... % [3 10]
    'postDurInSec',.1);
A.run(3)

%% Single spike 

A.setProtocol('CurrentStep');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.02,...
    'steps',15,... % [3 10]
    'postDurInSec',.1);
A.run(4)


%% tetanus  
A.setProtocol('CurrentPlateau');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'plateauDurInSec',.25,...
    'plateaux',12*(1:20),...
    'postDurInSec',.1);
A.run(3)

%% EpiFlash

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',.1,...
    'postDurInSec',6);
A.run(3)

%% Voltage steps, see if there is any way to affect the 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'steps',[-10 0 10 20 30],...
    'stimDurInSec',.2,...
    'postDurInSec',.2);
A.run(3)
