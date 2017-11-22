cd B:\Raw_Data\171109\171109_F2_C1

%% AviROI has been run on these trials
% 21-26
%%
trial = load('B:\Raw_Data\171109\171109_F2_C1\EpiFlash2TTrain_Raw_171109_F2_C1_25.mat');
[~,~,~,~,~,D,trialStem] = extractRawIdentifiers(trial.name);

figure; 
ax = subplot(2,1,1); hold on
t = makeInTime(trial.params);
stim = EpiFlashTrainStim(trial.params);
stim = stim/max(stim);

h2 = postHocExposure(trial,length(trial.roitraces));
frametimes = t(h2.exposure);
phi = trial.roitraces/max(trial.roitraces);

plot(t,stim)
plot(frametimes,phi)

order = ax.ColorOrder;

%%

trialnumlist = 21:26;
subplot(2,2,3),hold on
first =1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces));
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%% skootch the exposures

knownSkootch = 3;
batch_skootchExposure_KnownSkootch

%%

trialnumlist = 21:26;
subplot(2,2,4),hold on
first =1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','skootched');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%%
cd B:\Raw_Data\171110\171110_F1_C1

%% AviROI has been run on these trials
% 1-8
%%
trial = load('B:\Raw_Data\171110\171110_F1_C1\EpiFlash2TTrain_Raw_171110_F1_C1_7.mat');
[~,~,~,~,~,D,trialStem] = extractRawIdentifiers(trial.name);

figure; 
ax = subplot(2,1,1); hold on
t = makeInTime(trial.params);
stim = EpiFlashTrainStim(trial.params);
stim = stim/max(stim);

h2 = postHocExposure(trial,length(trial.roitraces));
frametimes = t(h2.exposure);
phi = trial.roitraces/max(trial.roitraces);

plot(t,stim)
plot(frametimes,phi)

order = ax.ColorOrder; order = repmat(order,2,1);

%%

trialnumlist = 1:8;
subplot(2,2,3),hold on
first = 1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','raw');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%% skootch the exposures

% knownSkootch = 1;
% batch_skootchExposure_KnownSkootch

%

trialnumlist = 2;
subplot(2,2,4),hold on
first =1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','skootched');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%%
cd B:\Raw_Data\171110\171121_F0_C0

%% AviROI has been run on these trials
% 2-9
%%
trial = load('B:\Raw_Data\171121\171121_F0_C0\EpiFlash2TTrain_Raw_171121_F0_C0_17.mat');
[~,~,~,~,~,D,trialStem] = extractRawIdentifiers(trial.name);

figure; 
ax = subplot(2,1,1); hold on
t = makeInTime(trial.params);
stim = EpiFlashTrainStim(trial.params);
stim = stim/max(stim);

h2 = postHocExposure(trial,length(trial.roitraces));
frametimes = t(h2.exposure);
phi = trial.roitraces/max(trial.roitraces);

plot(t,stim)
plot(frametimes,phi)

order = ax.ColorOrder; order = repmat(order,2,1);

%%

trialnumlist = 2:9;
subplot(2,2,3),hold on
first = 1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','raw');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%% skootch the exposures

% knownSkootch = 1;
% batch_skootchExposure_KnownSkootch

%

trialnumlist = 2;
subplot(2,2,4),hold on
first =1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','skootched');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%% AviROI has been run on these trials
% 1-8
%%
trial = load('B:\Raw_Data\171121\171121_F0_C0\EpiFlash2TTrain_Raw_171121_F0_C0_17.mat');
[~,~,~,~,~,D,trialStem] = extractRawIdentifiers(trial.name);

figure; 
ax = subplot(2,1,1); hold on
t = makeInTime(trial.params);
stim = EpiFlashTrainStim(trial.params);
stim = stim/max(stim);

h2 = postHocExposure(trial,length(trial.roitraces));
frametimes = t(h2.exposure);
phi = trial.roitraces/max(trial.roitraces);


%%

trialnumlist = [10:11 13:17];
tr_idx = trialnumlist(1);
trial = load(sprintf(trialStem,tr_idx));
plot(t,stim)
plot(frametimes,phi)

order = ax.ColorOrder; order = repmat(order,2,1);


subplot(2,2,3),hold on
first = 1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','raw');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'color',order(tr_idx+1-trialnumlist(1),:));
    end
end

%% skootch the exposures

% knownSkootch = 1;
% batch_skootchExposure_KnownSkootch

%

% trialnumlist = 10;
subplot(2,2,4),hold on
first =1;
for tr_idx = trialnumlist
    trial = load(sprintf(trialStem,tr_idx));

    t = makeInTime(trial.params);
    stim = EpiFlashTrainStim(trial.params);
    stim = stim/max(stim);

    h2 = postHocExposure(trial,length(trial.roitraces),'use','skootched');
    frametimes = t(h2.exposure);
    phi = trial.roitraces/max(trial.roitraces);

    flashes = find(diff(stim)>0)+1;

    for f = 1:length(flashes)
        tw = flashes(f)+(-500:800);
        fw = frametimes>t(tw(1))&frametimes<t(tw(end));
        if first
            plot(t(tw)-t(flashes(f)),stim(tw),'k');
            first=0;
        end
        plot(frametimes(fw)-t(flashes(f)),phi(fw),'.','color',order(tr_idx+1-trialnumlist(1),:));
    end
end