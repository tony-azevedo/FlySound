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
A.protocol.setParams('-q','durSweep',1);
A.tag('break-in')
A.run(1)
A.clearTags

%% Switch to current clamp
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

%% Check a 5 sec Sweep with camera on
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('sampratein',50000,'samprateout',50000,'durSweep',5);

A.run(1)
% Success, video is 4.9914 s long
% Success after specifying CameraBasler modelSerialNumber,

%% Check a 8 sec Sweep with camera on
% setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
% 
% A.rig.setParams('testvoltagestepamp',0)
% A.rig.applyDefaults;
% A.setProtocol('Sweep2T');
% A.protocol.setParams('sampratein',50000,'samprateout',50000,'durSweep',8);
% 
% A.run(5)
% % Success, video is 7.9922 s long
% 
% 
% % Check a 10 sec Sweep with camera on
% setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
% 
% A.rig.setParams('testvoltagestepamp',0)
% A.rig.applyDefaults;
% A.setProtocol('Sweep2T');
% A.protocol.setParams('sampratein',50000,'samprateout',50000,'durSweep',10);
% 
% A.run(1)
% 
% % Failure: Can't write this entire file (duration 9.037)
% 
% % Check a 12 sec Sweep with camera on
% setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
% 
% A.rig.setParams('testvoltagestepamp',0)
% A.rig.applyDefaults;
% A.setProtocol('Sweep2T');
% A.protocol.setParams('sampratein',50000,'samprateout',50000,'durSweep',12);
% 
% A.run(1)
% 
% % Failure: Can't write this entire file (duration 10.5440)

%% Check new EpiFlash2CB2T 
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue');
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

A.setProtocol('EpiFlash2CB2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.1,...
    'ndfs',1,...
    'stimDurInSec',4.8,...
    'postDurInSec',.1);
% A.tag
% A.run(5)

%% Check changing ROIs
A.rig.devices.camera.setParams(...
    'ROIHeight',512,...
    'ROIWidth',640);

% A.tag
% A.run(5)

