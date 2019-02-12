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

%% Switch to current clamp: Use the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue')
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

%% Sweep2T
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(20)

%% Current Step 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.5,...
    'steps',[-.5 -.25  .25 .5, 1]* 80,... % [3 10]
    'postDurInSec',1.5);
A.run(1)

%%
A.run(10)

%% EpiFlashTrain % what about when the bar is gone
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2TTrain');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...
    'nrepeats',5,...
    'flashDurInSec',.05,...
    'cycleDurInSec',.4,...
    'postDurInSec',2);

% A.rig.devices.camera.live
% A.rig.devices.camera.dead

%%
A.tag
A.run(5)
A.clearTags


%% Piezo2TSine
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoSine2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',2,...
    'displacements',[6],...
    'freqs', [1 2 4],...
    'stimDurInSec',4,...
    'postDurInSec',.5);
% A.tag
A.run(5)
% A.clearTags

%% Move the bar relative to origin
A.clearTags
A.tag

%% Piezo2T positive
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
A.run(7)
% A.clearTags
% 
% cam = CameraBasler;
% cam.live

%% Piezo2T ramp 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',0,...
    'speeds',50*[6 3 2 1],...
    'displacements',[10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(7)
% A.clearTags

%% Piezo2T negative
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

%% Piezo2T ramp negative
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
A.run(7)
% A.clearTags



%% Move the bar relative to origin
A.clearTags
A.tag


%% Sweep2T, slow manipulator movement
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')

A.rig.applyDefaults;

A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',10);

A.rig.devices.camera.setParams(...
    'framerate',50)

A.run(10)

%% Use manipulator to boing boing and record video and sensory

% % M285 motor program
% setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
% 
% x = -1; % outof (+)/ into (-) board (x)
% y = 0; % left(+)/right(-) (y)
% A.setProtocol('ManipulatorMove2T');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'stimDurInSec',2,...
%     'pause',1,...
%     'velocity',50,...
%     'coordinate',{[200, 0, 0]},...
%     'return',0,...
%     'postDurInSec',2);
% A.run
% % cam = CameraBasler;
% % cam.live
% 
% 
% %% Now add Atropine and MLA, look at current injection and sensory feedback.