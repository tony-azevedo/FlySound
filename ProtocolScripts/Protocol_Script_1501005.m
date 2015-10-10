%% Voltage Commands to isolate currents

setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;

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
A.rig.applyDefaults;

%% Sweep

%A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
%A.tag
A.run(3)
%A.clearTags

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

%% spiking

A.setProtocol('CurrentSine');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.5,...
    'stimDurInSec',5,...
    'freqs',[50],...
    'amps',[5]*1,... % [10 40]
    'postDurInSec',.5);
A.run(3)


%% Switch to Voltage clamp
% take off Rs and WC
% measure seal N Leak

%% Access
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')
A.rig.applyDefaults;

% turn on seal test
% remeasure WC
% turn on Rs
% record Rs


%% Na inactivation
step_up = 0;
step_down = -60;
durations = 3;
for sd_ind = 1:durations
    down = ones(size(1:sd_ind));
    up = ones(size(sd_ind:durations));
    plateaux = [down*step_down up*step_up];
    
    A.rig.applyDefaults;
    A.setProtocol('VoltagePlateau');
    A.protocol.setParams('-q',...
        'preDurInSec',0.2,...
        'plateaux',plateaux,...
        'plateauDurInSec',0.1,...
        'postDurInSec',0.2);
    A.run(3)
    systemsound('Notify');
end

%% Voltage Steps 
%A.rig.devices.amplifier.setParams('headstageresistorVC',5E9)
%A.rig.devices.amplifier.setParams('headstageresistorVC',5E8)
%A.rig.devices.amplifier.setDefaults

A.setProtocol('VoltageStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.12,...
    'stimDurInSec',0.1,...
    'postDurInSec',0.1,...
    'steps',[-60 -40 -20 -10 -5 -2.5 2.5 5 10 15]);          % tune this 
A.run(6)

%% VoltageSines
amps = [2.5 7.5];
freqs = [25 100 141 200];

A.setProtocol('VoltageSine');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.2,...
    'amps',amps,... % [10 40]
    'freqs',freqs,... % [10 40]
    'postDurInSec',.1)
A.run(12)


%% VoltageRamp 
A.rig.applyDefaults;
A.setProtocol('VoltageCommand');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'postDurInSec',0.2,...
    'stimulusName','VoltageRamp_m50_p12_h_0_5s');
A.run(5)
systemsound('Notify');


%% Start over with other drugs.

A.tag


% %%
% step_up = [20 40];
% step_down = [40 30 20 10 0 -10 -20];
% for su_ind = 1:length(step_up)
%     for sd_ind = 1:length(step_down)
%         plateaux(1) = step_up(su_ind);
%         plateaux(2) = step_down(sd_ind);
%         
%         A.rig.applyDefaults;
%         A.setProtocol('VoltagePlateau');
%         A.protocol.setParams('-q',...
%             'preDurInSec',0.2,...
%             'plateaux',plateaux,...
%             'plateauDurInSec',0.2,...
%             'postDurInSec',0.2);
%         A.run(2)
%         systemsound('Notify');
%     end
% end
% 
% %% V plateau for Na reversal - only control saline and TTX
% 
% step_down = [-60];
% step_up = [0 20 40 60];
% for sd_ind = 1:length(step_down)
%     for su_ind = 1:length(step_up)
%         plateaux(1) = step_down(sd_ind);
%         plateaux(2) = step_up(su_ind);
%         
%         A.rig.applyDefaults;
%         A.setProtocol('VoltagePlateau');
%         A.protocol.setParams('-q',...
%             'preDurInSec',0.12,...
%             'plateaux',plateaux,...
%             'plateauDurInSec',0.1,...
%             'postDurInSec',0.1);
%         A.run(2)
%         systemsound('Notify');
%     end
% end
