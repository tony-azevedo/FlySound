%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

setpref('AcquisitionHardware','cameraToggle','on')

% Start the bitch 
clear all, close all
A = Acquisition;

%% Turn on Piezo

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
% A.tag
A.run(1)
systemsound('Notify');
% A.clearTags

%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'displacements',[-3  3],...
    'stimDurInSec',2,...
    'postDurInSec',1);
% A.tag
A.run(4)
systemsound('Notify');
% A.clearTags

%% PiezoSine

A.setProtocol('PiezoSine');
freqs = [1 10 25 * sqrt(2) .^ (-1:1:8)]; 
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',1,...
    'freqs',freqs,...
    'postDurInSec',1,...
    'displacements',[1 3 10] * .05,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',400,...
    'displacements',[1  10] * .05,...
    'postDurInSec',2);
A.run(2)
systemsound('Notify');


%% PiezoChirp - down

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',400,...
    'freqEnd',0,...
    'displacements',[1 10] *.1,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

% %% 
% A.setProtocol('PiezoChirp','modusOperandi','Cal');
% A.protocol.setParams('-q',...
%     'preDurInSec',2,...
%     'freqStart',400,...
%     'freqEnd',0,...
%     'displacements',[1 10] *.1,...
%     'postDurInSec',2);
% A.protocol.CalibrateStimulus(A)

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
A.run(6)
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
A.run(6)
systemsound('Notify');

%% Long Courtship song
A.setProtocol('PiezoLongCourtshipSong');
A.protocol.setParams('-q','displacements',[-30 -3 3 30]*.0667,'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Pulses
A.setProtocol('PiezoStimulus');
A.protocol.setParams('-q',...
    'stimulusName','PulseSongRepeat',...
    'preDurInSec',2,...
    'displacements',[-2 -.6325 -.2 .2 .6325 2],...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');


