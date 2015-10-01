%% Voltage Commands to isolate currents

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;

%%
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',0); A.run(1)

%% Sweep - record the break-in

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',25);
A.tag('break-in')
A.run(1)
A.clearTags


%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(2)
A.clearTags

%% Switch to current clamp

%% Sweep

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(2)

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',300,...
    'amps',[3 10]*1,... % [10 40]
    'postDurInSec',2);
A.run(3)

%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-120 -100 -80 -60 -40 -20 -10 10 20 40]);          % tune this (-10:2:10))%
A.run(1)

%% Current injection characterization: looking for spikes

plateaux = [-50 -80 -140 -180 -180 -163 -140 0];
%plateaux = [-50 -80 -100 -100 -100 -79 -100 0];

A.setProtocol('CurrentPlateau');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'plateauDurInSec',.5,...
    'plateaux',plateaux,...
    'randomize',0);
A.tag
A.run(1)
systemsound('Notify');


%% Switch to voltage clamp

%% Which type of neuron?
celltype = 'BPL';
celltype = 'BPH';

% What size?
foldX = 1;
foldX = 3;

%% SineResponses
A.rig.applyDefaults;

srnames = dir(['C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\SineResponse_' celltype '_*' num2str(foldX) 'X*']);
A.setProtocol('VoltageCommand');
for srn = 1:length(srnames)
    A.protocol.setParams('-q',...
        'stimulusName',srnames(srn).name(1:end-4));
    A.run(8)
end


%% Sweep different holding potentials
A.setProtocol('Sweep');
A.rig.setParams('testvoltagestepamp',0)
% Condition1 = 'perfusion off';
% Condition1 = 'perfusion on';
% Condition2 = 'probe off'
% Condition2 = 'probe on'
% Condition3 = 'feedback off'
% Condition3 = 'feedback on'

A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',20); A.tag('20',Condition1,Condition2,Condition3); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',-20); A.tag('-20',Condition1,Condition2,Condition3); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',-40); A.tag('-40',Condition1,Condition2,Condition3); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',-50); A.tag('-50',Condition1,Condition2,Condition3); A.run(1)
A.protocol.setParams('-q','durSweep',5); A.run(2);
A.clearTags

A.protocol.setParams('-q','durSweep',0.1,'holdingPotential',0); A.run(1)


%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-80 -60 -40 -20 -10 -5  5 10 20 40]);          % tune this 
A.tag
A.run(2)

%%
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'stimulusName','VoltageRamp_m100_p20');
A.run(5)
systemsound('Notify');

%% Start over with other drugs.

A.tag

%% PiezoChirp - up

A.setProtocol('PiezoChirp');
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',0,...
    'freqEnd',400,...
    'displacements',[1  10] * .05,...
    'postDurInSec',2);
A.run(3)
systemsound('Notify');

%% Switch to voltage clamp

%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
% A.tag
A.run(4)
systemsound('Notify');
% A.clearTags

%% PiezoSine

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (1:1:8); 
freqs = 25 * sqrt(2) .^ (-1:1:9); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 3 10] * .05,'postDurInSec',1);
A.clearTags
%A.tag('Cd')
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
A.run(3)
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


%% PiezoSteps

A.setProtocol('PiezoStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[-1 -.3 -.1 .1 .3 1],...
    'stimDurInSec',0.2000,...
    'postDurInSec',.2);
% A.tag
A.run(4)
systemsound('Notify');
% A.clearTags

%% PiezoSine

A.setProtocol('PiezoSine');
%freqs = 25 * sqrt(2) .^ (1:1:8); 
freqs = sort([.3 1 3]); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 3 10] * .05,'postDurInSec',1);
A.clearTags
%A.tag('Cd')
A.run(3)
systemsound('Notify');

% A.setProtocol('PiezoSine','modusOperandi','Cal');
% freqs = sort([.3 1 3]); 
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'stimDurInSec',.3,...
%     'freqs',164,...
%     'postDurInSec',.5,...
%     'displacements',[1 3 10] * .05,'postDurInSec',1);
% A.protocol.CalibrateStimulus(A)

%% PiezoSine

A.setProtocol('PiezoSine');
%freqs = 25 * sqrt(2) .^ (1:1:8); 
freqs = sort([10 25 * sqrt(2) .^ (-1:1:7) 164]); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 3 10] * .05,'postDurInSec',1);
A.run(1)
A.clearTags

%% Create Voltage Waveforms that replicate the responses to PiezoSine
% Nah, not yet