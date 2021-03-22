function itime = makeInterTime(trial)
% time = makeTime(params)
% see also makeTime makeInTime makeOutTime

params = trial.params;
time = (round(params.durSweep*params.sampratein) -1)/params.sampratein;
if isfield(params,'preDurInSec')
    time = time-params.preDurInSec;
end
itime(:,1) = (0:1:length(trial.intertrial.arduino_output) -1)/params.sampratein + time;


