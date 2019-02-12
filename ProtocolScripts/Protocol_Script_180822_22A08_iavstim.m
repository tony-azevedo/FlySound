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


%% Switch to current clamp
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

%% Sweep
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('sampratein',50000,'samprateout',50000,'durSweep',5);

A.run(5)


% %% Current Step 
% setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
% A.rig.applyDefaults;
% 
% A.setProtocol('CurrentStep2T');
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'stimDurInSec',.5,...
%     'steps',[-.10 .25 .5 1]* 200,... % [3 10]
%     'postDurInSec',1);
% A.run(1)

% %%
% A.run(6)

%% Use the bath LED, not the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')

%% EpiFlash2T % Pulse over 3 orders of magnitude
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

% A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',.5);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs', 10.^-(3:-.25:0) * 5,...
    'stimDurInSec',0.01,...
    'postDurInSec',1);
A.protocol.randomize;
A.protocol.randomizeIter

%     3.0000    2.7500    2.5000    2.2500    2.0000    1.7500    1.5000    1.2500    1.0000    0.7500    0.5000
%    0.2500         0

% A.clearTags

A.run(1)

A.comment
%% do 60 or so repeats!
A.run(7)

%% EpiFlash2T % Pulse over smaller range of magnitude
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

% A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.4,...
    'ndfs',10.^-(1.9:-.05:1.55) * 5,...
    'stimDurInSec',0.020,...
    'postDurInSec',3);
A.protocol.randomize;
% A.protocol.randomizeIter
A.tag
% A.clearTags

%A.run(1)

%% repeats!
A.run(5)

%% EpiFlash2T % longer pulse
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.4,...
    'ndfs',10.^-(4:-.5:1) * 5,...
    'stimDurInSec',0.2,... % 100 ms
    'postDurInSec',1);
A.protocol.randomize;
A.protocol.randomizeIter

A.run
% A.clearTags

%% do 60 or so repeats!
A.run(7)

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

cam = CameraBasler;
cam.live

A.run(7)
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
A.run(7)


% %% Piezo2TSine
% setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
% A.rig.applyDefaults;
% 
% A.setProtocol('PiezoSine2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'displacementOffset',2,...
%     'displacements',[6],...
%     'freqs', [1 2 4],...
%     'stimDurInSec',4,...
%     'postDurInSec',.5);
% % A.tag
% A.run(5)
% % A.clearTags

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
A.run(10)
% A.clearTags


%% Move the bar relative to origin
A.clearTags
A.tag

%% Piezo2T positive
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
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

%% Piezo2T slow 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
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


%% Piezo2T negative
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoStep2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
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




%% PLAY TIME: MORE MOVEMENT Use the Epis
% setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')
% 
% %% EpiFlash2T 
% setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
% A.rig.applyDefaults;
% 
% A.setProtocol('EpiFlash2T');
% 
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'ndfs',1,...
%     'stimDurInSec',1,...
%     'postDurInSec',4);
% % A.tag
% % A.clearTags
% A.run(10)
