setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
A = Acquisition;


%% Sweep
setpref('AcquisitionHardware','cameraToggle','off')

A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.run(1)

%%
s.aoSession = daq.createSession('ni');
ch1 = s.aoSession.addAnalogOutputChannel('Dev1',0,'Voltage')
% ch1.Name = 'voltage'
ch2 = s.aoSession.addAnalogInputChannel('Dev1',0,'Voltage')
% ch2.Name = 'current'

s.aoSession.queueOutputData(zeros(1000,1));
in = s.aoSession.startForeground; % both amp and signal monitor input

%%
s.aoSession = daq.createSession('ni');
ch1 = s.aoSession.addAnalogOutputChannel('Dev1',0,'Voltage')

ch2= s.aoSession.addAnalogInputChannel('Dev1',0,'Voltage')

s.aoSession.queueOutputData(zeros(1000,1));
in = s.aoSession.startForeground;