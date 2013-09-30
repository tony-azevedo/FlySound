% Start the bitch
A = Acquisition;

%% Sweep, estimate output
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',1);
A.tag('Calibrate')
A.run


%% Steps of current or voltage
A.setProtocol('SealAndLeak');
A.tag('Calibrate')
A.run

