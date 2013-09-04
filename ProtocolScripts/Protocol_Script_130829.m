% Start the bitch
A = Acquisition;

%% test
A.setProtocol('SealTest');
A.run

%%
A.run

%%
A.rig.stop

%% trode
A.setProtocol('SealAndLeak');
A.comment('Trode')
A.run

%% test
A.setProtocol('SealTest');
A.run

%%
A.rig.stop

%% Seal
A.setProtocol('SealAndLeak');
A.comment('Seal')
A.run

%% test
A.setProtocol('SealTest');
A.run

%%
A.rig.stop

%% Break in
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% Resting potential and oscillations (5x5 sec)
A.setProtocol('Sweep');
A.comment('Resting potential and oscillations ')
A.run(5)
beep 

%% Hyperpolarize (spikes) (5x5 sec)
A.setProtocol('Sweep');
A.comment('Hyperpolarize ')
A.protocol.setParams('Vm_id',-3);
A.run(5)
beep 

%% Middle range (5x5 sec)
A.setProtocol('Sweep');
A.comment('Middle range ')
A.protocol.setParams('Vm_id',-2);
A.run(5)
beep 

%% Middle range (5x5 sec)
A.setProtocol('Sweep');
A.comment('Middle range ')
A.protocol.setParams('Vm_id',-1);
A.run(5)
beep 

%% Depolarize (oscillations) (5x5 sec)
A.setProtocol('Sweep');
A.comment('Depolarize (oscillations) (5x5 sec)')
A.protocol.setParams('Vm_id',1);
A.run(5)
beep 

%% Steps at rest
A.setProtocol('PiezoStep');
A.comment('At rest (5x5 sec)')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% I=0, then turn on holding command (-60), then switch to Voltage clamp (fast or whatever)

%% Break in
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% I=0, then turn off holding command, then switch to current clamp

%% PiezoSine at rest
A.setProtocol('PiezoSine');
A.comment('At rest')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% PiezoSine hyperpolarized (same sensitivity?)
A.setProtocol('PiezoSine');
A.comment('hyperpolarized')
%A.protocol.setParams('Vm_id',-1,'freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.protocol.setParams('Vm_id',-1,'freqs',[25,50],'displacements',[0.1 0.2],'postDurInSec',1.5);
A.run(3)
beep

%% PiezoSine depolarized (same sensitivity?)
A.comment('depolarized')
A.protocol.setParams('Vm_id',1,'freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% **************************
%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% mecamylamine
A.comment('Mecamylamine')
%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% Steps at rest
A.setProtocol('PiezoStep');
A.comment('Mecamylamine at rest')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% Sweeps at Rest
A.setProtocol('Sweep');
A.comment('Mecamylamine at rest')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 


%% Hyperpolarize (spikes) (5x5 sec)
A.comment('Mecamylamine Hyperpolarize')
A.protocol.setParams('Vm_id',-3);
A.run(5)
beep 

%% Middle range (5x5 sec)
A.comment('Mecamylamine Middle')
A.protocol.setParams('Vm_id',-2);
A.run(5)
beep 


%% Middle range (5x5 sec)
A.comment('Mecamylamine Middle')
A.protocol.setParams('Vm_id',-1);
A.run(5)
beep 

%% Middle range (5x5 sec)
A.comment('Mecamylamine Depolarize')
A.protocol.setParams('Vm_id',1);
A.run(5)
beep 


%% Steps at rest
A.setProtocol('PiezoStep');
A.comment('Mecamylamine at rest')
A.protocol.setParams('Vm_id',0);
A.run(3)
beep 


%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% PiezoSine at rest
A.setProtocol('PiezoSine');
A.comment('Mecamylamine rest')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% PiezoSine hyperpolarized (same sensitivity?)

A.setProtocol('PiezoSine');
A.comment('Mecamylamine hyperpolarized')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% PiezoSine depolarized (same sensitivity?)

A.setProtocol('PiezoSine');
A.comment('Mecamylamine depolarized')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% **************************
%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run


%% **************************

% TTX
%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% mecamylamine
A.comment('TTX')
%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% Steps at rest
A.setProtocol('PiezoStep');
A.comment('TTX at rest')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 

%% Sweeps at Rest
A.setProtocol('Sweep');
A.comment('TTX at rest')
A.protocol.setParams('Vm_id',0);
A.run(5)
beep 


%% Hyperpolarize (spikes) (5x5 sec)
A.comment('TTX Hyperpolarize')
A.protocol.setParams('Vm_id',-3);
A.run(5)
beep 

%% Middle range (5x5 sec)
A.comment('TTX Middle')
A.protocol.setParams('Vm_id',-2);
A.run(5)
beep 


%% Middle range (5x5 sec)
A.comment('TTX Middle')
A.protocol.setParams('Vm_id',-1);
A.run(5)
beep 

%% Middle range (5x5 sec)
A.comment('TTX Depolarize')
A.protocol.setParams('Vm_id',1);
A.run(5)
beep 


%% Steps at rest
A.setProtocol('PiezoStep');
A.comment('TTX at rest')
A.protocol.setParams('Vm_id',0);
A.run(3)
beep 


%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% PiezoSine at rest
A.setProtocol('PiezoSine');
A.comment('TTX rest')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% PiezoSine hyperpolarized (same sensitivity?)

A.setProtocol('PiezoSine');
A.comment('TTX hyperpolarized')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% PiezoSine depolarized (same sensitivity?)

A.setProtocol('PiezoSine');
A.comment('TTX depolarized')
A.protocol.setParams('freqs',[25,50,100,200,400],'displacements',[0.1 0.2 0.4 0.8],'postDurInSec',1.5);
A.run(3)
beep

%% **************************
%% Test seal
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.run

%% TTX



