function stim = EpiFlashTrainStim(p)

x = makeInTime(p);
y = x;
y(:) = 0;

stimpnts = round(p.samprateout*p.preDurInSec+1:...
    p.samprateout*(p.preDurInSec+p.stimDurInSec));

y(stimpnts) = 1;


flash = zeros(p.cycleDurInSec*p.samprateout,1);
flash(1:p.flashDurInSec*p.samprateout) = 1;
flashes = repmat(flash,1,p.nrepeats);
flashes = flashes(:);

y(stimpnts) = flashes;

stim = y.*p.ndf + p.background;
