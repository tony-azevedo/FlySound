setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all


clear A,    
A = Acquisition;
st = getacqpref('MC700AGUIstatus','status');
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','20');
if ~st
    MultiClamp700AGUI;
end

%% Use the bath LED, not the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Blue')

%% EpiFlash2T 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('interTrialInterval',2);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,... % 'ndfs',[1 1.25 1.5 1.75 2 2.5]*.05,...    
    'stimDurInSec',4,...
    'postDurInSec',.5);
% A.clearTags
% A.tag
A.run(2)
