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
A.protocol.setParams('-q','durSweep',1);
A.run(5)



%% EpiFlash2T
% setpref('AcquisitionHardware','cameraToggle','on')
% A.rig.applyDefaults;
% 
% A.setProtocol('EpiFlash2T');
% A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'ndfs',1,...
%     'stimDurInSec',1,...
%     'postDurInSec',3);
% % A.tag
% A.run(7)
% % A.clearTags

%% Use the bath LED, not the Epis
setpref('AcquisitionHardware','LightStimulus','LED_Bath')

%% EpiFlash2T looking for 1, 2, 3 spikes
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
% A.rig.setParams('testcurrentstepamp',-2); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[.075,.0825, .1]*3,...
    'stimDurInSec',.040,...
    'postDurInSec',.5);
% A.tag
A.run(8)
% do 60 or so repeats!
% A.clearTags

%%
A.tag
A.clearTags
A.tag
A.clearTags


%% EpiFlash2T looking for 4, 5,...10 spikes
setpref('AcquisitionHardware','cameraToggle','on')
setpref('AcquisitionHardware','LightStimulus','LED_Bath')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[.0825,.9,.95,.1]*3.7,...
    'stimDurInSec',.020,...
    'postDurInSec',.5);
% A.tag
A.run(5)
% do 60 or so repeats!
% A.clearTags

%% repeat singles for -200 and -100
A.tag
A.clearTags
A.tag
A.clearTags

%% Piezo2T positive
setpref('AcquisitionHardware','cameraToggle','off')
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
A.run(10)
% A.clearTags

%% Piezo2T negative
setpref('AcquisitionHardware','cameraToggle','off')
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
A.run(10)


%% Piezo2TSine
setpref('AcquisitionHardware','cameraToggle','off')
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
A.run(5)
% A.clearTags

%% Piezo2T slow negative
setpref('AcquisitionHardware','cameraToggle','off')
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

%% Piezo2T slow 
setpref('AcquisitionHardware','cameraToggle','off')
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


%% Piezo2T slow by hand, just move the leg with the manipulator
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',10);
A.run(3)
% A.clearTags


%% Current Step 
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'steps',[.25,.5, 1]* 250,... % [3 10]
    'postDurInSec',.1);
A.run(8)

%% Sweep with the LED over the eye. see what the fly does
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',4);
A.run(10)
% A.clearTags

