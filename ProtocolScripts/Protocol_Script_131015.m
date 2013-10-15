%% Whole cell recordings, Na exchange recordings

% good day, get one cel in the morning!  Take care of important morning fly
% stuff, then get to patching!  

% The typical big spiking neuron also shows the non-flat step response.
% didn't seem to see much change in the membrane potential with different
% Na concentrations, certainly not the kind that Rachel would like to see

% second cell was a wash, very hard to get

% Third cell was one of the tight cluster, this was a strange cell, more
% of an integrator, strong onset and offset responses to steps, Na exchange
% didn't seem to do 
% much, TTX eliminated input


% Start the bitch 
A = Acquisition;

%% trode
A.setProtocol('SealAndLeak');
A.tag('Trode')
A.run
A.untag('Trode')

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% 2 nd time around do this
A.tag('90 mM Sodium')
A.untag('90 mM Sodium')
A.tag('50 mM Sodium')
A.untag('50 mM Sodium')
A.tag('TTX')


%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)
beep 

%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.tag('Hyperpolarized')
A.protocol.setParams('-q','durSweep',5);
A.run(5)
A.untag('Hyperpolarized')
beep 



%% Steps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
beep 


%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','Vm_id',0);
A.protocol.setParams('-q','cycles',10,'displacement',1);
A.run(5)
beep 

%% PiezoSine
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[12.5, 25,50,100,200,400],'displacements',[0.1 0.2 0.4 ],'postDurInSec',1);
A.run(3)
beep

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

%% Amplitude modulation of 100Hz stimulus




%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.tag('Ringing')
A.protocol.setParams('-q','freqs',[50 100 200],...
    'displacement',[0.4],'displacements',[0.4],...
    'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.run(3)
A.untag('Ringing')
beep

%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')



%% %%%%%%%  TTX %%%%%%%%%
A.tag('TTX')

%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[50 100 200],'displacements',[0.4],'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.tag('Ringing')
A.run(10)
A.untag('Ringing')
beep

%% Courtship song TTX
A.setProtocol('PiezoCourtshipSong');
A.tag('TTX')
A.protocol.setParams('displacements',[0.1 0.2 0.4],'postDurInSec',1);
A.run(5)
beep

