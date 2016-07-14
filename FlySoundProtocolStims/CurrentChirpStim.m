function stim = CurrentChirpStim(p)

if length(p.amps) >1
    p.amps = p.amp;
end
x = makeInTime(p);
y = x;
y(:) = 0;

stimpnts = round(p.samprateout*p.preDurInSec+1:...
    p.samprateout*(p.preDurInSec+p.stimDurInSec));

standardstim = chirp(x(stimpnts),p.freqStart,p.stimDurInSec,p.freqEnd);

w = window(@triang,2*p.ramptime*p.samprateout);
w = [w(1:p.ramptime*p.samprateout);...
    ones(length(stimpnts)-length(w),1);...
    w(p.ramptime*p.samprateout+1:end)];

y(stimpnts) = w.*standardstim;
stim = y.*p.amp;
