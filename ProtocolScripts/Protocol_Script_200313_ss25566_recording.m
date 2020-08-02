setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all

clear A,    
A = Acquisition;

st = getacqpref('MC700AGUIstatus','status');
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','20');
if ~st
    MultiClamp700AGUI;
end

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


%% Use the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue')
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');


%% Sweep2T
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

A.rig.setParams('testvoltagestepamp',0)
A.rig.setParams('interTrialInterval',10);
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(4)


%% Current Step 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.5,...
    'steps',[ -.1 .25 .5  .75 1]* 50,... [ -.1 .25 .5  .75 1]
    'postDurInSec',1);
A.run(1)
% A.rig.devices.camera.live

%%
A.run(6)

%% EpiFlash2T % What happens when the fly is jamming on the bar?
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...
    'stimDurInSec',2,...
    'postDurInSec',2.5);
% A.tag
A.run(2)

%%
A.run(20)%(60)
% do 60 or so repeats!
% A.clearTags


%% Move the bar relative to origin
A.clearTags
A.tag

%% PiezoStep2T flexion
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
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
% A.tag

% cam = CameraBasler;
% cam.live

A.run(7)
% A.clearTags

%%% PiezoRamp2T flexion
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); 
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',0,...
    'speeds',50*[6 3 2 1],...
    'displacements',[10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
A.run(10)

%%% PiezoStep2T extension
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
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
A.run(7)

%%% PiezoRamp2T extension
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',10,...
    'speeds',50*[6 3 2 1],...
    'displacements',[-10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(10)
% A.clearTags



%% Move the bar relative to origin
A.clearTags
A.tag


%% Sweep2T, slow manipulator movement
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')

A.rig.applyDefaults;

A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.rig.devices.camera.setParams(...
    'framerate',50)


%%
A.clearTags
A.tag
A.run
A.rig.devices.camera.live

%% Maybe some TTX and try the relaxation of the probe
