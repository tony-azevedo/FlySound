%% Piezo Amplitude Correction Script

% deliver 5 sine wave stimulus amplitudes using protocols as I will for the experiment {0.5, 1, 2, 4}.  Establishing only these amps and freqs as possibilities for now

displacement = 0.05*sqrt(2).^(0:6);
freqs = 25 * sqrt(2) .^ (0:10);
displacementOffset = 5;
% displacement = 1;
% freqs = 25 * 2 .^ (2:5);
%displacement = 3;
%freqs = 200;

A = Acquisition; A.setProtocol('PiezoSine','modusOperandi','Cal');
A.protocol.setParams('ramptime',.04,...
    'stimDurInSec',.4,...
    'preDurInSec',0.4,...
    'postDurInSec',0.2,...
    'displacementOffset',displacementOffset)
stem = regexprep(A.getRawFileStem,'\\','\\\');

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
        
        if displacement(i)*d.gain(i,j)+ displacementOffset+d.offset(i,j) >= 10 || ...
                displacementOffset+d.offset(i,j)-displacement(i)*d.gain(i,j) >= 10
            d.amplitude(i,j) = 0;
            d.gaincorrection(i,j) = 1;
            d.offsetcorrection(i,j) = 0;
            d.calibrated = false;
            continue
        end
        
        A.protocol.setParams('freqs',freqs(j),...
            'displacement',displacement(i)*d.gain(i,j),...
            'displacementOffset',displacementOffset+d.offset(i,j));
        start = A.n;
        A.run(3);
        
        trialnums = start:A.n-1;
        trials = zeros(length(trialnums),length(A.protocol.x));
        voltages = zeros(length(trialnums),length(A.protocol.x));
        
        peaks = [];
        troughs = [];
        ps = sprintf('peaks: \t');
        ts = sprintf('troughs: \t');
        figure(3), ax = subplot(2,1,1); delete(get(ax,'children'));
        for n = 1:length(trialnums);
            load(sprintf(stem,trialnums(n)));
            trials(n,:) = sgsmonitor;
            voltages(n,:) = voltage;
            [peaksvec,plocs] = findpeaks(trials(n,0.23*params.sampratein:0.36*params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(params.sampratein/params.freq));
            peaks = [peaks, peaksvec];
            [troughsvec,tlocs] = ...
                findpeaks(-trials(n,0.45*params.sampratein:0.75*params.sampratein),...
                'MINPEAKDISTANCE',...
                floor(.9*p.params.sampratein/p.params.freq));
            troughs = [troughs, -troughsvec];
            ps = sprintf('%s, %g (%g)',ps,mean(peaks),std(peaks));
            ts = sprintf('%s, %g (%g)',ts,mean(troughs),std(troughs));
            plot(sgsmonitor),hold on,
            plot(plocs+0.23*p.params.sampratein,sgsmonitor(plocs+0.23*p.params.sampratein),'or')
            plot(tlocs+0.23*p.params.sampratein,sgsmonitor(tlocs+0.23*p.params.sampratein),'og')
        end
        text(-.15,4.6,sprintf('f: %.0f,d: %.3f, act.: %.3f',...
            freqs(j),displacement(i),(mean(peaks)-mean(troughs))/2));
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
