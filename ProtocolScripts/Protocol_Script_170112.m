setpref('AcquisitionHardware','PGRCameraToggle','off')
setpref('AcquisitionHardware','PGRCameraLocation','PGRCameraObjective')

% Start the bitch 
% clear all, close all
clear A, 
A = Acquisition;
%


%% EpiFlash 2 5 10
% setpref('AcquisitionHardware','PGRCameraToggle','on') % This turns on the point grey camera below the foil
setpref('AcquisitionHardware','LightStimulus','LED_Red')
A = Acquisition;

A.tag('LED_Red')

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',5,...
    'displacements',[10],...
    'stimDurInSec',2,...
    'postDurInSec',10);
A.protocol.randomize(1);
A.run(2)

A.protocol.setParams('-q',...
    'preDurInSec',5,...
    'displacements',[0 2 10],...
    'stimDurInSec',5,...
    'postDurInSec',10);
A.protocol.randomize(1);
A.run(2)

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',5,...
    'displacements',[0 2 10],...
    'stimDurInSec',10,...
    'postDurInSec',10);
A.protocol.randomize(1);
A.run(2)

A.untag('LED_Red')
% A.comment

%% EpiFlash 2 5 10
% setpref('AcquisitionHardware','PGRCameraToggle','on') % This turns on the point grey camera below the foil
setpref('AcquisitionHardware','LightStimulus','Epifluorescence')
A = Acquisition;

A.tag('Epifluorescence')

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',5,...
    'displacements',[0 2 10],...
    'stimDurInSec',2,...
    'postDurInSec',10);
A.protocol.randomize(1);
A.run(2)

A.protocol.setParams('-q',...
    'preDurInSec',5,...
    'displacements',[0 2 10],...
    'stimDurInSec',5,...
    'postDurInSec',10);
A.protocol.randomize(1);
A.run(2)


A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',5,...
    'displacements',[0 2 10],...
    'stimDurInSec',10,...
    'postDurInSec',10);
A.protocol.randomize(1);
A.run(2)

A.untag('Epifluorescence')
A.comment
