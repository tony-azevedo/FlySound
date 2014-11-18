%% Whole cell voltage clamp, trying to patch using the hamamatsu
% Trying to:
%   up the N on the frequency selectivity
%   fill cells and image, connect physiology to morphology
%   explore the main 4 lines plus the 45D07
%   apply TTX/4AP and any other drugs that may be helpful.
%   develop a cut Antennal Nerve prep, a naked brain without ipsilateral
%       input
%   deliver song stimulus and noise stimuli
setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;


%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Sweep

A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.run(2)
systemsound('Notify');

%% Sweep

A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'stimulusName','NonInvasiveVmRamp');
A.run(2)
systemsound('Notify');
