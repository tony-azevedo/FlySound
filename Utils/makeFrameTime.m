function ft = makeFrameTime(trial,varargin)
if nargin>1
    t = varargin{1};
else
    t = makeInTime(trial.params);
end

if isfield(trial,'forceProbeStuff')
    N = length(trial.forceProbeStuff.CoM);
elseif isfield(trial,'legPositions')
    N = length(trial.legPositions.Tibia_Angle);
else
    ft = [];
    return
end
    
h2 = postHocExposure(trial,N);
ft = t(h2.exposure);
