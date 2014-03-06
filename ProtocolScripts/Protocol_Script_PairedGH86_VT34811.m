%% Paired recordings between B1 cells (GH86) and VT34811 cells
% 

% Start the bitch 
A = Acquisition;
A.setIdentifiers('amplifier1Device','MultiClamp700BAux')

%% trode- use the resistance button

%% Seal on Trode #1
% assume I'm patching the B1 with Left electrode - more stable
A.setIdentifiers('amplifier1Device','MultiClamp700BAux')
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Input Resistance on Trode #1
A.setIdentifiers('amplifier1Device','MultiClamp700BAux')
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')


%% Seal on Trode #2
A.setIdentifiers('amplifier1Device','MultiClamp700B')
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Input Resistance on Trode #2
A.setIdentifiers('amplifier1Device','MultiClamp700B')
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% Definitely Need TTX!  Second time around
A.tag('TTX')
A.untag('TTX')

%% Make sure you're on the right cell
A.setIdentifiers('amplifier1Device','MultiClamp700BAux')

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(3)
systemsound('notify')

%% Assume B1 on left electrode
A.setProtocol('CurrentSine2T');
freqs = 25 * sqrt(2) .^ (-1:10); 
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'amps',[2 4 8],...  % Tune this if necessary
    'stimDurInSec',.4);

A.run(1)
systemsound('Notify');

%% Assume B1 on left electrode
A.setProtocol('CurrentStep2T');
A.protocol.setParams('-q',...
    'steps',[-8 -4 -2 2 4 8],...  % Tune this if necessary
    'postDurInSec',.2,...
    'preDurInSec',.2,...
    'stimDurInSec',.02);
A.run(5)
systemsound('Notify');


%% Assume B1 on left electrode
A.setProtocol('CurrentStep2T');
A.protocol.setParams('-q',...
    'steps',[2 4 8],...  % Tune this if necessary
    'stimDurInSec',.4);
A.run(1)
systemsound('Notify');


