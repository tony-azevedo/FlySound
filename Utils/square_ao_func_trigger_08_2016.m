%% 02_08_2016 JCT
%% create a square wave function for controlling a 60 micron travel piezo

function square_ao_func_trigger_08_2016(movement, num_cycles, length_on, length_off, cond_sig, framerate, plot_flag)
global nisesh;
micron = 10/60;
amplitude = movement*micron;

total_length = num_cycles*(length_on+length_off)+length_off;%% in ms
frame_on = 1/framerate*nisesh.Rate; %vector length needed per frame

out_1= [zeros(1,length_off/1000*nisesh.Rate)];

for ii =1:num_cycles
    out_1=  [out_1 amplitude*ones(1,length_on/1000*nisesh.Rate) zeros(1,length_off/1000*nisesh.Rate)];
end 

numframes = length(out_1)/frame_on;
idxs = 1:frame_on:length(out_1);
triggerstim = ones(1, length(out_1));
size(idxs)

for ii = 1:length(idxs)
    triggerstim(idxs(ii):(idxs(ii)+10)) = 0;
end
triggerstim(end) = 0;


if plot_flag == 1
f9 = figure(9);clf;set(f9, 'Position', [1100, 650, 500, 500]);hold all;
plot((1:length(out_1))/nisesh.Rate, out_1);
plot((1:length(out_1))/nisesh.Rate, triggerstim);
xlabel('Time');
ylabel('Voltage');
end

% queueOutputData(nisesh,[-out_1' -out_1' out_2']);
queueOutputData(nisesh,[-out_1' -out_1' triggerstim']);
nisesh.startForeground;
end
