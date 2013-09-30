top = 1000;
bottom = 50;
N = 12;
freqs = logspace(log10(bottom),log10(top),N);

f = 1;

freq = freqs(f);

calibrate_microphone(0,0,200,1,1,1,1,12)

