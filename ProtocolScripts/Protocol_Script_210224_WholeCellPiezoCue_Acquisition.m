%% Testing and developing code;
% Goals: 
% 4) Improve the system for R2020
% 5) Documentation, publish

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

%% Switch to current clamp, single electrode:

%% Sweep
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','100');

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.run(5)

%% Current Step 
A.rig.applyDefaults;

A.setProtocol('CurrentStepForceProbe2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',.5,...
    'steps',[-.25 .25 .5 1]* 200,... % [3 10]
    'postDurInSec',1.5);
% A.run(1)

%%
A.run(3)


%% ContinuousFB2T - run continuously
A.setProtocol('AcquireWithEpiFeedback');
%A.rig.devices.epi.setParams('controlToggle',1) %This output no longer
%controls the Arduino
A.protocol.setParams('ttlval',true); % This no longer controls the led either

%%
A.run 

%% 
A.comment

%% 
% A.rig.stop  


