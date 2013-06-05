sampratein = 10000;
samprateout = 10000;
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
stimonset = .41;                                  % time before stim on (seconds)
stimpost = .1;                                  % time after stim offset (seconds)

% timing calculations
stimonsamp = floor(stimonset*samprateout)+1;
stimoffsamp = floor(stimonset*samprateout)+(samprateout*stimdur);
nsampout = stimoffsamp+floor(stimpost*samprateout);
nsampin = ceil(nsampout/samprateout*sampratein);

stim = zeros(nsampout,1);
stim(stimonsamp:stimoffsamp) = stimtrain; %stimulus

istim = zeros(nsampout,1);
% istim(floor(stimonset*samprateout/4)+1:floor(stimonset*samprateout/4)+samprateout*0.2) = .1;
istim(samprateout*.1+1:samprateout*0.4) = 1;

scale = sort([(-6:.5:6) (-.5:.05:.5)]);
scale = ones(size(scale));

%% reset aquisition engines
% configure session
aiSession = daq.createSession('ni');
aiSession.addAnalogInputChannel('Dev1',[0 4], 'Voltage');
aiSession.Rate = sampratein;
aiSession.DurationInSeconds = stimdur+stimonset+stimpost;

% configure AO
aoSession = daq.createSession('ni');
aoSession.addAnalogOutputChannel('Dev1',0, 'Voltage');
aoSession.Rate = samprateout;

aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger')
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger')
M = 1; CHI = {}; YPS = {};

%%
test = 0;
if test
    slope = m(1);
    b = m(2);
    scale = sort([(-.5:.05:.5)]);
end

N = length(scale);
cmd = nan(aiSession.NumberOfScans,N);
divcmd = nan(aiSession.NumberOfScans,N);
curresp = divcmd;
chi = nan(size(1:N));
yps = nan(size(1:N));
zet = nan(size(1:N));

for n = 1:N
    if test
        outputTrace = (scale(n)-b)/slope*istim;
        offset = 0.0045;
        V_offset = offset/slope;
    else
        outputTrace = scale(n)*istim;
        offset = 0;
        V_offset = offset;
    end
    aoSession.wait;
    aoSession.queueOutputData(outputTrace - V_offset)
    aoSession.startBackground; % Start the session that receives start trigger first
    x = aiSession.startForeground;
    cmd(:,n) = scale(n)*istim;
    divcmd(:,n) = (x(:,1)+offset);
    curresp(:,n) = x(:,1) * 1000/(10*1) +0.00890326;
    
    subplot(2,2,1);
    plot(cmd);
    xlabel('sample');
    ylabel('Desired');
    
    subplot(2,2,3);
    % f = sampratein/length(x)*[0:length(x)/2]; f = [f, fliplr(f(2:end-1))];
    % loglog(f,real(fft(nanmean(x,2))).*conj(fft((nanmean(x,2))))); drawnow
    % plot(nanmean(divcmd,2));
    plot(divcmd);
    xlabel('sample');
    ylabel('Actual');

    drawnow
    
    chi(n) = mean(cmd(sampratein*.1+20:sampratein*0.4-20,n));
    yps(n) = mean(divcmd(sampratein*.1+20:sampratein*0.4-20,n));
    zet(n) = mean(curresp(sampratein*.1+20:sampratein*0.4-20,n));
    
    subplot(2,2,2);
    plot(yps,zet,'o');
    
    subplot(2,2,4);
    plot(chi,yps,'o');
end
%
m = polyfit(chi,yps,1);
hold on
plot(chi,m(1)*chi+m(2),'color',[1 1 1]*.8)
text(0,-.4,sprintf('m = %.5f, b = %.5f',m(1),m(2)))
mean(sqrt((yps-(m(1)*chi+m(2))).^2))
text(0,-0.3,sprintf('rms = %e',sqrt(mean((yps-(m(1)*chi+m(2))).^2))));
xlabel('desired')
ylabel('actual')

% *************** Enter the final value in code _____.m at line ____ ******