%% Piezo Amplitude Correction Script

% deliver 5 sine wave stimulus amplitudes using protocols as I will for the experiment {0.5, 1, 2, 4}.  Establishing only these amps and freqs as possibilities for now

displacements = 0.05*sqrt(2).^(0:6);
freqs = 25 * sqrt(2) .^ (0:10);
displacementOffset = 5;
% displacement = 1;
% freqs = 25 * 2 .^ (2:5);
%displacement = 3;
%freqs = 200;

A = Acquisition; 
A.setProtocol('PiezoSine','modusOperandi','Cal');
A.protocol.setParams('ramptime',.04,...
    'stimDurInSec',.4,...
    'preDurInSec',0.4,...
    'postDurInSec',0.2,...
    'displacements',displacements(1),...
    'freqs',freqs(1),...
    'displacement',displacements(1),...
    'freq',freqs(1),...
    'displacementOffset',displacementOffset)
stem = regexprep(A.getRawFileStem,'\\','\\\');

d.freqs = freqs;
d.displacement = displacements;

d.amplitude = zeros(length(displacements),length(freqs));
d.gain = ones(length(displacements),length(freqs));
d.gaincorrection = d.gain;
d.offset = d.amplitude;
d.offsetcorrection = d.amplitude;

d.gainarchive={};
d.offsetarchive={};

%% Run this until the correction is stable and the amplitude is accurate

for i = 1:length(displacements)
    for j = 1:length(freqs)
        
        if displacements(i)*d.gain(i,j)+ displacementOffset+d.offset(i,j) >= 10 || ...
                displacementOffset+d.offset(i,j)-displacements(i)*d.gain(i,j) >= 10
            d.amplitude(i,j) = 0;
            d.gaincorrection(i,j) = 1;
            d.offsetcorrection(i,j) = 0;
            d.calibrated = false;
            continue
        end
        
        A.protocol.setParams('freq',freqs(j),...
            'freqs',freqs(j),...
            'displacement',displacements(i)*d.gain(i,j),...
            'displacements',displacements(i)*d.gain(i,j),...
            'displacementOffset',displacementOffset+d.offset(i,j));
        start = A.n;
        A.run(3);
        
        trialnums = start:A.n-1;
        trials = zeros(length(trialnums),length(A.protocol.x));
        voltages = zeros(length(trialnums),length(A.protocol.x));
        
        searchind = A.protocol.params.preDurInSec+...
            [A.protocol.params.ramptime+.01 ...
            A.protocol.params.stimDurInSec-A.protocol.params.ramptime-0.01];
        peaks = []; 
        troughs = [];
        ps = sprintf('peaks: \t');
        ts = sprintf('troughs: \t');
        figure(3), ax = subplot(2,1,1); delete(get(ax,'children'));
        for n = 1:length(trialnums);
            load(sprintf(stem,trialnums(n)));
            trials(n,:) = sgsmonitor;
            voltages(n,:) = voltage;
            [peaksvec,plocs] = findpeaks(trials(n,...
                searchind(1)*params.sampratein:searchind(2)*params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(params.sampratein/params.freq));
            peaks = [peaks, peaksvec];
            [troughsvec,tlocs] = ...
                findpeaks(-trials(n,...
                searchind(1)*params.sampratein:searchind(2)*params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(.9*params.sampratein/params.freq));
            troughs = [troughs, -troughsvec];
            ps = sprintf('%s, %g (%g)',ps,mean(peaks),std(peaks));
            ts = sprintf('%s, %g (%g)',ts,mean(troughs),std(troughs));
            plot(sgsmonitor),hold on,
            plot(plocs+searchind(1)*params.sampratein,sgsmonitor(plocs+searchind(1)*params.sampratein),'or')
            plot(tlocs+searchind(1)*params.sampratein,sgsmonitor(tlocs+searchind(1)*params.sampratein),'og')
        end
        text(.001,4.8,sprintf('f: %.0f,d: %.3f, act.: %.3f',...
            freqs(j),displacements(i),(mean(peaks)-mean(troughs))/2));
        fprintf('\n%s\n%s\n',ps,ts);
        figure(3), subplot(2,1,2);plot(mean(voltages));
        
        resid = trials-repmat(mean(trials),length(trialnums),1);
        %sgsamp = (mean(max(trials,[],2))-mean(min(trials,[],2)))/2;
        sgsamp = (mean(peaks)-mean(troughs))/2;
        d.amplitude(i,j) = sgsamp;
        d.gaincorrection(i,j) = displacements(i)/d.amplitude(i,j);
        d.offsetcorrection(i,j) = displacementOffset - mean(mean(trials(:,400:2400)));

    end
end
beep
%%
save(sprintf(...
    regexprep(...
    'C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection%s',...
    '\\','\\\'),...
    datestr(date,'yymmdd')),'d'); 
%%
d.gainarchive = [d.gainarchive {d.gain}];
d.offsetarchive = [d.offsetarchive {d.offset}];
d.gain = d.gain.*d.gaincorrection;
d.offset = d.offset+d.offsetcorrection;
disp('Correction Complete')
%% If you fuck up!
d2 = load(sprintf(...
    regexprep(...
    'C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection%s',...
    '\\','\\\'),...
    datestr(date,'yymmdd'))); 
