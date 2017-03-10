setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
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

% 19951 - 16068

%% Acquire
A.rig.setParams('testvoltagestepamp',0)
A.rig.setParams('testcurrentstepamp',0)
setpref('AcquisitionHardware','PGRCameraToggle','off')

A.setProtocol('Acquire');
A.run

%% Acquire

A.rig.stop
A.comment

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.run(3)



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
    'preDurInSec',.25,...
    'stimDurInSec',.25,...
    'steps', 150* [.25 .5 .75 1],... % [3 10]
    'postDurInSec',.25);
A.run(20)

%% Salkoff Wyman protocols

% tetanus  
A.setProtocol('CurrentPlateau');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'plateauDurInSec',.06,...
    'plateaux',100 * [0 2.5 0 2.5 0 1 0 1 0 1 0],...
    'postDurInSec',.1);
A.run(3)


%% EpiFlash
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.devices.camera.setParams('framerate',40);
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',1,...
    'postDurInSec',7);
A.run(10)

%% M285 motor program

x = -1; % outof (+)/ into (-) board (x)
y = 0; % left(+)/right(-) (y)
% setpref('AcquisitionHardware','PGRCameraToggle','on') % This turns on the point grey camera below the foil
A.setProtocol('ManipulatorMove');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'stimDurInSec',2,...
    'pause',1,...
    'velocity',5000,...
    'coordinate',{[0, -50, 0], [00, -100, 0]},...
    'return',1,...
    'postDurInSec',2);
A.run(2)

%% Sweep - Just playing around

setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',2);
% 

A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',2);
A.rig.devices.camera.setParams('framerate',35);
% A.tag('check video')
A.run(2)
% A.untag('check video')


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
%%
A.tag('Pilocarpine 50 uM')

%%
A.comment

