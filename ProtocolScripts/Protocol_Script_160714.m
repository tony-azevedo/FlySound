%% Whole cell voltage clamp, Cs internal, para,

setacqpref('AcquisitionHardware','PGRCameraToggle','on')
setacqpref('AcquisitionHardware','PGRCameraToggle','off')
getacqpref('AcquisitionHardware','PGRCameraToggle')

% Start the bitch 
% clear all, close all
clear A
A = Acquisition;
%


% Seal
A.setProtocol('CurrentStep');
A.run(1);


%% EpiFlash
setacqpref('AcquisitionHardware','PGRCameraToggle','off')

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',1,...
    'postDurInSec',4);
A.run(3)

%% Sweep
setacqpref('AcquisitionHardware','PGRCameraToggle','on')

A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.run(3)
