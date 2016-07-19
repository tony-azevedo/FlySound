setpref('AcquisitionHardware','PGRCameraToggle','off')

% Start the bitch 
% clear all, close all
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
A.protocol.setParams('-q','durSweep',1);
A.run(4)



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
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'steps',5*[10 15 20],... % [3 10]
    'postDurInSec',.1);
A.run(1)

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
    'plateaux',20*[1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1],... % [3 10]
    'postDurInSec',.1);
A.run(3)

%% EpiFlash
setpref('AcquisitionHardware','PGRCameraToggle','off')

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',1,...
    'postDurInSec',4);
A.run(2)

