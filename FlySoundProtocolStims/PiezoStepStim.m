function stim = PiezoStepStim(p)

if length(p.displacements) >1
    p.displacements = p.displacement;
end
x = makeInTime(p);
y = x;
y(:) = 0;
y(p.samprateout*(p.preDurInSec)+1: p.samprateout*(p.preDurInSec+p.stimDurInSec)) = 1;

stim = y.*p.displacement;