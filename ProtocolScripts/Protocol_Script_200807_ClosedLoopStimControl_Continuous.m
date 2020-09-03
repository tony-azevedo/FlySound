%% Testing and developing code;
% Goals: 
% 1) Use the same routines currently used to also record probe position.
% 2) Set up a continuous protocol
% 3) Record video frames every now and then. Can do this in pylonviewer
% instead
% 4) Improve the system for R2020
% 5) make rig name not constant

setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

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
A.rig.devices.epi.setParams('controlToggle',1)
A.protocol.setParams('ttlval',true);

%%
A.run

%% 
A.rig.stop  

%% 
A.comment

%% turn on the LED for testing
A.rig.devices.epi.override

%% turn off the LED for testing
A.rig.devices.epi.abort


%% FBCntrlEpiFlash2T - 
A.rig.applyDefaults;

A.setProtocol('FBCntrlEpiFlash2T');

%% FBCntrlEpiFlash2T - Fly IS in control

A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',1,...  
    'stimDurInSec',4,...
    'postDurInSec',.5);

A.rig.devices.epi.setParams('controlToggle',1)
A.rig.setParams('interTrialInterval',0);

A.clearTags
A.tag('must extend')
% A.tag('x 890, w 40, t 24')
A.tag('x 890, w 40, t 27')
%A.comment
A.run(1)

% Not in control: probe trial
A.rig.devices.epi.setParams('controlToggle',0)
A.clearTags
A.tag('out of control')
%A.comment
A.run(1)

% A.rig.devices.epi.setParams('controlToggle',0)
% 
% % No light. Rest trials
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'ndfs',0,...  
%     'stimDurInSec',4,...
%     'postDurInSec',.5);
% 
% A.clearTags
% A.tag('rest')
% %A.comment
% A.run(5)

