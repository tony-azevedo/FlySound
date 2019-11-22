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

%% EpiFlash2T 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

% A.clearTags
% A.tag
% A.comment
A.run(3)
% A.rig.devices.camera.live
% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)

%% Use the bath LED, not the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')

%% EpiFlash2T 
% Testing whether the RED BATH led by itself, pointed at the antenna, does
% anything


setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[0.02, 0.04],...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

% A.clearTags
% A.tag
% A.comment
A.run(4)
% A.rig.devices.camera.live
% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)


%% PiezoRamp2T extension
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',10,...
    'speeds',[300],...50*[6 3 2 1],...
    'displacements',[-1],...
    'stimDurInSec',.1,...
    'postDurInSec',.5);
% A.tag
A.run(6)
% A.clearTags

% cam = CameraBasler;
% cam.live


%% Try the mechanical stimulus along with the LED
setacqpref('AcquisitionHardware','LightStimulus','LED_Arduino')

%% PairedPiezoEpiFlash2T 

setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('PairedPiezoLEDFlash2T');

A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'piezoPreInSec',.5,...
	'piezoDurInSec',.1,...
    'displacements',-1,...
    'speeds',300,...
    'displacementOffset',10,...
    'ndfs',0,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

% A.clearTags
% A.tag
A.comment
A.run(10)
% A.rig.devices.camera.live
% A.rig.devices.camera.setParams(...
%     'framerate',50)
% A.rig.devices.camera.setParams(...
%     'framerate',170)


