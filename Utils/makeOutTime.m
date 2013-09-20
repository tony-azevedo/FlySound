function time = makeOutTime(params)
% time = makeTime(params)
% see also makeTime makeInTime makeOutTime
if isa(params, 'FlySoundProtocol') || isfield(params, 'params')
    params = params.params;
end

time = (0:1:params.durSweep*params.samprateout)/params.samprateout;
if isfield(params,'preDurInSec');
    time = time-params.preDurInSec;
end
time = time(:);