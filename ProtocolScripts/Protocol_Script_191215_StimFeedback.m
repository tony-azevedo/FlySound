setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all


clear A,    
imaqreset
A = Acquisition;

st = getacqpref('MC700AGUIstatus','status');
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','20');
if ~st
    MultiClamp700AGUI;
end

%% EpiFlash2T - 
setacqpref('AcquisitionHardware','LightStimulus','LED_Arduino')
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

%%
A.rig.devices.camera.setParams(...
    'ROICenterX','False',...
    'ROICenterY','False',...
    'ROIOffsetX',0,...
    'ROIOffsetY',0,...
    'ROIWidth',1280,...
    'ROIHeight',256)


%% EpiFlash2T - Fly IS in control

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

A.rig.devices.epi.setParams('controlToggle',0)
A.rig.setParams('interTrialInterval',0);

A.rig.devices.camera.dead
A.clearTags
A.tag('must kick')
%A.comment
A.run(40)

A.rig.devices.epi.setParams('controlToggle',0)
A.clearTags
A.tag('out of control')
%A.comment
A.run(1)

A.rig.devices.epi.setParams('controlToggle',1)

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',0,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

A.clearTags
A.tag('rest')
%A.comment
A.run(5)

A.rig.devices.camera.live
% A.rig.devices.camera.dead

% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)

%%




%% EpiFlash2T - Fly is Resting! No LED
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',0,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

A.rig.devices.epi.setParams('controlToggle',1)

A.rig.devices.camera.dead
A.clearTags
A.tag('Light off')
%A.comment
A.run(10)
A.rig.devices.camera.live
% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)

