%% Cell-attached recordings
% This day was pretty much a wash.  I stuggled with patching, saw spikes in
% one B1 cell, then some weird stuff notated in the notebook, then I patch
% some random cell with a strange response, spiking that appeared not to
% change with application of 90mM Na.  Oh well
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
A.untag('90 mM Sodium')
A.tag('TTX')


%% Resting potential and oscillations (5x5 sec) Minimize current
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(5)
beep 

%% Steps
A.setProtocol('PiezoStep');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
beep 


%% Big Step
A.setProtocol('PiezoSquareWave');
A.protocol.setParams('-q','Vm_id',0);
A.run(5)
beep 

%% PiezoSine
A.setProtocol('PiezoSine');
A.protocol.setParams('-q','freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 ],'postDurInSec',1.5);
A.run(3)
beep

%% Amplitude modulation of 100Hz stimulus


%% Courtship song
A.setProtocol('PiezoCourtshipSong');
A.protocol.setParams('-q','displacements',[0.2 0.4],'postDurInSec',1);
A.run(5)
beep

%% PiezoSine ringing test
A.setProtocol('PiezoSine');
A.tag('Ringing')
A.protocol.setParams('-q','freqs',[50 100 200],...
    'displacement',[0.4],'displacements',[0.4],...
    'postDurInSec',1.5,'stimDurInSec',0.2,'ramptime',0.02);
A.run(5)
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

