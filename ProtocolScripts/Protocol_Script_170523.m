setacqpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
A = Acquisition;

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


%% Sweep
setacqpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(1)


%% Switch to current clamp

%% Sweep
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)


%% Sweep2T
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(3)


%% Current Step 
setacqpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',0.2,...
    'steps', 200* [.25 .5 .75 1],... % [3 10]
    'postDurInSec',1);
A.run(2)

%% Current Step -> Movement?
setacqpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',0.5,...
    'steps', 100* [.15 .25 .5 1],... % [3 10]
    'postDurInSec',1);
A.run(5)


%% EpiFlash2T
setacqpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacements',[10],...
    'stimDurInSec',4,...
    'postDurInSec',.5);
% A.tag
A.run(4)
% A.clearTags

%% Piezo2T
setacqpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',-10,...
    'displacements',[1 3 10 20],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(4)
% A.clearTags

%% Current Step 
setacqpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.1,...
    'steps',[100],... % [3 10]
    'postDurInSec',.1);
A.run(4)