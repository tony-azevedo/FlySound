function stim = EpiFlashStim(p)

x = makeInTime(p);
y = x;
y(:) = 0;

stimpnts = round(p.samprateout*p.preDurInSec+1:...
    p.samprateout*(p.preDurInSec+p.stimDurInSec));

y(stimpnts) = 1;

stim = y.*p.ndf + p.background;