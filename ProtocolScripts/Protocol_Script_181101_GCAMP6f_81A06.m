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
    'ROICenterX','True',...
    'ROICenterY','True',...
    'ROIOffsetX',0,...
    'ROIOffsetY',0,...
    'ROIWidth',640,...
    'ROIHeight',512);

% A.rig.devices.camera.live
% A.rig.devices.camera.dead

%% Image Cell Bodies
A.tag
A.run(10)
A.clearTags


%% image processes?
A.tag
A.run(10)
A.clearTags
