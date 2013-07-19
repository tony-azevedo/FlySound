%% Piezo Amplitude Correction Script

% deliver 5 sine wave stimulus amplitudes using protocols as I will for the experiment {0.5, 1, 2, 4}.  Establishing only these amps and freqs as possibilities for now

displacement = 0.5*sqrt(2).^(0:6);
freqs = 25 * sqrt(2) .^ (0:10);
displacementOffset = 5;
% displacement = 1;
% freqs = 25 * 2 .^ (2:5);
displacement = 3;
freqs = 200;

p = PiezoSine;
p.setParams('ramptime',.02,...
    'stimDurInSec',.2,...
    'preDurInSec',0.2,...
    'postDurInSec',0.1,...
    'displacementOffset',displacementOffset)
stem = regexprep(p.getRawFileStem,'\\','\\\');

d.freqs = freqs;
d.displacement = displacement;

d.amplitude = zeros(length(displacement),length(freqs));
d.gain = ones(length(displacement),length(freqs));
d.gaincorrection = d.gain;
d.offset = d.amplitude;
d.offsetcorrection = d.amplitude;

d.gainarchive={};
d.offsetarchive={};
%% Run this until the correction is stable and the amplitude is accurate

for i = 1:length(displacement)
    for j = 1:length(freqs)
        
        if displacement(i)*d.gain(i,j) >=5
            d.amplitude(i,j) = 0;
            d.gaincorrection(i,j) = 1;
            d.offsetcorrection(i,j) = 0;
            continue
        end
        
        p.setParams('freqs',freqs(j),...
            'displacement',displacement(i)*d.gain(i,j),...
            'displacementOffset',displacementOffset+d.offset(i,j));
        start = p.n;
        p.run(100);
        
        trialnums = start:p.n-1;
        trials = zeros(length(trialnums),length(p.x));
        voltages = zeros(length(trialnums),length(p.x));
        load(regexprep(p.getDataFileName,'\\','\\\'))
        
        peaks = [];
        troughs = [];
        ps = sprintf('peaks: \t');
        ts = sprintf('troughs: \t');
        for n = 1:length(trialnums);
            load(sprintf(stem,trialnums(n)));
            trials(n,:) = sgsmonitor;
            voltages(n,:) = voltage;
            [peaksvec,plocs] = findpeaks(trials(n,0.23*p.params.sampratein:0.36*p.params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(p.params.sampratein/p.params.freq));
            peaks = [peaks, peaksvec];
            [troughsvec,tlocs] = ...
                findpeaks(-trials(n,0.23*p.params.sampratein:0.36*p.params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(.9*p.params.sampratein/p.params.freq));
            troughs = [troughs, -troughsvec];
            ps = sprintf('%s, %g (%g)',ps,mean(peaks),std(peaks));
            ts = sprintf('%s, %g (%g)',ts,mean(troughs),std(troughs));
            figure(3), subplot(2,1,1);
%             plot(sgsmonitor),hold on, 
%             plot(plocs+0.23*p.params.sampratein,sgsmonitor(plocs+0.23*p.params.sampratein),'or')
%             plot(tlocs+0.23*p.params.sampratein,sgsmonitor(tlocs+0.23*p.params.sampratein),'og')
        end
        fprintf('\n%s\n%s\n',ps,ts);
        figure(3), subplot(2,1,2);plot(mean(voltages));
        
        resid = trials-repmat(mean(trials),length(trialnums),1);
        %sgsamp = (mean(max(trials,[],2))-mean(min(trials,[],2)))/2;
        sgsamp = (mean(peaks)-mean(troughs))/2;
        d.amplitude(i,j) = sgsamp;
        d.gaincorrection(i,j) = displacement(i)/d.amplitude(i,j);
        d.offsetcorrection(i,j) = displacementOffset - mean(mean(trials(:,400:2400)));

    end
end

%%
save(sprintf(...
    'C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection%s',...
    datestr(date,'yymmdd')),'d'); d.gainarchive = [d.gainarchive {d.gain}];

d.offsetarchive = [d.offsetarchive {d.offset}];
d.gain = d.gain.*d.gaincorrection;
d.offset = d.offset+d.offsetcorrection;

%%

% store as ?? for future indexing for correction factor (put this under
% version control)


% rerun, using correction factors, measure error
d.error = zeros(size(d.correction));
for i = 1:length(displacement)
    for j = 1:length(freqs)
        
        if displacement(i)*d.correction(i,j) >=5
            d.error(i,j) = Inf;
            continue
        end
        p.setParams('freqs',freqs(j),...
            'displacement',displacement(i)*d.correction(i,j),...
            'displacementOffset',5+d.offset(i,j));
        start = p.n;
        p.run(5);
        p.setParams('displacement',displacement(i),...
            'displacementOffset',5);
        stim = p.generateStimulus;

        % load the 5 trials, compute variance
        trialnums = start:p.n-1;
        trials = zeros(length(trialnums),length(p.x));
        load(regexprep(p.getDataFileName,'\\','\\\'))
        
        for n = 1:length(trialnums);
            load(sprintf(regexprep(stem,'\\','\\\'),trialnums(n)));
            trials(n,:) = sgsmonitor;
        end
        
        resid = trials-repmat(stim',length(trialnums),1);
        d.error(i,j) = sqrt(mean(mean((resid.^2))));
        sgsamp = (mean(max(trials,[],2))-mean(min(trials,[],2)))/2;
        d.correctedamplitude(i,j) = sgsamp;
        d.correctedcorrection(i,j) = displacement(i)/d.correctedamplitude(i,j);
        d.correctedoffset(i,j) = mean(stim(1:400)' - mean(trials(:,1:400)));
    end
end
d.correctionarchive = [d.correctionarchive {d.correction}];
d.correction = d.correctedcorrection;
save('C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection','d'); 


% for fun, try to run the chirp