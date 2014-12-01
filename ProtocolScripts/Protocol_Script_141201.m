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
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',800,...
    'displacements',[3 10 30] *.0667,...
    'postDurInSec',4);
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
    'displacements',[3 10 30] *.0667,...
    'postDurInSec',4);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

%% PiezoChirp - narrow

A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',40,...
    'freqEnd',280,...
    'displacements',[10] *.1,...
    'postDurInSec',4);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags 

%% PiezoChirp - narrowest

A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',80,...
    'freqEnd',180,...
    'displacements',[10] *.1,...
    'postDurInSec',4);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags 

%% PiezoChirp - down narrow

A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',280,...
    'freqEnd',40,...
    'displacements',[10] *.1,...
    'postDurInSec',4);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags 

%% PiezoChirp - down narrowest

A.setProtocol('PiezoChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',180,...
    'freqEnd',80,...
    'displacements',[10] *.1,...
    'postDurInSec',4);
A.tag
A.run(5)
systemsound('Notify');
A.clearTags 

%% PiezoSine

A.setProtocol('PiezoSine');
A.rig.setParams('interTrialInterval',1);
%freqs = 25 * sqrt(2) .^ (-1:10); 
freqs = [25 80 120 160 200 240 280]; 
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'stimDurInSec',3,...
    'freqs',freqs,...
    'postDurInSec',4,...
    'displacements',[3 30] * .07);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

%% Long Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'displacements',2,...
    'preDurInSec',2.5,...
    'postDurInSec',2);
A.tag
A.run(6)
systemsound('Notify');
A.clearTags 

%% pulses
A.setProtocol('PiezoStimulus');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'stimulusName','PulseSongRepeat',...
    'displacements',[-3  3]*.667,...
    'preDurInSec',2.5,...
    'postDurInSec',2);
A.tag
A.run(4)
systemsound('Notify');
A.clearTags 

%% Vaughan song

A.setProtocol('PiezoStimulus');
A.protocol.setParams('-q',...
    'stimulusName','VaughanSong_20',...
    'displacements',1.5,...
    'preDurInSec',2.5,...
    'postDurInSec',2);
A.tag
A.run(3)
systemsound('Notify');
A.clearTags 

