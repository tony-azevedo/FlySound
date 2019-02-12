setacqpref('AcquisitionHardware','cameraBaslerToggle','off');

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

%% Switch to current clamp

%% Sweep
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','50');

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.run(5)

%% Use the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','50');

%% EpiFlash 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.1,...
    'ndfs',10,...
    'stimDurInSec',2.8,...
    'postDurInSec',.1);

% change ROIs
% A.rig.devices.camera.setParams(...
%     'framerate',50,...
%     'ROIWidth',1280,...
%     'ROIHeight',1024);

A.rig.devices.camera.setParams(...
    'framerate',100,...
    'ROIWidth',1280,...
    'ROIHeight',1024);


% A.rig.devices.camera.live
% A.rig.devices.camera.dead

%%
A.tag
A.run(10)
A.clearTags

