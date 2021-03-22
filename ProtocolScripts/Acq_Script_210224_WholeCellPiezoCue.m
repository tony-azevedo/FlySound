%% Testing and developing code;
% Goals: 
% 4) Improve the system for R2020
% 5) Documentation, publish

clear A,    
A = Acquisition;

st = getacqpref('MC700AGUIstatus','status');
% setacqpref('MC700AGUIstatus','mode','VClamp');
% setacqpref('MC700AGUIstatus','VClamp_gain','20');
if ~st
    MultiClamp700AGUI;
end

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


