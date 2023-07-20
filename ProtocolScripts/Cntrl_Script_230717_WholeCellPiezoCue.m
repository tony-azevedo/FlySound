%% Testing and developing code;
% Goals: 
% 1) Improve the system for R2020
% 2) Write documentation, publish


clear C, 
C = Control;

st = getacqpref('MC700AGUIstatus','status');
% setacqpref('MC700AGUIstatus','mode','VClamp');
% setacqpref('MC700AGUIstatus','VClamp_gain','20');
if ~st
    MultiClamp700AGUI;
end

%% ContinuousFB2T - run continuously
% setup the acquisition side first

%% Seal
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','20');

C.setProtocol('SealAndLeakControl');
C.tag('R_input')
C.run
C.untag('R_input')

%% Switch to current clamp, single electrode:
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

%% Current Step 
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

C.rig.applyDefaults;

C.setProtocol('CurrentStepControl');
C.rig.setParams('interTrialInterval',0);
C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.5,...
    'steps',[-.25 .25 .5 1]* 200,... % [3 10]
    'postDurInSec',1.5);
C.run(3)


%% LEDArduinoFlash_Control - 
C.rig.applyDefaults;
C.setProtocol('LEDFlashWithPiezoCueControl');
C.rig.devices.epi.abort

%% FBCntrlEpiFlash2T - Fly IS in control

C.protocol.setParams('-q',...
    'preDurInSec',1,...
    'cueDelayDurInSec',.5,...
    'cueStimDurInSec',.3,...
    'cueRampDurInSec',.07,...
    'background',5,...
    'displacements',[-5, -2.5, 2.5, 5],...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);
C.protocol.randomize();

C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1,'blueToggle',0)
C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1,'blueToggle',1)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
C.rig.setParams('waitForLED', 1,'LEDTimeout',10,'blueOnCount',3,'blueOffCount',3,'enforcedRestCount',6);
C.rig.setParams('waitForLED', 1,'LEDTimeout',10,'blueOnCount',3,'blueOffCount',3,'enforcedRestCount',6);

C.clearTags
C.tag('flex') % flex extend
C.run(2)

% *** Not in control: probe trial ***
% C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',0)
% C.clearTags
% C.tag('out of control')
% C.run(1)

% Rest trials
C.rig.devices.epi.setParams('routineToggle',0,'controlToggle',1,'blueToggle',0)
C.rig.setParams('interTrialInterval',2,'iTIInterval',2);
% C.rig.setParams('waitForLED', 1,'LEDTimeout',10,'blueOnCount',3,'blueOffCount',3,'enforcedRestCount',6);
C.protocol.setParams('-q',...
    'preDurInSec',1,...
    'cueDelayDurInSec',.5,...
    'cueStimDurInSec',.3,...
    'cueRampDurInSec',.07,...cledd
    'background',5,...
    'displacements',[0],...
    'ndfs',0,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);
C.protocol.randomize();
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

