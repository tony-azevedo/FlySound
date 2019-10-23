function ft = makeFrameTime2CB2T(trial,varargin)
if nargin>1
    t = varargin{1};
else
    t = makeInTime(trial.params);
end

if isfield(trial,'clustertraces_NBCls')
    h2 = postHocExposure2(trial,max(size(trial.clustertraces_NBCls)));
elseif isfield(trial,'clustertraces')
    h2 = postHocExposure2(trial,max(size(trial.clustertraces)));    
end
ft = t(h2.exposure2);
