function ft = makeFrameTime(trial,varargin)
if nargin>1
    t = varargin{1};
else
    t = makeInTime(trial.params);
end

h2 = postHocExposure(trial,length(trial.forceProbeStuff.CoM));
ft = t(h2.exposure);
