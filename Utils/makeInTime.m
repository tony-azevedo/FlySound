function time = makeInTime(params)
% time = makeTime(params)
if isa(params, 'FlySoundProtocol')
    params = params.params;
end

time = (1:1:params.durSweep*params.sampratein)/params.sampratein;
if isfield(params,'preDurInSec');
    time = time-params.preDurInSec;
end