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


%% Record with 5X, 50Hz for cameratwin to get nice bright signals for clusters
setacqpref('AcquisitionHardware','cameraBaslerToggle','on');

setacqpref('AcquisitionHardware','LightStimulus','LED_Blue');
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

A.setProtocol('EpiFlash2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.1,...
    'ndfs',1,...
    'stimDurInSec',2,...
    'postDurInSec',.1);

% change ROIs
A.rig.devices.camera.setParams(...
    'framerate',25,...
    'ROICenterX','False',...
    'ROICenterY','False',...
    'ROIOffsetX',640,...
    'ROIOffsetY',0,...
    'ROIWidth',640,...
    'ROIHeight',512);

% A.rig.devices.camera.live
% A.rig.devices.camera.dead
% A.rig.devices.cameratwin.live
% A.rig.devices.cameratwin.dead

%%
A.tag
A.run(15)
A.clearTags

%% Record with 5X, 100Hz for cameratwin to compare to clustering signals

A.rig.devices.cameratwin.setParams(...
    'framerate',100);

% A.rig.devices.camera.live
% A.rig.devices.camera.dead
% A.rig.devices.cameratwin.live
% A.rig.devices.cameratwin.dead

%%
A.tag
A.run(45)
A.clearTags


%% Put the bar in and run again.
A.rig.devices.camera.setParams(...
    'framerate',50);

% A.rig.devices.camera.live
% A.rig.devices.camera.dead
%%
A.rig.devices.camera.setParams(A.rig.devices.camera.getDefaults)

%% Run again
% A.rig.devices.camera.live
% A.rig.devices.camera.dead
% A.rig.devices.cameratwin.live
% A.rig.devices.cameratwin.dead
A.tag
A.run(45)
