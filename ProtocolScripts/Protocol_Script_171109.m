setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
A = Acquisition;

%% EpiFlash2T fast
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2TTrain');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.rig.devices.camera.setParams('framerate',75);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',5,...
    'nrepeats',20,...
    'flashDurInSec',.05,...
    'cycleDurInSec',.1,...
    'postDurInSec',.5);
% A.tag
A.run(8)
% A.clearTags

%% EpiFlash2T fast
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2TTrain');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.rig.devices.camera.setParams('framerate',150);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',5,...
    'nrepeats',20,...
    'flashDurInSec',.05,...
    'cycleDurInSec',.1,...
    'postDurInSec',.5);
% A.tag
A.run(8)
% A.clearTags


%% Piezo2T negative
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',10,...
    'displacements',[-10 -3 -1],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
A.run(3)

%% Piezo2T positive
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',0,...
    'displacements',[10 3 1],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
A.run(3)

%% Piezo2T sines
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoSine2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',3,...
    'displacements',[6],...
    'freqs', [.5 1 2],...
    'stimDurInSec',2,...
    'postDurInSec',.5);
% A.tag
A.run(3)
% A.clearTags

%% 
A.clearTags