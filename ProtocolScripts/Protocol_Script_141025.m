%% Imaging Ca in the terminals of B1 cells, sensory stimulation

% 1) Beginning of the day: start acquisition here in order to have a file
% to save images to.

toggleImagingPref('off')

% Start the bitch 
clear all, close all
A = Acquisition;

A.setProtocol('PiezoLongCourtshipSong','modusOperandi','Cal');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'displacements',[1 3],...
    'postDurInSec',2);
A.protocol.CalibrateStimulus(A)


%% Take a quick sweep early just to see base line at the ROI 
A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.run(2)
systemsound('Notify');

%% PiezoChirp - diagnostics
A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[20] *.05,...
    'postDurInSec',2);
A.tag
A.run(6)
systemsound('Notify');
A.clearTags 

%% PiezoSteps  - diagnostics

A.setProtocol('PiezoStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'displacements',[-1],...
    'preDurInSec',1,...
    'stimDurInSec',.5,...
    'postDurInSec',.5);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags


%% PiezoSteps

A.setProtocol('PiezoStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'displacements',[-3 -1 -.3 .3 1 3],...
    'preDurInSec',2,...
    'stimDurInSec',2,...
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

%% PiezoSine

A.setProtocol('PiezoSine');
A.rig.setParams('interTrialInterval',1);
freqs = 25 * sqrt(2) .^ (-1:10); 
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'stimDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',4,...
    'displacements',[3 10 30] * .07);
A.tag
A.run(2)
systemsound('Notify');
A.clearTags 

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'displacements',[3 10 30]*.08,...
    'preDurInSec',2.5,...
    'postDurInSec',4);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2.5,...
    'displacements',[3 10 30]*.08,...
    'postDurInSec',4);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 


%% PiezoChirp - up
A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[3 10 30] *.05,...
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 


%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',800,...
    'freqEnd',17,...
    'displacements',[3 10 30] *.05,...
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 
