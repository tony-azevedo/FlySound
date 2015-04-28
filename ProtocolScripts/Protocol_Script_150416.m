%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

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
A.tag
A.run(4)
systemsound('Notify');
A.clearTags

%% Voltage Steps 

A.setProtocol('VoltageStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-40 -30 -20 -10 -5  5 10 20 30 40]);          % tune this 
A.tag
A.run(3)
systemsound('Notify');

%% Voltage Steps - Hyperpolarize to -80

A.setProtocol('VoltageStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-20 -10 -5  5 10 20 30 40]);          % tune this 
A.tag
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
A.run(6)
systemsound('Notify');
% A.clearTags

%% PiezoSteps hyperpolarize
% set to -80, -60
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
freqs = 25 * sqrt(2) .^ (-1:10); 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 sqrt(10) 10] * .2,'postDurInSec',1);
%A.clearTags
%A.tag('Cd')
A.run(3)
systemsound('Notify');
% 
% A.setProtocol('PiezoSine');
% freqs = 25 * sqrt(2) .^ [2 (4:6) 8]; 
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'freqs',freqs,...
%     'postDurInSec',.5,...
%     'displacements',[1 10] * .2,'postDurInSec',1);
% A.clearTags
% %A.tag('Cd')
% A.run(3)
% systemsound('Notify');
% 

%% PiezoSine - Hyperpolarized to -80, or -60

% A.setProtocol('PiezoSine');
% freqs = 25 * sqrt(2) .^ (-1:10); 
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'freqs',freqs,...
%     'postDurInSec',.5,...
%     'displacements',[3 10 30] * .05,'postDurInSec',1);
% A.clearTags
% %A.tag('Cd')
% A.run(3)
% systemsound('Notify');

A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ [2 (4:6) 8]; 
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqs',freqs,...
    'postDurInSec',.5,...
    'displacements',[1 10] * .2,'postDurInSec',1);
A.clearTags
%A.tag('Cd')
A.run(3)
systemsound('Notify');

%% Then Apply TTX, this will tell whether there are currents that QX not be preventing

