function [y,x] = VoltageCommandStim(p)

fn = ['C:\Users\tony\Code\FlySound\CommandWaves\',...
    p.stimulusName];


[stim,p.samprateout] = audioread([fn '.wav']);
p.stimDurInSec = length(stim)/p.samprateout;

p.durSweep = p.stimDurInSec+...
    p.preDurInSec + ...
    p.postDurInSec;

x = makeTime(p);
x = x(:);
y = x;
y(:) = 0;

stimpnts = round(p.samprateout*p.preDurInSec+1:...
    p.samprateout*(p.preDurInSec+p.stimDurInSec));

y(stimpnts) = stim;
