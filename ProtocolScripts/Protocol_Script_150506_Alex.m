%% Imaging Ca in the terminals of B1 cells, sensory stimulation

% 1) Beginning of the day: start acquisition here in order to have a file
% to save images to.

toggleImagingPref('on')
 
clear all, close all
A = Acquisition;

%% Take a quick sweep early just to see base line at the ROI 
A.setProtocol('SpeakerChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',0,...
    'postDurInSec',1);
A.tag
A.run(1)
systemsound('Notify');
A.clearTags 


%% SpeakerChirp - up
A.setProtocol('SpeakerChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',6,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[1],...
    'postDurInSec',6);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags 

%% SpeakerSine

A.setProtocol('SpeakerSine');
A.rig.setParams('interTrialInterval',1);
%freqs = 25 * sqrt(2) .^ (-1:10); 
freqs = [25 80 120 160 200 240 280]; 
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'stimDurInSec',3,...
    'freqs',freqs,...
    'postDurInSec',4,...
    'displacements',[3 30] * .1);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

%% SpeakerStimulus - pips

A.setProtocol('SpeakerStimulus');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'stimulusName','alexBehaviorPips',...
    'amps',[1],...
    'preDurInSec',4,...
    'ramptime',0,...
    'postDurInSec',4);
A.tag
A.run(10)
systemsound('Notify');
A.clearTags 

