function y = PiezoRampStim(p)

if length(p.displacements) >1
    p.displacements = p.displacement;
end
x = makeInTime(p);
y = x;
y(:) = 0;

ramptime = abs(p.displacement)/p.speed;
stimpnts = round(p.samprateout*p.preDurInSec+1:...
    p.samprateout*(p.preDurInSec+p.stimDurInSec));

ramp = round(ramptime*p.samprateout);
w = window(@triang,2*ramp);
w = [w(1:ramp);...
    ones(length(stimpnts)-length(w),1);...
    w(ramp+1:end)];

y(stimpnts) = w*p.displacement;

