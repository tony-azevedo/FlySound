setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all
clear A, 
A = Acquisition;
%

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.tag('requiredData')
A.run(1)
A.clearTags

%% Acquire
A.rig.setParams('testvoltagestepamp',0)
% A.rig.setParams('testcurrentstepamp',0)
setpref('AcquisitionHardware','PGRCameraToggle','off')

A.setProtocol('Acquire');


%%
A.run

%% Acquire

A.rig.stop
%A.comment

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')
