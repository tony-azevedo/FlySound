% Mic Calibration script, w/o Ovation Bullshit

cd('C:\Users\Anthony Azevedo\Raw_Data\27-sep-2013\27-Sep-2013_Mic1_E1');

%% reject any trials that go above the rails
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

%% Create a new data

%% Analysis
datafilename = dir('Calibration Parameters*');
data = load(datafilename(1).name); data = data.data; clear datafilename

% Bring in all trial reps
% - how many trials?
for d = 1:length(data)
    repsfiles = dir(sprintf('RawMicCal_27-Sep-2013_Mic1_E1_%d_Rep*',data(d).trial));
    trial = load(repsfiles(1).name);
    win = max(.01*data(d).freq,2);
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

    BK_voltage = BK_voltage - mean(BK_voltage);
    KE1_voltage = KE1_voltage - mean(KE1_voltage);
    KE2_voltage = KE2_voltage - mean(KE2_voltage);

    % Calulate fourier components
    f = data(d).fs_in/length(BK_voltage)*[0:length(BK_voltage)/2]; f = [f, fliplr(f(2:end-1))];
    bkfft = fft(BK_voltage);
    ke1fft = fft(KE1_voltage);
    ke2fft = fft(KE2_voltage);

    bkps = bkfft.*conj(bkfft);
    ke1ps = bkfft.*conj(bkfft);
    ke2ps = bkfft.*conj(bkfft);

    % find the power peak
    [bk_pow_peak,ind] = max(bkps(...
        (1:length(bkps) < length(bkps)/2) ...
        & f>data(d).freq-win...
        & f<data(d).freq+win));

    f_ind = sum((1:length(f) < length(f)/2) & f<=data(d).freq-win)+ind;
    f_max = f(f_ind);
    
    % Store the values
        
end

