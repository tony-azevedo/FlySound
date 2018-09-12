setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all


clear A,    
A = Acquisition;
st = getacqpref('MC700AGUIstatus','status');
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','50');
if ~st
    MultiClamp700AGUI;
end

%% Sweep - record the break-in

A.setProtocol('Sweep');
A.rig.applyDefaults; A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults

A.protocol.setParams('-q','durSweep',10);
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000);
A.protocol.setDefaults;
A.tag('break-in')
A.run(1)
A.clearTags

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')


%% Switch to current clamp, single electrode:

%% Sweep
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','50');

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(5)


%% Switch to current clamp, single electrode:

%% Use the bath LED, not the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue')
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','50');

%% Sweep2T
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(5)


%% Current Step 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'steps',[.5,.75, 1]* 200,... % [3 10]
    'postDurInSec',.1);

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(2)


%% EpiFlash2T 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5 ,...
    'ndfs',1,...
    'stimDurInSec',2,...
    'postDurInSec',2.5);
% A.tag
% A.clearTags

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(5)
% do 60 or so repeats!

%% EpiFlashTrain 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2TTrain');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...
    'nrepeats',5,...
    'flashDurInSec',.02,...
    'cycleDurInSec',.2,...
    'postDurInSec',1);
% A.tag
A.run(10)
% A.clearTags

%% Piezo2T positive
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
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

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

cam = CameraBasler;
cam.live
% A.rig.devices.camera.live
%%
A.run(10)
% A.clearTags

%% Piezo2T negative
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
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
A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(10)


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

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(5)
% A.clearTags

%% Piezo2T slow negative
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',10,...
    'speeds',50*[3 2 1],...
    'displacements',[-10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(10)
% A.clearTags

%% Piezo2T slow 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',0,...
    'speeds',50*[3 2 1],...
    'displacements',[10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag

A.rig.setParams('sampratein',50000); A.rig.setParams('samprateout',50000);A.rig.setDefaults;
A.protocol.setParams('-q','sampratein',50000,'samprateout',50000); A.protocol.setDefaults;

A.run(10)
% A.clearTags

%% Move the bar relative to origin
A.clearTags
A.tag

%% Piezo2T positive
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
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
A.run(5)
% A.clearTags

%% Piezo2T negative
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
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
A.run(5)

%% Piezo2T slow negative
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',10,...
    'speeds',50*[3 2 1],...
    'displacements',[-10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(5)
% A.clearTags

%% Piezo2T slow 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',0,...
    'speeds',50*[3 2 1],...
    'displacements',[10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(5)
% A.clearTags
