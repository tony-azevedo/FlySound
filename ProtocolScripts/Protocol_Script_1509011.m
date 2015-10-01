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
A.run(5)

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'freqStart',0,...
    'freqEnd',300,...
    'amps',[3 10]*1,... % [10 40]
    'postDurInSec',.5);
A.run(3)

%% Current injection characterization
steps = [-40 -20 -10 10 20 40];
%steps = [-160 -140 -120 -100 -80 -60 -40 -20 -10 10 20 40];

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',steps);          % tune this (-10:2:10))%
A.run(1)

% %% Current injection characterization: looking for spikes
% 
% plateaux = [-50 -80 -140 -180 -180 -163 -140 0];
% plateaux = [-50 -80 -120 -120 -120 -89 -120 0];
% %plateaux = [-50 -80 -100 -100 -100 -79 -100 0];
% 
% A.setProtocol('CurrentPlateau');
% A.rig.setParams('interTrialInterval',0);
% A.protocol.setParams('-q',...
%     'preDurInSec',1.5,...
%     'postDurInSec',1.5,...
%     'plateauDurInSec',.5,...
%     'plateaux',plateaux,...
%     'randomize',0);
% A.tag
% A.run(1)
% systemsound('Notify');


%% Switch to voltage clamp

%% Which type of neuron?
% celltype = 'BPL';
% celltype = 'BPH';

% %% SineResponses
% for foldX = 1:2
%     A.rig.applyDefaults;
%     
%     srnames = dir(['C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\SineResponse_' celltype '_*' num2str(foldX) 'X*']);
%     A.setProtocol('VoltageCommand');
%     for srn = 1:length(srnames)
%         A.comment(srnames(srn).name(1:end-4))
%         A.protocol.setParams('-q',...
%             'preDurInSec',.2,...
%             'postDurInSec',.2,...
%             'stimulusName',srnames(srn).name(1:end-4));
%         A.run(16)
%     end
% end

%% Voltage Steps 

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.15,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 20 40]);          % tune this 
A.run(2)

%% VoltageSines
amps = [2.5 7.5];
freqs = [25 100 141 200];

A.setProtocol('VoltageSine');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'stimDurInSec',.3,...
    'amps',amps,... % [10 40]
    'freqs',freqs,... % [10 40]
    'postDurInSec',.2)
A.run(16)


%% VoltageRamp Long
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'postDurInSec',0.2,...
    'stimulusName','VoltageRamp_m60_p40_h_1s');
A.run(4)
systemsound('Notify');

%% VoltageRamp Short
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'postDurInSec',0.2,...
    'stimulusName','VoltageRamp_m60_p40_h_0_5s');
A.run(2)
systemsound('Notify');

%% V plateau for Na reversal - only control saline and TTX

step_down = [-60];
step_up = [0 20 40 60 80];
for sd_ind = 1:length(step_down)
    for su_ind = 1:length(step_up)
        plateaux(1) = step_down(sd_ind);
        plateaux(2) = step_up(su_ind);
        
        A.rig.applyDefaults;
        A.setProtocol('VoltagePlateau');
        A.protocol.setParams('-q',...
            'preDurInSec',0.1,...
            'plateaux',plateaux,...
            'plateauDurInSec',0.1,...
            'postDurInSec',0.1);
        A.run(2)
        systemsound('Notify');
    end
end


%% Start over with other drugs.

A.tag


%%
step_up = [20 40];
step_down = [40 30 20 10 0 -10 -20];
for su_ind = 1:length(step_up)
    for sd_ind = 1:length(step_down)
        plateaux(1) = step_up(su_ind);
        plateaux(2) = step_down(sd_ind);
        
        A.rig.applyDefaults;
        A.setProtocol('VoltagePlateau');
        A.protocol.setParams('-q',...
            'preDurInSec',0.2,...
            'plateaux',plateaux,...
            'plateauDurInSec',0.2,...
            'postDurInSec',0.2);
        A.run(2)
        systemsound('Notify');
    end
end
