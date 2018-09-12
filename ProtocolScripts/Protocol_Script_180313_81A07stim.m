setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all

clear A,    
A = Acquisition;
st = getacqpref('MC700AGUIstatus','status');
setacqpref('MC700AGUIstatus','mode','VClamp');
setacqpref('MC700AGUIstatus','VClamp_gain','50');
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
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','50');

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);

A.run(5)


%% Switch to current clamp, single electrode:

%% Sweep2T
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

A.rig.setParams('testvoltagestepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(5)


%% Current Step 
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'steps',[.5,.75, 1]* 200,... % [3 10]
    'postDurInSec',.1);
A.run(2)


%%
setacqpref('AcquisitionHardware','cameraBaslerToggle','off')

% Start the bitch 
% clear all, close all

clear A,    
A = Acquisition;

%% Use the bath LED, not the Epis
setacqpref('AcquisitionHardware','LightStimulus','LED_Bath')
setacqpref('MC700AGUIstatus','mode','IClamp');
setacqpref('MC700AGUIstatus','IClamp_gain','50');

%% EpiFlash2T 
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[0.8, .85, .9, 1]*.037,...
    'stimDurInSec',0.020,...
    'postDurInSec',1);
% A.tag
% A.clearTags
A.run

%%
A.run(20)
% do 60 or so repeats!

%% EpiFlash2T higher intensities
setacqpref('AcquisitionHardware','cameraBaslerToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');

A.rig.setParams('testvoltagestepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'ndfs',[1.5 2 4]*.15,...
    'stimDurInSec',0.020,...
    'postDurInSec',1);
% A.tag
% A.clearTags
A.run

%%
A.run(9)
% do 60 or so repeats!

%% Replace bar with rigid electrode, 

% repeat

%% Playing around, try flicking the soft probe with patch pipette

% see if a big unit appears on the EMG
