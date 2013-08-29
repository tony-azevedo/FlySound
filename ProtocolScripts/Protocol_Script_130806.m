% Start the bitch
A = Acquisition;

%% test
A.setProtocol('SealTest');
A.protocol.run

%%
A.protocol.stop

%% trode
A.setProtocol('SealAndLeak');
A.comment('Trode')
A.protocol.run

%% test
A.setProtocol('SealTest');
A.protocol.run

%%
A.protocol.stop

%% Seal
A.setProtocol('SealAndLeak');
A.comment('Seal')
A.protocol.run

%% test
A.setProtocol('SealTest');
A.protocol.run

%%
A.protocol.stop

%% Break in
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.protocol.run

%% Resting potential and oscillations (5x5 sec)
A.setProtocol('Sweep');
A.comment('Resting potential and oscillations ')
A.protocol.run(5)
beep 

%% Hyperpolarize (spikes) (5x5 sec)
A.setProtocol('Sweep');
A.comment('Hyperpolarize ')
A.protocol.setParams('Vm_id',-3);
A.protocol.run(5)
beep 

%% Middle range (5x5 sec)
A.setProtocol('Sweep');
A.comment('Middle range ')
A.protocol.setParams('Vm_id',-2);
A.protocol.run(5)
beep 

%% Middle range (5x5 sec)
A.setProtocol('Sweep');
A.comment('Middle range ')
A.protocol.setParams('Vm_id',-1);
A.protocol.run(5)
beep 

%% Depolarize (oscillations) (5x5 sec)
A.setProtocol('Sweep');
A.comment('Depolarize (oscillations) (5x5 sec)')
A.protocol.setParams('Vm_id',1);
A.protocol.run(5)
beep 

%% Steps at rest
A.setProtocol('PiezoStep');
A.comment('Depolarize (oscillations) (5x5 sec)')
A.protocol.setParams('Vm_id',1);
A.protocol.run(5)
beep 

%% I=0, then turn on holding command, then switch to current clamp (fast or whatever)

%% Break in
A.setProtocol('SealAndLeak');
A.comment('Break in / Leak')
A.protocol.run

%% I=0, then turn off holding command, then switch to current clamp

%% PiezoSine at rest
p = PiezoSine;
p.setParams('freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

beep

%% PiezoSine hyperpolarized (same sensitivity?)
p = PiezoSine;
p.setParams('Vm_id',-1,'freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

%% PiezoSine depolarized (same sensitivity?)
p = PiezoSine;
p.setParams('Vm_id',1,'freqs',[25,50,100,200,400],'displacement',.5);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

%% **************************
%% Test seal
p = SealAndLeak;
p.run

%% mecamylamine
p.comment('Mecamylamine')
%% Test seal
p = SealAndLeak;
p.run

%% Stes
p = PiezoStep;
p.comment('Mecamylamine')
p.setParams('displacement',1);
p.run(5);
p.setParams('displacement',-1);
p.run(5);
p.setParams('displacement',1);
p.run(5);
p.setParams('displacement',-1);
p.run(5);

%% at REst
p = Sweep;
p.comment('Mecamylamine')
p.setParams('Vm_id',0);
p.run(3)
beep

%% Hyperpolarize (spikes) (5x5 sec)
p = Sweep;
p.comment('Mecamylamine')
p.setParams('Vm_id',-3);
p.run(3)
beep

%% Middle range (5x5 sec)
p = Sweep;
p.comment('Mecamylamine')
p.setParams('Vm_id',-2);
p.run(5)
beep

%% Middle range (5x5 sec)
p = Sweep;
p.setParams('Vm_id',-1);
p.run(5)
beep

%% Depolarize (oscillations) (5x5 sec)
p = Sweep;
p.setParams('Vm_id',1);
p.run(5)
beep


%% Steps at rest
p = PiezoStep;
p.comment('Mecamylamine')
p.setParams('displacement',1);
p.run(5);

p.setParams('displacement',3);
p.run(5);

p.setParams('displacement',-3);
p.run(5);

p.setParams('displacement',-1);
p.run(5);

%% Test seal
p = SealAndLeak;
p.run

%% PiezoSine at rest
p = PiezoSine;
p.comment('Mecamylamine')
p.setParams('freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);
beep
%% PiezoSine hyperpolarized (same sensitivity?)
p = PiezoSine;
p.setParams('Vm_id',-1,'freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);
beep
%% PiezoSine depolarized (same sensitivity?)
p = PiezoSine;
p.setParams('Vm_id',1,'freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

%% **************************
%% Test seal
p = SealAndLeak;
p.run

%% TTX

%% Test seal
p = SealAndLeak;
p.run

%% at REst
p = Sweep;
p.comment('TTX')
p.setParams('Vm_id',0);
p.run(3)
beep

%% Hyperpolarize (spikes) (5x5 sec)
p = Sweep;
p.comment('TTX')
p.setParams('Vm_id',-3);
p.run(3)
beep

%% Middle range (5x5 sec)
p = Sweep;
p.comment('TTX')
p.setParams('Vm_id',-2);
p.run(5)
beep

%% Middle range (5x5 sec)
p = Sweep;
p.comment('TTX')
p.setParams('Vm_id',-1);
p.run(5)
beep

%% Depolarize (oscillations) (5x5 sec)
p = Sweep;
p.comment('TTX')
p.setParams('Vm_id',1);
p.run(5)
beep

%% Steps at rest
p = PiezoStep;
p.comment('TTX')
p.setParams('displacement',1);
p.run(5);

p.setParams('displacement',3);
p.run(5);

p.setParams('displacement',-3);
p.run(5);

p.setParams('displacement',-1);
p.run(5);

%% Test seal
p = SealAndLeak;
p.run

%% PiezoSine at rest
p = PiezoSine;
p.comment('TTX')
p.setParams('freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

%% PiezoSine hyperpolarized (same sensitivity?)
p = PiezoSine;
p.comment('TTX')
p.setParams('Vm_id',-1,'freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

%% PiezoSine depolarized (same sensitivity?)
p = PiezoSine;
p.comment('No Cell')
p.setParams('Vm_id',1,'freqs',[25,50,100,200,400],'displacement',.5,'postDurInSec',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',1);
p.run(3);

p.setParams('freqs',[25,50,100,200,400],'displacement',2);
p.run(3);

