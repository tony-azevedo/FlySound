% Protocol_Script_Scratch

setpref('AcquisitionHardware','cameraToggle','off')
clear A, 
A = Acquisition;


%%
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',.5);
A.run(1)

%%
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',.5);
A.run(1)

%%
setpref('AcquisitionHardware','cameraToggle','on')
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',8);
A.run(2)

%%
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.devices.camera.setParams('framerate',100);
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',8,...
    'postDurInSec',1);
A.tag
A.run(5)
A.clearTags

%% Current Step 
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.1,...
    'steps',[100],... % [3 10]
    'postDurInSec',.1);
A.run(4)
