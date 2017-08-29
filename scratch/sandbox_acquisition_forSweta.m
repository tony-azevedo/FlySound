sampratein = 50000;
samprateout = 50000;

stimonset = 2;                                  % time before stim on (seconds)
stimdur = 1;
stimpost = 7;                                  % time after stim offset (seconds)
dur = stimonset+stimdur+stimpost;

stim_on_samp = floor(stimonset*samprateout)+1;
stim_off_samp = floor(stimonset*samprateout)+(samprateout*stimdur);

nsampout = stim_off_samp+floor(stimpost*samprateout);
nsampin = ceil(nsampout/samprateout*sampratein);

stim = zeros(nsampout,1);
stim(stim_on_samp:stim_off_samp) = 1; %stimulus

framerate = 32;
frametime = 1/25;
Nframes = floor(dur/frametime);
triggerstim = stim*0;
idxs = ((1:Nframes)-1)*(frametime*samprateout) + 1;
triggerstim(idxs) = 1;
triggerstim(idxs(2)) = 0;
triggerstim(idxs(3)) = 0;

Nframes = sum(triggerstim);

stim = stim+triggerstim;


%% Other
s = daq.createSession('ni');
s.addAnalogInputChannel('Dev1',0, 'Voltage');
s.addDigitalChannel('Dev1','Port0/Line0','InputOnly');
s.addAnalogOutputChannel('Dev1',[0], 'Voltage');
s.addDigitalChannel('Dev1', 'Port0/Line2', 'OutputOnly');
s.Rate = samprateout;

s.queueOutputData([stim(:) triggerstim(:)]);
in = s.startForeground;
