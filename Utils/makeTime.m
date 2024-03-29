function time = makeTime(params)
% time = makeTime(params)
% see also makeTime makeInTime makeOutTime
if isa(params, 'FlySoundProtocol') || isfield(params, 'params')
    params = params.params;
end

time = (0:1:round(params.durSweep*params.sampratein) - 1)/params.sampratein;
if isfield(params,'preDurInSec');
    time = time-params.preDurInSec;
end
time = time(:);