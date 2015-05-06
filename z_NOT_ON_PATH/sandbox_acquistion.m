sampratein = 10000;
samprateout = 40000;
stimdur = .1;
fc = 400;
fm = 1;

% stimname = ['AM tone, fc ', num2str(data(n).fc),' Hz, fm ', ...
%     num2str(data(n).fm), ' Hz, m = 100%, duration ',...
%     num2str(data(n).stimdur),' seconds'];
AMtrain = amp_mod(1,fm,fc,.5,...
    samprateout,stimdur,1,'with carrier');
if isempty(AMtrain)
    fprintf('AM stimulus not generated');
    return;
end
intensity = .1; % set voltage scaling factor for stimulus output
stimtrain = intensity.*AMtrain(:);  % make sure stim is a column vector

% stimName = exp_info.stimName;
stimonset = 1;                                  % time before stim on (seconds)
stimpost = .5;                                  % time after stim offset (seconds)

% timing calculations
stimonsamp = floor(stimonset*samprateout)+1;
stimoffsamp = floor(stimonset*samprateout)+(samprateout*stimdur);
nsampout = stimoffsamp+floor(stimpost*samprateout);
nsampin = ceil(nsampout/samprateout*sampratein);

stim = zeros(nsampout,1);
stim(stimonsamp:stimoffsamp) = stimtrain; %stimulus

Ihpulse = -1;                                      % hyperpolarizing pulse should give a
% 4 pA hyperpolarizing signal
istim = zeros(nsampout,1);
% istim(floor(stimonset*samprateout/4)+1:floor(stimonset*samprateout/4)+samprateout*0.2) = .1;
istim(samprateout*.1+1:samprateout*0.4) = .1;

%% reset aquisition engines
% configure session
aiSession = daq.createSession('ni');
aiSession.addAnalogInputChannel('Dev1',0:1, 'Voltage');
aiSession.Rate = sampratein;
aiSession.DurationInSeconds = stimdur+stimonset+stimpost;

% configure AO
aoSession = daq.createSession('ni');
aoSession.addAnalogOutputChannel('Dev1',0:1, 'Voltage');
aoSession.Rate = samprateout;

aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger')
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger')
M = 1; CHI = {}; YPS = {};
%%
N = 5;
cmd = nan(aiSession.NumberOfScans,N);
divcmd = nan(aiSession.NumberOfScans,N);
chi = nan(size(1:N));
yps = nan(size(1:N));

for n = 1:N
aoSession.queueOutputData([n*istim stim])

aoSession.startBackground; % Start the session that receives start trigger first 
x = aiSession.startForeground;
cmd(:,n) = x(:,1);
divcmd(:,n) = x(:,2);

subplot(2,2,1);
plot(cmd); 
xlabel('sample');
ylabel('I');

subplot(2,2,3);
% f = sampratein/length(x)*[0:length(x)/2]; f = [f, fliplr(f(2:end-1))];
% loglog(f,real(fft(nanmean(x,2))).*conj(fft((nanmean(x,2))))); drawnow
% plot(nanmean(divcmd,2)); 
plot(divcmd); 
xlabel('Hz');
ylabel('Power');

drawnow

% TODO:    aiSession.addTriggerConnection('Dev1/PFI1','External','StartTrigger')
%     aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger')
%
% ao.startBackground; % Start the session that receives start trigger first
%ai.startBackground;

chi(n) = mean(cmd(sampratein*.1+20:sampratein*0.4-20,n));
yps(n) = mean(divcmd(sampratein*.1+20:sampratein*0.4-20,n));

subplot(1,2,2);
plot(chi,yps,'o');

pause()
end

CHI{M} = chi; YPS{M} = yps;
M = M+1;
% data(n).trigdiff = AO.InitialTriggerTime-AI.InitialTriggerTime;

%% configure analog input
% AI = analoginput ('nidaq', 'Dev1');
% addchannel (AI, 0:2);   % acquire from ACH0, ACH1, and ACH2, which contain 
%                         % the 10Vm out, I out, and scaled output, respectively
% set(AI, 'SampleRate', samprate);
% set(AI, 'SamplesPerTrigger', inf);
% set(AI, 'InputType', 'Differential');
% set(AI, 'TriggerType', 'Manual');
% set(AI, 'ManualTriggerHwOn','Trigger');


%% collect and analyse data(n)

% read data from engine
x = getdata(AI,length(t));

% record current-clamp or voltage-clamp data
if strcmp(recMode,'VClamp')
    voltage = x(:,1); voltage = voltage';  % acquire voltage from 10Vm (channel ACH0)
    current = x(:,3); current = current';  % acquire current from scaled output (channel ACH3)
elseif strcmp(recMode,'IClamp')
    current = x(:,2); current = current';
    voltage = x(:,3); voltage = voltage';
end




