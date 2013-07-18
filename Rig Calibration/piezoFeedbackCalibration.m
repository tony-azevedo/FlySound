%% Piezo Amplitude Correction Script

% deliver 5 sine wave stimulus amplitudes using protocols as I will for the experiment {0.5, 1, 2, 4}.  Establishing only these amps and freqs as possibilities for now

displacement = 0.5*sqrt(2).^(0:6);
freqs = 25 * sqrt(2) .^ (0:10);
% displacement = 1;
% freqs = 25 * 2 .^ (2:5);

p = PiezoSine;
p.setParams('ramptime',.02,'stimDurInSec',.2,'preDurInSec',0.2,'postDurInSec',0.1,'displacementOffset',5)
stem = p.getRawFileStem;

d.amplitude = zeros(length(displacement),length(freqs));
d.correction = zeros(length(displacement),length(freqs));
d.freqs = freqs;
d.displacement = displacement;
d.offset = d.amplitude;
d.correctionarchive={};

for i = 1:length(displacement)
    for j = 1:length(freqs)
        p.setParams('displacement',displacement(i),'freqs',freqs(j),'displacementOffset',5);
        start = p.n;
        stim = p.generateStimulus;
        p.run(5);
        % load the 5 trials, compute variance
        trialnums = start:p.n-1;
        trials = zeros(length(trialnums),length(p.x));
        load(regexprep(p.getDataFileName,'\\','\\\'))
        
        peaks = [];
        troughs = [];
        for n = 1:length(trialnums);
            load(sprintf(regexprep(stem,'\\','\\\'),trialnums(n)));
            trials(n,:) = sgsmonitor;
            peaks = [peaks, ...
                findpeaks(trials(1,0.22*p.params.sampratein:0.36*p.params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(p.params.sampratein/p.params.freq))];
            troughs = [troughs, ...
                -findpeaks(-trials(1,0.22*p.params.sampratein:0.36*p.params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(p.params.sampratein/p.params.freq))];
        end
        
        resid = trials-repmat(mean(trials),length(trialnums),1);
        error = sqrt(mean(mean((resid.^2))));
        %sgsamp = (mean(max(trials,[],2))-mean(min(trials,[],2)))/2;
        sgsamp = (mean(peaks)-mean(troughs))/2;
        d.amplitude(i,j) = sgsamp;
        d.correction(i,j) = displacement(i)/d.amplitude(i,j);
        d.offset(i,j) = mean(stim(1:400)' - mean(trials(:,1:400)));
    end
end
% store as ?? for future indexing for correction factor (put this under
% version control)
save('C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection','d'); 

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