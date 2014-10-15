%% Whole cell voltage clamp, imaging Ca in the terminals of B1 cells
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit
% single spikes while hyperpolarized. Filling the cell with Alexa 594 (10uM
% or 50uM) and Fluo5F (150uM or 300uM).  Find the terminal under 2P at 925
% nm illumination, change the wavelength to 800nm, then watch terminals
% fill in the red channel, start imaging the green channel.

% 1) Beginning of the day: start acquisition here in order to have a file
% to save images to.

setpref('AcquisitionHardware','twoPToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;

%% 
% Procedure is:
% Before dropping the electrode in, startup the acquisition and the
% imaging.  
% Zoom the 2P all the way out.  
% Find the cell under normal illumination and with the LED.  
% Image the cell under 2P. at wide zoom
% Adjust the laser wavelength to 800.
%
% Now connect the imaging with the physiology
% Set up the directory
% Paste the images name
% Enter the line number and repeats
% Start the physiology protocol

%% Seal
toggleTwoPPref('off')
A.setProtocol('SealAndLeak');
A.tag('Rinput')
A.run
A.untag('Rinput')

%% Take a quick sweep early after break-in just to see base line at the ROI 
toggleTwoPPref('off')
A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.run(2)
systemsound('Notify');

%% Current injection characterization
toggleTwoPPref('off')

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-40 -30 -20 -10 0 10 20 30 40]);          % tune this 
A.tag
A.run(3)
A.untag
systemsound('Notify');


%% hyperpolarize the cell, injection characterization
toggleTwoPPref('off')

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-5 0 5 10 15 20]);          % tune this 
A.tag
A.run(5)
A.untag
systemsound('Notify');


%% Start trying to measure spikes going above threshold
% switch to current clamp
% toggleTwoPPref('on')
% %plateaux = [repmat(-30,1,5),10,repmat(-30,1,5)];
% plateaux = [0 0 -100 0 0 -50 0 0 -25 0 0 25 0 0 50 0 0 100 0 0];
% % plateaux = [-180 -180 -180 -190 -180 -180 -150 -180 -180 -120 -180 -180 -90 -180 -180 0],'randomize',0);
% % plateaux = [-90 -90 -90 -100 -90 -90 -80 -90 -90 -70 -90 -90 -60 -90 -90 -50 -90 -90 0],'randomize',0);
% 
% A.setProtocol('CurrentPlateau');
% A.rig.setParams('interTrialInterval',1);
% A.protocol.setParams('-q','preDurInSec',1.5,...
%     'postDurInSec',5,'plateauDurInSec',.4,...
%     'plateaux',plateaux,'randomize',0);
% 
% A.tag
% A.run(10)
% A.untag
% systemsound('Notify');
% 

%% look at calcium when doing the steps
toggleTwoPPref('on')

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',1,...
    'postDurInSec',1,...
    'steps',[-40 -20  20 40]);          % tune this 
A.tag
A.run(5)
A.untag
systemsound('Notify');


%% CurrentChirp - up
toggleTwoPPref('on')
A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',300,...
    'amps',[3 10 30],... % [10 40]
    'postDurInSec',2);
A.tag
A.run(2)
A.untag
systemsound('Notify');

%% CurrentChirp - down
A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'freqStart',300,...
    'freqEnd',17,...
    'amps',[3 10 30],... % [10 40]
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

%% Start trying to measure spikes going above threshold

toggleTwoPPref('on')

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',0.02,...
    'postDurInSec',1,...
    'steps',[-5 0 5 10 15 20]);          % tune this 
A.tag
A.run(5)
A.untag
systemsound('Notify');

%% Ramping stimulus
% switch to current clamp
toggleTwoPPref('on')

A.setProtocol('CurrentPlateau');
plateaux = [(-5:-5:-70), repmat(-70,1,10),-60,repmat(-70,1,10)];
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','preDurInSec',1.5,...
    'postDurInSec',1.5,'plateauDurInSec',0.1,'plateaux',plateaux,'randomize',0);
A.tag
A.run(10)
A.untag
systemsound('Notify');


%% CurrentSine
toggleTwoPPref('on')
A.setProtocol('CurrentSine');
A.rig.setParams('interTrialInterval',1);
freqs = 50 * sqrt(2) .^ (0:5); 
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'amps',[10 30 50],...
    'preDurInSec',1,...
    'stimDurInSec',1,...
    'postDurInSec',1);
A.tag
A.run(2)
A.untag
systemsound('Notify');

%% Finally, image the whole cell.
