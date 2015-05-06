%% Imaging Ca in the terminals of B1 cells, sensory stimulation

% 1) Beginning of the day: start acquisition here in order to have a file
% to save images to.

toggleImagingPref('on')

% Start the bitch 
clear all, close all
A = Acquisition;

% A.setProtocol('PiezoLongCourtshipSong','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'displacements',[3],...
%     'postDurInSec',2);
% A.protocol.CalibrateStimulus(A)

% toggleImagingPref('off')
% A.setProtocol('PiezoChirp','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'preDurInSec',6,...
%     'freqStart',400,...
%     'freqEnd',40,...
%     'displacements',[1] *.667,...
%     'postDurInSec',4);
% A.protocol.CalibrateStimulus(A)
% 

%% PiezoSteps  - diagnostics

A.setProtocol('PiezoStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'displacements',[-3],...
    'preDurInSec',1,...
    'stimDurInSec',1,...
    'postDurInSec',.5);
A.tag('diagnostic')
A.run(1)
systemsound('Notify');
A.clearTags


%% Take a quick sweep early just to see base line at the ROI 
A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.run(2)
systemsound('Notify');


%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',6,...
    'freqStart',40,...
    'freqEnd',400,...
    'displacements',[1] *.667,...
    'postDurInSec',4);
A.tag
A.run(10)
systemsound('Notify');
A.clearTags 


%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',6,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[1] *.667,...
    'postDurInSec',4);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',6,...
    'freqStart',400,...
    'freqEnd',40,...
    'displacements',[1] *.667,...
    'postDurInSec',4);
A.tag
A.run(10)
systemsound('Notify');
A.clearTags 

%% Long Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'displacements',2,...
    'preDurInSec',8,...
    'postDurInSec',2);
A.tag
A.run(10)
systemsound('Notify');
A.clearTags 

%% pulses
A.setProtocol('PiezoStimulus');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'stimulusName','PulseSongRepeat',...
    'displacements',[-3 0 3]*.667,...
    'preDurInSec',6,...
    'postDurInSec',4);
A.tag
A.run(4)
systemsound('Notify');
A.clearTags 
