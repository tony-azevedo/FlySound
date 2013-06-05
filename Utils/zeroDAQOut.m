% set 0 on analog outputs

aoSession = daq.createSession('ni');
aoSession.Rate = 100000;
aoSession.addAnalogOutputChannel('Dev1',0,'Voltage');
aoSession.addAnalogOutputChannel('Dev1',1,'Voltage');
aoSession.addAnalogOutputChannel('Dev1',2,'Voltage');
aoSession.addAnalogOutputChannel('Dev1',3,'Voltage');

aiSession = daq.createSession('ni');
aiSession.Rate = 100000;
aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % scaled output
aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % 100 beta mV/pA
aiSession.addAnalogInputChannel('Dev1',4, 'Voltage'); % 10 Vm

aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');

stim0 = zeros(aoSession.Rate*0.1,length(aoSession.Channels));
aiSession.DurationInSeconds = 0.1;
aoSession.queueOutputData(stim0);  

aoSession.startBackground
y = aiSession.startForeground; %

Vin = y(:,1);

gain = readGain();
Vin = Vin/gain - scaledVoltageOffset(gain);

figure(1);
bluelines = findobj(1,'Color',[0, 0, 1]);
set(bluelines,'color',[.8 .8 1]);
hold on
plot(Vin)


%%
dur = 1;
stim0 = zeros(aoSession.Rate*dur,length(aoSession.Channels));
stim0(2501:20000,1) = 1;

% for model cell: 510 Mohms
% dV = 100 mV
% dI = 100 mV/510 Mohms = .196 nA
% conversion = 2nA/V
% voltage divider = 0.09983 Vout/Vin
% Vin = desired I(in A) / (2nA/Vout) / (0.09983 Vout/Vin)

m = 1.99597; % from the currentInputCalibration script
b = -0.00539;

desiredI = .100/510e6 * 1e9/1; % .196 nA

% desiredI = m*Vdaq+b; 
Vdaq = (desiredI-b)/m; 
stim0 = stim0*Vdaq;

ext_offset = 0.0000; %nA
V_eo_daq = ext_offset/m; 
stim1 = stim0-V_eo_daq;

aoSession.queueOutputData(stim1);  
aiSession.DurationInSeconds = dur;
aoSession.startBackground
y = aiSession.startForeground; %

Vin = y(:,1);
Iin = y(:,2);

gain = readGain();
Vin = Vin/gain - scaledVoltageOffset(gain);

Iin = Iin+ext_offset;
currentscale = 1/1 % V/nA (mV/pA)
Iin = Iin*currentscale;

figure(2);
subplot(2,1,1);
ylabel('V');
bluelines = findobj(2,'Color',[0, 0, 1]);
set(bluelines,'color',[.8 .8 1]);
hold on
plot(Vin)
ylim([-.01 .3])

subplot(2,1,2)
ylabel('nA');
hold on;
plot(Iin);
plot(stim0(:,1)/Vdaq*(desiredI),'r');

crazyfactor = mean(Iin(2601:19000))/(desiredI)
