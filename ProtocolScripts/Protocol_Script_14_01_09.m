%% Targeted patch recordings of VT30609 - the suspected cell, 
% ie, 1.5 according to yesterday's recordings, top left bright one.
% Then cell attached once I have determined the sensitivity to sound

% Start the bitch 
A = Acquisition;

%% trode- use the resistance button

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Input
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

%% 2 nd time around do this
A.tag('TTX')
A.untag('TTX')

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)
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

%% PiezoSine
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:10); 
freqs = freqs([1 3 4 5 6 7 9]); %  25 50 70.7107  100 141.4214  200 400
A.protocol.setParams('-q','freqs',freqs,'displacements',[0.1 0.2 0.4],'postDurInSec',1);
A.run(3)
beep

%% CurrentSine
A.setProtocol('CurrentSine');
freqs = 25 * sqrt(2) .^ (0:10); 
%freqs = freqs([1 3 4 5 6 7 9]); %  25 50 70.7107  100 141.4214  200 400
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'amps',[5 10 20],...  % Tune this if necessary
    'postDurInSec',1);
A.run(5)
systemsound('Notify');


%% Hyperpolarized PiezoSine
A.setProtocol('PiezoSine');
freqs = 25 * sqrt(2) .^ (0:10); 
freqs = freqs([1 3 4 5 6 7 9]); %  25 50 70.7107  100 141.4214  200 400
A.protocol.setParams('-q','freqs',freqs,'displacements',[0.1 0.2 0.4],'postDurInSec',1);
A.tag('Hyperpolarized')
A.run(3)
A.untag('Hyperpolarized')
beep

%% Hyperpolarized CurrentSine
A.setProtocol('CurrentSine');
freqs = 25 * sqrt(2) .^ (0:10); 
freqs = freqs([1 3 4 5 6 7 9]); %  25 50 70.7107  100 141.4214  200 400
A.protocol.setParams('-q',...
    'freqs',freqs,...
    'amps',[5 10 20],...  % Tune this if necessary
    'postDurInSec',1);

A.tag('Hyperpolarized')
A.run(5)
A.untag('Hyperpolarized')
systemsound('Notify');

%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4],'postDurInSec',1);
A.run(3)
beep

%% Backwards Courtship song
A.setProtocol('PiezoBWCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4],'postDurInSec',1);
A.run(3)
beep

%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','Vm_id',0);
A.protocol.setParams('-q','cycles',10,'displacement',1);
A.run(5)
beep 

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_{input}')
A.run
A.untag('R_{input}')

%% Amplitude modulation of 100Hz stimulus

