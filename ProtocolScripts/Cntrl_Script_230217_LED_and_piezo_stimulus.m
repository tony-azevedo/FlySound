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

%% LED Step 
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

C.rig.applyDefaults;

C.setProtocol('LEDArduinoFlashControl');
C.protocol.setParams('sampratein', 50000,'samprateout',50000)
C.rig.setParams('interTrialInterval',2);
C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.06,...%'steps',[-.25 .25 .5 1]* 100,... % [3 10]
    'postDurInSec',4.5);
C.run(10)

%% Piezo Ramp step

C.setProtocol('TriggerPiezoRampControl');
% C.protocol.setParams('sampratein', 10000,'samprateout',10000)
C.rig.setParams('interTrialInterval',2);
C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'displacements',[-5,-2.5,2.5,5],...
    'stimDurInSec',0,...%'steps',[-.25 .25 .5 1]* 100,... % [3 10]
    'postDurInSec',4.5,...
    'cueStimDurInSec',0.3,...
    'cueRampDurInSec',0.06);
C.rig.devices.triggeredpiezo.plotStimulus()
%C.protocol.setParams('sampratein', 10000,'samprateout',10000)
C.run(3)


%% turn on the LED for testing
C.rig.devices.epi.override

%% turn off the LED for testing
C.rig.devices.epi.abort

