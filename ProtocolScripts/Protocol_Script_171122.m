setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
A = Acquisition;
st = getpref('MC700AGUIstatus','status');
setpref('MC700AGUIstatus','mode','VClamp')
setpref('MC700AGUIstatus','VClamp_gain','50')
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


%% Switch to current clamp, single electrode:

%% Sweep
setpref('MC700AGUIstatus','mode','IClamp')
setpref('MC700AGUIstatus','IClamp_gain','50')

A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);

A.run(1)


%% Switch to current clamp, single electrode:

%% Sweep2T
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',6);
A.run(5)



%% EpiFlash2T
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...
    'stimDurInSec',2,...
    'postDurInSec',2.5);
% A.tag
A.run(10)
% A.clearTags

%% Current Step 
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams(...
    'preDurInSec',.5,...
    'stimDurInSec',1,...
    'steps',[-.25 -.125 .125 .25 .5 1]* 100,... % [3 10]
    'postDurInSec',1);
A.run(3)

%% Piezo2T positive
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacementOffset',0,...
    'displacements',[10 3 1],...
    'stimDurInSec',.5,...
    'postDurInSec',1);
% A.tag
A.run(5)
% A.clearTags

%% Piezo2T negative
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacementOffset',10,...
    'displacements',[-10 -3 -1],...
    'stimDurInSec',.5,...
    'postDurInSec',1);
A.run(5)


%% Piezo2TSine
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoSine2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',2,...
    'displacements',[6],...
    'freqs', [1 2 4],...
    'stimDurInSec',4,...
    'postDurInSec',.5);
% A.tag
A.run(5)
% A.clearTags

%% Piezo2T slow negative
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
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
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
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


%% Piezo2T slow by hand, just move the leg with the manipulator
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

% A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',10);
A.run(3)
% A.clearTags


%% Current Step 
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',.5,...
    'steps',[-.5 -.25 .5 1]* 75,... % [3 10]
    'postDurInSec',.3);
A.run(3)

%% EpiFlash2T
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2TTrain');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...
    'stimDurInSec',2,...
    'postDurInSec',2.5);
% A.tag
A.run(10)
% A.clearTags


%% Sweep with the LED over the eye. see what the fly does
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',4);
A.run(10)
% A.clearTags

