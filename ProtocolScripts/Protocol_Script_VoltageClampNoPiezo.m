%% Whole cell voltage clamp, with QX-314 and Cs internal, internal made on 4/18
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, %close all
A = Acquisition;


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
A.run(4)
A.clearTags

% Then hyperpolorize -60, -80, -20 0
% Then into voltage clamp -60 -80 -20 0

%% Just to compare to ArcLight Recordings
% switch to current clamp
A.setProtocol('VoltagePlateau');
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'stimDurInSec',0.02,...
    'plateaux',[-10 0 -20 0 -30 0 -40 0 -50 0 10 0 20 0 30],...
    'randomize',0);
A.run(3)

%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-40 -30 -20 -10 -5  5 10 20 30 40]);          % tune this 
A.tag
A.run(3)

%% Voltage Steps - Hyperpolarize to -80

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-20 -10 -5  5 10 20 30 40]);          % tune this 
A.tag
A.run(3)


% %% PiezoSteps
% 
% A.setProtocol('PiezoStep');
% A.protocol.setParams('-q',...
%     'preDurInSec',.2,...
%     'displacements',[-1 -.3 -.1 .1 .3 1],...
%     'stimDurInSec',0.2000,...
%     'postDurInSec',.2);
% % A.tag
% A.run(6)
% % A.clearTags
% 
% %% PiezoSteps hyperpolarize
% % set to -80, -60
% A.setProtocol('PiezoStep');
% A.protocol.setParams('-q',...
%     'preDurInSec',.2,...
%     'displacements',[-1 -.3 -.1 .1 .3 1],...
%     'stimDurInSec',0.2000,...
%     'postDurInSec',.2);
% % A.tag
% A.run(4)
% % A.clearTags
% 
% %% PiezoSine
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
% 
% %% PiezoSine - Hyperpolarized to -80, or -60
% 
% A.setProtocol('PiezoSine');
% freqs = 25 * sqrt(2) .^ [2 (4:6) 8]; 
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'freqs',freqs,...
%     'postDurInSec',.5,...
%     'displacements',[1 10] * .2,'postDurInSec',1);
% A.tag
% A.run(3)
% 
% %% PiezoSine Full set of currents, go back to 0 currents
% A.setProtocol('PiezoSine');
% freqs = 25 * sqrt(2) .^ (-1:10); 
% A.protocol.setParams('-q',...
%     'preDurInSec',.5,...
%     'freqs',freqs,...
%     'postDurInSec',.5,...
%     'displacements',[1 sqrt(10) 10] * .2,'postDurInSec',1);
% A.clearTags
% A.tag
% A.run(3)
% 

%% Then Apply TTX, this will tell whether there are currents that QX may not be preventing

