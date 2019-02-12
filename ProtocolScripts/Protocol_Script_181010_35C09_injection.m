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
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','50');

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.run(5)


%% Switch to current clamp:

%% Sweep2T
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(5)



%%
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all

clear A,    
A = Acquisition;

%% Use the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue')
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','50');


%% Current Step 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.5,...
    'steps',[-1 -.5 -.25   .25 .5, 1]* 50,... % [3 10]
    'postDurInSec',1.5);
A.run(1)

%%
A.run(10)

%% EpiFlash2T % What happens when the fly is jamming on the bar?
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'ndfs',1,...
    'stimDurInSec',2,...
    'postDurInSec',2.8);
% A.tag

A.run(3)%(60)
% do 60 or so repeats!
% A.clearTags

%% EpiFlashTrain % what about when the bar is gone
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2TTrain');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...
    'nrepeats',5,...
    'flashDurInSec',.1,...
    'cycleDurInSec',.4,...
    'postDurInSec',2);
% A.tag
A.run(2)
% A.clearTags


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
A.run(5)
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
A.run(7)
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

%% Piezo2T ramp negative
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',10,...
    'speeds',50*[6 3 2 1],...
    'displacements',[-10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(7)
% A.clearTags

%% Piezo2T ramp 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('PiezoRamp2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacementOffset',0,...
    'speeds',50*[6 3 2 1],...
    'displacements',[10],...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
% A.tag
A.run(7)
% A.clearTags

%% Now see if the bar moves differently at each position

%% Current Step 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.5,...
    'steps',[-1 -.5 -.25   .25 .5, 1]* 50,... % [3 10]
    'postDurInSec',1.5);
A.run(5)

%% Play around

%% Use manipulator to boing boing and record video and sensory

% M285 motor program
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

x = -1; % outof (+)/ into (-) board (x)
y = 0; % left(+)/right(-) (y)
A.setProtocol('ManipulatorMove2T');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'stimDurInSec',2,...
    'pause',1,...
    'velocity',5000,...
    'coordinate',{[200, 0, 0]},...
    'return',0,...
    'postDurInSec',2);
A.run
%A.rig.devices.camera.live
