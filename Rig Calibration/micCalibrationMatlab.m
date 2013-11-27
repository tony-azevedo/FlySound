% Mic Calibration script, w/o Ovation Bullshit

cd('C:\Users\Anthony Azevedo\Raw_Data\27-sep-2013\27-Sep-2013_Mic1_E1');

%% reject any trials that go above the rails
% Note, this is set at 7.2V.  I don't know where this number comes from,
% aiSession in calibrate_microphone generates channels that hit -10:+10.
% Why this clipping?

datafilename = dir('Calibration Parameters*');
data = load(datafilename(1).name); data = data.data; clear datafilename
rawfiles = dir('RawMicCal*');
load(rawfiles(1).name);
t = (1:length(BK_voltage))/data(1).fs_in;
winl = .1;
winr = .15;

if ~isdir('Archive')
    mkdir('Archive')
end

figure(1), clf
subplot(3,3,[1 2],'parent',1); ylim([-8 8])
subplot(3,3,[4 5],'parent',1); ylim([-8 8])
subplot(3,3,[7 8],'parent',1); ylim([-8 8])
subplot(3,3,3,'parent',1); ylim([-8 8])
subplot(3,3,6,'parent',1); ylim([-8 8])
subplot(3,3,9,'parent',1); ylim([-8 8])
for rf = 1:length(rawfiles)
    load(rawfiles(rf).name);
    
    if sum(abs(BK_voltage)>7.2) || sum(abs(KE1_voltage)>7.2) || sum(abs(KE2_voltage)>7.2)
        ax = subplot(3,3,[1 2],'parent',1);
        cla(ax);
        plot(t(t>winl&t<=winr),BK_voltage(t>winl&t<=winr),'parent',ax);
        ax = subplot(3,3,[4 5],'parent',1);
        cla(ax);
        plot(t(t>winl&t<=winr),KE1_voltage(t>winl&t<=winr),'parent',ax);
        ax = subplot(3,3,[7 8],'parent',1);
        cla(ax);
        plot(t(t>winl&t<=winr),KE2_voltage(t>winl&t<=winr),'parent',ax);
        
        
        ax = subplot(3,3,3,'parent',1);
        cla(ax);
        plot(t,BK_voltage,'parent',ax);
        ax = subplot(3,3,6,'parent',1);
        cla(ax);
        plot(t,KE1_voltage,'parent',ax);
        ax = subplot(3,3,9,'parent',1);
        cla(ax);
        plot(t,KE2_voltage,'parent',ax);
        drawnow
        
        movefile(rawfiles(rf).name,'Archive')
    end
end
beep

%% trial 33, gain KE 1 and 2 should have gain of 500 rather than 1000
datafilename = dir('Calibration Parameters*');
data = load(datafilename(1).name); data = data.data; 
for d = 1:length(data)
    if data(d).trial==33 && data(d).gain_KE1 ~= 500
        disp(data(d));
        data(d).gain_KE1 = 500;
        data(d).gain_KE2 = 500;
        disp(data(d));
        save(datafilename(1).name,'data');
    end
end

%% Analysis
rawfiles = dir('RawMicCal*');
load(rawfiles(1).name);
t = (1:length(BK_voltage))/data(1).fs_in;
winl = .1;
winr = .15;

datafilename = dir('Calibration Parameters*');
data = load(datafilename(1).name); data = data.data; clear datafilename

kBK = 49.4e-3; % [V/Pa]
c = 337.24; % [m/s]
rho = 1.2466; % [kg/m^3]

params_fft1 = {};
params_fft2 = {};

kKE1_arg = [];
kKE2_arg = [];

clf
fftax = subplot(2,2,3);
axis(fftax,'square','equal')
compareax = subplot(2,2,4);
axis(compareax,'square','equal')
psax = subplot(2,1,1);

for d = 1:length(data)
    % Bring in all trial reps
    repsfiles = dir(sprintf('RawMicCal_27-Sep-2013_Mic1_E1_%d_Rep*',data(d).trial));
    if isempty(repsfiles)
        % skip trials with no reps (eg 32)
        fprintf(1,'No reps for %s',sprintf('RawMicCal_27-Sep-2013_Mic1_E1_%d_Rep*',data(d).trial));
        continue
    end
    
    trial = load(repsfiles(1).name);
    BK_voltage_mat = nan(length(trial.BK_voltage),length(repsfiles));
    KE1_voltage_mat = nan(length(trial.KE1_voltage),length(repsfiles));
    KE2_voltage_mat = nan(length(trial.KE2_voltage),length(repsfiles));

    for rep = 1:length(repsfiles)
        trial = load(repsfiles(rep).name);
        BK_voltage_mat(:,rep) = trial.BK_voltage;
        KE1_voltage_mat(:,rep) = trial.KE1_voltage;
        KE2_voltage_mat(:,rep) = trial.KE2_voltage;
    end

    % Average
    BK_voltage = mean(BK_voltage_mat,2);
    KE1_voltage = mean(KE1_voltage_mat,2);
    KE2_voltage = mean(KE2_voltage_mat,2);

    % Subtract off DC
    BK_voltage = BK_voltage - mean(BK_voltage);
    KE1_voltage = KE1_voltage - mean(KE1_voltage);
    KE2_voltage = KE2_voltage - mean(KE2_voltage);

    % scale
    BK_voltage = BK_voltage/data(d).gain_BK;
    KE1_voltage = KE1_voltage/data(d).gain_KE1;
    KE2_voltage = KE2_voltage/data(d).gain_KE2;

    % Integrate 
    KE1_voltage_int = cumtrapz(t,KE1_voltage);
    KE2_voltage_int = cumtrapz(t,KE2_voltage);
    
    % ******* Method 1: Calulate fourier components
    f = data(d).fs_in/length(BK_voltage)*[0:length(BK_voltage)/2]; f = [f, fliplr(f(2:end-1))];
    bkfft = fft(BK_voltage);
    ke1fft = fft(KE1_voltage);
    ke2fft = fft(KE2_voltage);

    bkps = bkfft.*conj(bkfft);

    % find the power peak
    win = max(.01*data(d).freq,2);
    [bk_pow_peak,ind] = max(bkps(...
        (1:length(bkps) < length(bkps)/2) ...
        & f>data(d).freq-win...
        & f<data(d).freq+win));
    
    f_ind = sum((1:length(f) < length(f)/2) & f<=data(d).freq-win)+ind;
    f_max = f(f_ind);
    
    % this should be a real number
    kKE1 = (ke1fft(f_ind)/1i)/bkfft(f_ind) * (kBK * rho * c / (2*pi*f_max));
    line([0,real(kKE1)],[0,imag(kKE1)],'parent',fftax);
    kKE1_arg(end+1) = angle(kKE1);
    disp(kKE1_arg(end)/2/pi);
    
    kKE2 = (ke2fft(f_ind)/1i)/bkfft(f_ind) * (kBK * rho * c / (2*pi*f_max));
    line([0,real(kKE2)],[0,imag(kKE2)],'linestyle','--','parent',fftax); 
    kKE2_arg(end+1) = angle(kKE2);
    disp(kKE2_arg(end)/2/pi);

    drawnow
    
    % Store the values
    params_fft1{end+1} = [data(d).freq,data(d).voltage,abs(kKE1)];
    params_fft2{end+1} = [data(d).freq,data(d).voltage,abs(kKE2)];
    
    
    % ******* Method 2: Use the integrated function and PS
    ke1fft = fft(KE1_voltage_int);
    ke2fft = fft(KE2_voltage_int);

    ke1ps = ke1fft.*conj(ke1fft);
    ke2ps = ke2fft.*conj(ke2fft);

    kKE1_p = sqrt(ke1ps(f_ind)/bkps(f_ind)) * kBK *rho * c;
    %plot([0,real(kKE1)],[0,imag(kKE1)],'r','parent',psax); hold on
    l1 = line(d,real(kKE1),'parent',psax,...
        'linestyle','none','marker','o'); 
    kKE2_p = sqrt(ke2ps(f_ind)/bkps(f_ind)) * kBK *rho * c;
    l2 = line(d,real(kKE2),'parent',psax,...
        'linestyle','none','marker','+'); 


    % ******* Compare the methods - This does really well
    line(abs(kKE1),abs(kKE1_p),'parent',compareax,...
        'linestyle','none','marker','o'); 
    line(abs(kKE2),abs(kKE2_p),'parent',compareax,...
        'linestyle','none','marker','+'); 
    
end
axis(fftax,'square')
axis(compareax,'square')
ylims = get(psax,'ylim');
set(psax,'yLim',[0,ylims(2)]);
legend([l1,l2],{'k_{KE1}','k_{KE2}'});

ylabel(fftax,'Imag(k_{KE})')
xlabel(fftax,'Real(k_{KE})')

ylabel(psax,'|(k_{KE})|')
xlabel(psax,'trial #')

ylabel(compareax,'|(k_{KE})| from Integration')
xlabel(compareax,'|(k_{KE})| from Fourier')


%%
freqs = [];
amps = [];
for p = 1:length(params_fft1)
    v = params_fft1{p};
    if ~sum(freqs==v(1))
        freqs(end+1) = v(1);
    end
    if ~sum(amps == v(2))
        amps(end+1) = v(2);
    end
end

kKE1_mat = nan(length(freqs),length(amps));
kKE2_mat = kKE1_mat;

for p = 1:length(params_fft1)
    v = params_fft1{p};
    kKE1_mat(freqs==v(1),amps==v(2)) = v(3);    
    v = params_fft2{p};
    kKE2_mat(freqs==v(1),amps==v(2)) = v(3);
end
    
figure(1)
k1vsamp = subplot(2,1,1);
k1vsfreq = subplot(2,1,2);

figure(2)
k2vsamp = subplot(2,1,1);
k2vsfreq = subplot(2,1,2);

co = get(k1vsamp,'colorOrder');
mo = {'o','+'};

for f = 1:length(freqs)
    % k vs amp
    line(amps(~isnan(kKE1_mat(f,:))),kKE1_mat(f,~isnan(kKE1_mat(f,:))),...
        'parent',k1vsamp,'DisplayName',[num2str(freqs(f)),' Hz'],...
        'color',co(mod(f,size(co,1))+1,:),...
        'marker',mo{ceil(f/size(co,1))},'markerfacecolor',co(mod(f,size(co,1))+1,:),'markeredgecolor',co(mod(f,size(co,1))+1,:),'markersize',3)

    line(amps(~isnan(kKE2_mat(f,:))),kKE2_mat(f,~isnan(kKE1_mat(f,:))),...
        'parent',k2vsamp,'DisplayName',[num2str(freqs(f)),' Hz'],...
        'color',co(mod(f,size(co,1))+1,:),...
        'marker',mo{ceil(f/size(co,1))},'markerfacecolor',co(mod(f,size(co,1))+1,:),'markeredgecolor',co(mod(f,size(co,1))+1,:),'markersize',3)
end
for a = 1:length(amps)
    %k vs freq
    line(freqs(~isnan(kKE1_mat(:,a))),kKE1_mat(~isnan(kKE1_mat(:,a)),a),...
        'parent',k1vsfreq,'DisplayName',[num2str(amps(a)),' V'],...
        'color',co(mod(a,size(co,1))+1,:),...
        'marker',mo{ceil(a/size(co,1))},'markerfacecolor',co(mod(a,size(co,1))+1,:),'markeredgecolor',co(mod(a,size(co,1))+1,:),'markersize',3)

    line(freqs(~isnan(kKE2_mat(:,a))),kKE2_mat(~isnan(kKE2_mat(:,a)),a),...
        'parent',k2vsfreq,'DisplayName',[num2str(amps(a)),' V'],...
        'color',co(mod(a,size(co,1))+1,:),...
        'marker',mo{ceil(a/size(co,1))},'markerfacecolor',co(mod(a,size(co,1))+1,:),'markeredgecolor',co(mod(a,size(co,1))+1,:),'markersize',3)
end
ylims = get(k1vsamp,'ylim');
% set(k1vsamp,'yLim',[0,ylims(2)]);
set(k1vsamp,'yLim',[0,5e-4]);
ylabel(k1vsamp,'k_{KE1}');
xlabel(k1vsamp,'Amp (V)')

ylims = get(k1vsfreq,'ylim');
%set(k1vsfreq,'yLim',[0,ylims(2)]);
set(k1vsfreq,'yLim',[0,5e-4]);
set(k1vsfreq,'xscale','log');
ylabel(k1vsfreq,'k_{KE1}');
xlabel(k1vsfreq,'freq (Hz)')
set(k1vsfreq,'xLim',[40,1200]);

ylims = get(k2vsamp,'ylim');
%set(k2vsamp,'yLim',[0,ylims(2)]);
set(k2vsamp,'yLim',[0,5e-4]);
ylabel(k2vsamp,'k_{KE2}');
xlabel(k2vsamp,'Amp (V)')

ylims = get(k2vsfreq,'ylim');
%set(k2vsfreq,'yLim',[0,ylims(2)]);
set(k2vsfreq,'yLim',[0,5e-4]);
set(k2vsfreq,'xscale','log');
ylabel(k2vsfreq,'k_{KE2}');
xlabel(k2vsfreq,'freq (Hz)')
set(k2vsfreq,'xLim',[40,1200]);

    
figure(3)
