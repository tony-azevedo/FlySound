setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all
clear A, 
A = Acquisition;
%

%% Sweep - record the break-in

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.run(2)
%A.clearTags
