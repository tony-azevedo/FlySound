function stim = PiezoSineStim(p)

x = makeInTime(p);
y = x;
stim = sin(2*pi*p.freq*x);
y(:) = 0;

stimpnts = round(p.samprateout*p.preDurInSec+1:...
    p.samprateout*(p.preDurInSec+p.stimDurInSec));

w = window(@triang,2*p.ramptime*p.samprateout);
w = [w(1:p.ramptime*p.samprateout);...
    ones(length(stimpnts)-length(w),1);...
    w(p.ramptime*p.samprateout+1:end)];

y(stimpnts) = w;

stim = stim.*y.*p.displacement;