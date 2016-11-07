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
A.protocol.setParams('-q','durSweep',6);
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
    'preDurInSec',.4,...
    'stimDurInSec',.2,...
    'steps', 10*[-.5 5 10 15 20],... % [3 10]
    'postDurInSec',.4);
A.run(1)

%% Single spike 

A.setProtocol('CurrentStep');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.02,...
    'steps',10,... % [3 10]
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
setpref('AcquisitionHardware','PGRCameraToggle','on') % This turns on the point grey camera below the foil

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',.25,...
    'postDurInSec',6);
A.run(3)

%% M285 motor program

setpref('AcquisitionHardware','PGRCameraToggle','on') % This turns on the point grey camera below the foil
A.setProtocol('ManipulatorMove');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'stimDurInSec',1,...
    'postDurInSec',8);
A.run(1)

%% Sweep - Just playing around

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',10);
A.tag('check video')
A.run(5)
A.clearTags


%% Voltage steps, see if there is any way to affect the 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'steps',[-10 0 10 20 30],...
    'stimDurInSec',.2,...
    'postDurInSec',.2);
A.run(3)

%% 

A.tag('Caffeine')


