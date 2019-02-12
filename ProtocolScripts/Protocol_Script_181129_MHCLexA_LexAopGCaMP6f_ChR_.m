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


% %% Order of operations
% % 1: Dissect and look at cells, determine Genotype
% % 2: a little imaging with head intact
% % 3: MLA on, wait, image
% % 4: TTX on, wait, image.
% % 5: Cut head, image


%% New Order of operations
% 1: Dissect, detach head
% 2: Position EMG, bar, canula
% 3: Flash, record emg and leg pulse
% 4: TTX wash on, periodically flash same intensity, every 30 seconds or so
% 5: When the spikes are gone, give one nice flash while imaging leg


%% EpiFlash2T - Find intensity
setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[0.88,0.94 1]*5,...
    'stimDurInSec',0.050,...
    'postDurInSec',1);
A.protocol.setDefaults
% A.tag
% A.clearTags

%%
A.run

%% Find the right intensity
A.protocol.setParams('-q',...
    'ndfs',.4);
A.run

%% Start TTX, image flashes
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')
A.setProtocol('EpiFlash2T');

A.rig.devices.camera.setParams(...
    'framerate',50,... % 169
    'ROIWidth',1280,...
    'ROIHeight',1024);

A.protocol.setParams('-q',...
    'ndfs',5);

%%
A.rig.setParams('interTrialInterval',0);
A.run(5)


%% Record with 5X, 50Hz for cameratwin to get nice bright signals for clusters

setacqpref('AcquisitionHardware','LightStimulus','LED_Blue');
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

A.setProtocol('EpiFlash2CB2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'ndfs',1,...
    'stimDurInSec',1,...
    'postDurInSec',1.5);

% change ROIs
A.rig.devices.camera.setParams(...
    'framerate',50,...
    'ROIWidth',1280,...
    'ROIHeight',1024);

A.rig.devices.cameratwin.setParams(...
    'framerate',50,...
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
A.clearTags
A.tag
A.run(6)

%% Sweep2T, slow manipulator movement
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')

A.rig.applyDefaults;

A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',10);

A.rig.devices.camera.setParams(...
    'framerate',50)

A.run(10)

%% Record with 5X, 50Hz for cameratwin to get nice bright signals for clusters

setacqpref('AcquisitionHardware','LightStimulus','LED_Blue');
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

A.setProtocol('EpiFlash2CB2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',5);
A.protocol.setParams('-q',...
    'preDurInSec',.1,...
    'ndfs',1,...
    'stimDurInSec',4.8,...
    'postDurInSec',.1);

% change ROIs
A.rig.devices.camera.setParams(...
    'framerate',169,...
    'ROIWidth',1280,...
    'ROIHeight',1024);

A.rig.devices.cameratwin.setParams(...
    'framerate',50,...
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
A.run(10)
A.clearTags
