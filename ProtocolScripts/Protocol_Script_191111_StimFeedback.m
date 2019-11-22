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
% This is the basic control loop paradigm, very simple, just turns the LED
% on through the Arduino, then waits for it to turn off. The light goes off
% at the end of a block to give the fly a break.

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


%% 1) FIRST - see what the fly does in response to movement
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

%% 2)Pair mechanical stimulus with light flash - learning?
%% Try the mechanical stimulus along with the LED
setacqpref('AcquisitionHardware','LightStimulus','LED_Arduino')

%% PairedPiezoEpiFlash2T

setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
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



%% 3) Just do two piezo pulses! Or one! This is the thing we need.
%%
% The PairedPiezoEpiFlash idea was a good start, now need one that can be
% triggered by the arduino at the right time

clear A,    
A = Acquisition;

setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PairedPiezoArduino2T');

% set the Piezo stimulus here
%%
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'piezoPreInSec',1,...
	'piezoDurInSec',.5,...
    'stimDurInSec',4,...
    'postDurInSec',.5);

% A.clearTags
% A.tag
% A.comment
% A.run
