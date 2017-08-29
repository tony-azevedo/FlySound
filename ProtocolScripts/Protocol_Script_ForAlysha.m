%% Protocol script to do the things we've talked about thus far: current steps, light flashes, record video.

setpref('AcquisitionHardware','PGRCameraToggle','off')

% clear all, close all
clear A
A = Acquisition; % Creates an Acquisition Object that handles saving data

% Data is saved in the Acquisition folder under the date, and the Fly
% number, Cell number, according to format: YYMMDD_FX_CX.

% Creating the Acquisition object will ask you to define a fly and cell and
% a genotype. (Don't worry about the amp).

% If you're done with one cell and want to start another, or another fly,
% call this command:
A.setIdentifiers('reset',1)

% This script runs basic protocols. To adjust the protocols, change the
% values in the setParams line.

% To run one of these commands, just right click and hit:
% "Evaluate current section" or Cntrl+Enter

%% Sweep - record the break-in
% When I'm ready to break-into a cell, I just acquire that data.

A.rig.applyDefaults;                            % boiler plate
A.setProtocol('Sweep');                         % sets up a the rig to just acquire data (Sweep)
A.protocol.setParams('-q','durSweep',10);       % run for 10 seconds
A.tag('break-in')                               % just tags epochs to not that
A.run(1)                                        % run this once
A.clearTags


%% Sweep - acquire voltage clamp data

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',4);
A.run(1)


%% Switch to current clamp

%% Sweep
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)

%% Current Step - This should drive spikes. Or not...

A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',.1,...            % 100 ms before the step
    'stimDurInSec',.1,...           % 100 ms step
    'steps',1*[-2 5 10 15 20],...   % size of the step
    'postDurInSec',.1);             % 100 ms after the step
A.run(3)                            % loop through all the steps 3 times

%% EpiFlash - This protocol just flashes the epi fluorescent light.
% The TLED from sutter has to be in TTL mode

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...        % 10 V command signal, blast the light
    'stimDurInSec',.1,...           % 100 ms stimulus
    'postDurInSec',6);
A.run(3)

%% EpiFlash - This protocol just flashes the epi fluorescent light.
% The TLED from sutter has to be in TTL mode

setpref('AcquisitionHardware','PGRCameraToggle','off') % This turns on the point grey camera below the foil

A.setProtocol('EpiFlash');
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...        % 10 V command signal, blast the light
    'stimDurInSec',.1,...           % 100 ms stimulus
    'postDurInSec',6);
A.run(3)
% This will bring up a preview window of the video stream and let you adjust the light levels. 
% The preview will wait for you to press a button before the protocol runs.
% Once the camera toggle is on, the camera will run for all of the
% subsequent commands.
% To turn the camera off, call the following command:
% setpref('AcquisitionHardware','PGRCameraToggle','off') % This turns off the point grey camera below the foil


%% Voltage steps
% for this protocol to run, the amp has to be in voltage clamp.

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'steps',[-10 0 10 20 30],...
    'stimDurInSec',.2,...
    'postDurInSec',.2);
A.run(3)

%% Plateau - this protocol injects current of the defined amounts for a given amount of time
A.setProtocol('CurrentPlateau');
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'plateauDurInSec',.25,...
    'plateaux',12*(1:20),...    % plural of plateaus? Set it however you like
    'postDurInSec',.2);
A.run(3)

