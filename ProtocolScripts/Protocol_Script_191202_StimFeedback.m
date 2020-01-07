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


%% Use the bath LED, not the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Arduino')

%% EpiFlash2T - 

setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

%% - Fly is NOT in control
A.rig.devices.epi.setParams('controlToggle',0)

% A.clearTags
% A.tag
% A.comment
A.run(2)
% A.rig.devices.camera.live
% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)

%% EpiFlash2T - Fly IS in control


A.rig.devices.epi.setParams('controlToggle',1)

A.run(12)

%% EpiFlash2T - Fly IS in control


A.rig.devices.epi.setParams('controlToggle',1)

A.comment
A.run(4)
%A.run(10)
% A.rig.devices.camera.live
% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)
% 
% 
%%

% %% 1) FIRST - see what the fly does in response to movement
% %% PiezoRamp2T extension
% setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
% A.rig.applyDefaults;
% 
% A.setProtocol('PiezoRamp2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'displacementOffset',10,...
%     'speeds',[300],...50*[6 3 2 1],...
%     'displacements',[-1],...
%     'stimDurInSec',.1,...
%     'postDurInSec',.5);
% % A.tag
% A.run(6)
% % A.clearTags
% 
% % cam = CameraBasler;
% % cam.live
% 
% %% 2)Pair mechanical stimulus with light flash - learning?
% %% Try the mechanical stimulus along with the LED
% setacqpref('AcquisitionHardware','LightStimulus','LED_Arduino')
% 
% 
% %% 3) Just do one Piezo pulse triggered by the movement. This is the thing we need.
% %%
% 
% clear A,    
% setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
% A = Acquisition;
% 
% 
% setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
% A.rig.applyDefaults;
% 
% A.setProtocol('PairedPiezoArduino2T');
% 
% % set the Piezo stimulus here
% 
% %%
% A.rig.setParams('interTrialInterval',1);
% A.protocol.setParams('-q',...
%     'preDurInSec',1.5,...
%     'piezoPreInSec',1,...
% 	'piezoDurInSec',0,...
%     'stimDurInSec',4,...
%     'postDurInSec',.5);
% 
% A.rig.devices.arduino.setParams('controlToggle',1)
% 
% % A.clearTags
% % A.tag
% % A.comment
% A.run(3)
