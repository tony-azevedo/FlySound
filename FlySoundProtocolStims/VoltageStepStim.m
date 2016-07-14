function stim = VoltageStepStim(p)

x = makeInTime(p);
stim = x;
stim(:) = 0;

stim(x>=0&x<p.stimDurInSec) = 1;

stim = stim*p.step;