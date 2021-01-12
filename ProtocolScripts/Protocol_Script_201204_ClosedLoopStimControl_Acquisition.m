%% Testing and developing code;
% Goals: 
% 1) Use the same routines currently used to also record probe position.
% 2) Set up a continuous protocol
% 3) Record video frames every now and then. Can do this in pylonviewer
% instead
% 4) Improve the system for R2020
% 5) make rig name not constant

setacqpref('AcquisitionHardware','cameraBaslerToggle','off');

clear A,    
A = Acquisition;

st = getacqpref('MC700AGUIstatus','status');
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','20');
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
A.rig.stop  

%% 
A.comment

