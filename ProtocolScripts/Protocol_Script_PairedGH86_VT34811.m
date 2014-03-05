%% Paired recordings between B1 cells (GH86) and VT34811 cells
% 

% Start the bitch 
A = Acquisition;

%% trode- use the resistance button

%% Seal on Trode #1
% assume I'm patching the B1 with Left electrode - more stable
A.setProtocol('SealAndLeak','amplifier1Device','MultiClamp700BAux');
A.tag('Seal')
A.run
A.untag('Seal')

%% Input Resistance on Trode #1
A.setProtocol('SealAndLeak','amplifier1Device','MultiClamp700BAux');
A.tag('R_input')
A.run
A.untag('R_input')


%% Seal on Trode #2
A.setProtocol('SealAndLeak','amplifier1Device','MultiClamp700B');
A.tag('Seal')
A.run
A.untag('Seal')

%% Input Resistance on Trode #2
A.setProtocol('SealAndLeak','amplifier1Device','MultiClamp700B');
A.tag('R_input')
A.run
A.untag('R_input')

%% Definitely Need TTX!  Second time around
A.tag('TTX')
A.untag('TTX')

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(3)
systemsound('notify')


%% Hyperpolarized
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Hyperpolarized')
A.run(3)
A.untag('Hyperpolarized')
systemsound('Notify');

%% Spiking, somewhere in between
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.tag('Spiking')
A.run(5)
A.untag('Spiking')
systemsound('Notify');

%% Steps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
beep 

%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','Vm_id',0);
A.protocol.setParams('-q','cycles',6,'displacement',1);
A.run(3)
beep 

%% PiezoSine
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:10); 
A.protocol.setParams('-q','freqs',freqs,'displacements',[0.1 0.2 0.4 0.8 1.6]);
A.protocol.randomize
A.run(3)
beep

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
beep

%% Backwards Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4 0.8],'postDurInSec',1);
A.run(3)
beep

%% PiezoChirp Up
A.setProtocol('PiezoChirp');
A.protocol.setParams('-q','displacements',[0.1 0.2 0.4 0.8]);
A.run(3)
beep

%% PiezoChirp Down
A.setProtocol('PiezoChirp','modusOperandi','Cal');
A.protocol.setParams('-q','displacements',[0.1 0.2 0.4 0.8],...
    'freqStart',800,...
    'freqEnd',25);
% A.protocol.CalibrateStimulus(A)
A.run(3)
beep

%% Hyperpolarization is not as interesting in these cells


%% CurrentSine
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'steps',[5 10 20],...  % Tune this if necessary
    'stimDurInSec',.4);
A.run(5)
systemsound('Notify');

%% Hyperpolarized CurrentSine
A.setProtocol('CurrentSine');
freqs = 25 * sqrt(2) .^ (0:10); 
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'amps',[5 10 20],...  % Tune this if necessary
    'postDurInSec',1);

A.tag('Hyperpolarized')
A.run(5)
A.untag('Hyperpolarized')
systemsound('Notify');


%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_{input}')
A.run
A.untag('R_{input}')

%% Amplitude modulation of 100Hz stimulus

