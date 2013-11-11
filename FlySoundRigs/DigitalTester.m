%% digital tester
d = daq.getDevices;

aoSession = daq.createSession('ni');
aiSession = daq.createSession('ni');

% http://www.mathworks.com/help/releases/R2012b/daq/ref/daq.session.adddigitalchannel.html
aiSession.addAnalogInputChannel('Dev1',0,'Voltage');
aiSession.addAnalogInputChannel('Dev1',18,'Voltage');
aiSession.Rate = 50000;

aoSession.addAnalogOutputChannel('Dev1',1,'Voltage');
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');

aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
% aiSession.addTriggerConnection('Dev1/PFI3','External','StartTrigger');

%%
%datacolumns = exp(-100000*(0:999)'/1000); 
%datacolumns = sin(2*pi*10*(1:1000)'/1000); 
framerate = 70;
deltaT = round(1/70 * aoSession.Rate);
triggers = zeros(size((0:1000-1)'));
triggers(deltaT:deltaT:end) = 1;
triggers(end) = 0;

datacolumns = 3.3*triggers;

aoSession.queueOutputData(datacolumns);
aoSession.startBackground; % Start the session that receives start trigger first

% Collect input
in = aiSession.startForeground; % both amp and signal monitor input

plot(in)

%% Quick check

din = in(:,1);
din = din>1;

dintrans = [-(din(1:end-1) - din(2:end)); 0];

ai = in(:,2);
snips = nan(sum(dintrans==-1),60);
ind = find(dintrans==-1);
for i = 1:length(ind)
    snips(i,:) = ai(ind(i):ind(i)+60-1);
end

plot(snips'), hold on
plot(mean(snips,1))