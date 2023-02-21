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
C.rig.setParams('interTrialInterval',2);
C.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.06,...%'steps',[-.25 .25 .5 1]* 100,... % [3 10]
    'postDurInSec',4.5);
%C.protocol.setParams('sampratein', 10000,'samprateout',10000)
C.run(10)

%% Piezo Ramp step

% C.setProtocol('TriggeredPiezoRampControl');
% C.rig.setParams('interTrialInterval',2);
% C.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'stimDurInSec',.3,...%'steps',[-.25 .25 .5 1]* 100,... % [3 10]
%     'postDurInSec',4.26);
% %C.protocol.setParams('sampratein', 10000,'samprateout',10000)
% C.run(10)


%% turn on the LED for testing
A.rig.devices.epi.override

%% turn off the LED for testing
C.rig.devices.epi.abort

