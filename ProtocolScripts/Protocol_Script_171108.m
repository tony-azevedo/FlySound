setacqpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
A = Acquisition;


%% EpiFlash2T
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue')
setacqpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.rig.devices.camera.setParams('framerate',75);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[1],...
    'stimDurInSec',4,...
    'postDurInSec',.5);
% A.comment
A.run(60)

%% Piezo2T negative
setacqpref('AcquisitionHardware','cameraToggle','on')
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
setacqpref('AcquisitionHardware','cameraToggle','on')
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
setacqpref('AcquisitionHardware','cameraToggle','on')
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