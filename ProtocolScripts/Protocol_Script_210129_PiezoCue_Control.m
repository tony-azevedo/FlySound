%% Testing and developing code;
% Goals: 
% 1) Improve the system for R2020
% 2) Write documentation, publish

clear C, 
C = Control;

%% ContinuousFB2T - run continuously
% setup the acquisition side first

%% LEDArduinoFlash_Control - 
C.rig.applyDefaults;
C.setProtocol('LEDFlashWithPiezoCueControl');
C.rig.devices.epi.abort

%% FBCntrlEpiFlash2T - FlyIS in control

C.protocol.setParams('-q',...
    'preDurInSec',1,...
    'cueDelayDurInSec',.5,...
    'cueStimDurInSec',.3,...
    'cueStimDurInSec',.07,...
    'displacements',[-10, -3, 3, 10],...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);
C.protocol.randomize();

C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1,'blueToggle',0)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
C.rig.setParams('waitForLED', 1,'LEDTimeout',1,'blueOnCount',3,'blueOffCount',3,'enforcedRestCount',6);

C.clearTags
C.tag('flex') % flex extend
C.run(11)

%% *** Not in control: probe trial ***
% C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',0)
% C.clearTags
% C.tag('out of control')
% C.run(1)

% Rest trials
C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
C.rig.setParams('timeoutinterval',30,'turnoffLED', 1);
C.protocol.setParams('-q',...
    'preDurInSec',1,...
    'cueDelayDurInSec',.3,...
    'cueStimDurInSec',.2,...
    'displacements',0,...
    'ndfs',0,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);
C.clearTags
C.tag('rest')
C.run(6)

% msgbox('Double check the continuous acquisition is running')

%%
C.rig.devices.epi.setParams('routineToggle',1,'controlToggle',1)

%%
C.rig.devices.epi.setParams('controlToggle',0)

%% Play time!

C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

% *** Not in control: probe trial ***
C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',0)
C.clearTags
C.tag('out of control')
C.run(1)


C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
C.rig.setParams('scheduletimeout',0,'timeoutinterval',30,'turnoffLED', 1);

C.clearTags
C.tag('must flex')
C.run(10)



%% turn on the LED for testing
A.rig.devices.epi.override

%% turn off the LED for testing
C.rig.devices.epi.abort

