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

% %% PiezoChirp - Attempt to stimulate
% A.setProtocol('PiezoChirp');
% A.protocol.setParams('-q',...
%     'freqStart',800,...
%     'freqEnd',17,...
%     'displacements',[0.2],'postDurInSec',1);
% A.run(3)
% systemsound('Notify');

% %% Calibration settings
% A.setProtocol('PiezoChirp','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'freqStart',800,...
%     'freqEnd',17,...
%     'displacements',[3 10 30] *.05,...
%     'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)
% 
% A.setProtocol('PiezoChirp','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'freqStart',17,...
%     'freqEnd',800,...
%     'displacements',[3 10 30] *.05,...
%     'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)
% 
% A.setProtocol('PiezoSine','modusOperandi','Cal');
% freqs = 25 * sqrt(2) .^ (-1:10); 
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'freqs',freqs,...
%     'displacements',[3 10 30] * .05,'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)
% 
% A.setProtocol('PiezoCourtshipSong','modusOperandi','Cal');
% A.protocol.setParams('-q','displacements',[3 10 30]*.05,'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)
% 
% A.setProtocol('PiezoBWCourtshipSong','modusOperandi','Cal');
% A.protocol.setParams('-q','displacements',[3 10 30]*.05,'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)



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


%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-40 -30 -20 -10 0 10 20 30 40]);          % tune this 
A.tag
A.run(2)
A.untag
systemsound('Notify');

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',300,...
    'amps',[3 10 30]*.8,... % [10 40]
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');
A.untag


%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.tag
A.run(5)
systemsound('Notify');
A.untag

%% PiezoStimulus

A.setProtocol('PiezoStimulus');
A.protocol.showCalibratedStimulusNames
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimulusName','Basic',...
    'postDurInSec',.5,...
    'displacements',[3 10 30] * .1);
%A.tag
A.run(1)
systemsound('Notify');
%A.untag


%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (-1:10); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[3 10 30] * .05,'postDurInSec',1);
A.tag
A.run(3)
systemsound('Notify');
A.untag

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[3 10 30]*.05,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[3 10 30]*.05,'postDurInSec',1);
A.run(3)
systemsound('Notify');


%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[3 10 30] *.05,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[3 10 30] *.05,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


%% %%%%%%% MANIPULATIONS
% Hyperpolarize the cell
A.tag('Hyperpolarized')

% TTX to try to eliminate spiking
A.tag('TTX 1uM')

% 4AP
A.tag('4AP 5mM')

% TTX and 4AP
A.tag('TTX 1uM','4AP 5mM')

% Curare
A.tag('Curare 5uM')

% MLA
A.tag('MLA 1uM')

% Vclamp
A.tag('VClamp')

% Wash
A.tag('Wash')

% Cobalt
A.tag('Cobalt 5mM')

% Move probe
A.tag('Probe unattached')

A.untag
%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-40 -30 -20 -10 0 10 20 30 40]);          % tune this 
A.tag
A.run(2)
systemsound('Notify');

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',300,...
    'amps',[3 10 30]*.8,... % [10 40]
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');


%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-10 -5 5 10 20]);          % tune this
A.tag
A.run(5)
systemsound('Notify');

%% PiezoSteps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.tag
A.run(6)
systemsound('Notify');

%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[3 10 30] *.05,...
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');


%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[3 10 30] *.05,...
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');


%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
systemsound('Notify');


%% Play time

%% PiezoSine VClamp adaptation protocol
A.setProtocol('PiezoSine');
freqs = 25 * 2 .^ (0:5); 
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'displacements',[0.1 0.4],...
    'stimDurInSec',.3,...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');


%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Then run TTX to try to eliminate spiking
A.tag('Curare 5uM')

