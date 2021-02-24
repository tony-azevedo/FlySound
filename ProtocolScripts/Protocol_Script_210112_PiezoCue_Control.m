%% Testing and developing code;
% Goals: 
% 1) Use the same routines currently used to also record probe position.
% 2) Set up a continuous protocol
% 3) Record video frames every now and then. Can do this in pylonviewer
% instead
% 4) Improve the system for R2020
% 5) make rig name not constant

clear C,    
C = Control;

%% ContinuousFB2T - run continuously
% setup the acquisition side first

%% LEDArduinoFlash_Control - 
C.rig.applyDefaults;
C.setProtocol('LEDArduinoFlashControl');
C.rig.devices.epi.abort

%% FBCntrlEpiFlash2T - FlyIS in control

C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
C.rig.setParams('scheduletimeout',0,'timeoutinterval',30,'waitForLED', 1);

C.clearTags
C.tag('flex') % flex extend
C.run(45)

% *** Not in control: probe trial ***
% C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',0)
% C.clearTags
% C.tag('out of control')
% C.run(1)

% Rest trials
C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
C.rig.setParams('scheduletimeout',0,'timeoutinterval',30,'turnoffLED', 1);
C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',0,...  
    'stimDurInSec',3,...
    'postDurInSec',.2);
C.clearTags
C.tag('rest')
C.run(5)

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

