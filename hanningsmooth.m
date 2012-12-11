function filtsig = hanningsmooth(signal,win);
% Filter signal with a hanning window of width win
% Cuts off ends of convolved signal to align to original signal

win=ceil(win);
smooth_win = hanning(win)/sum(hanning(win));
filtsig = conv(signal,smooth_win);

sigrange = [floor(win/2):ceil(win/2+length(signal)-1)];
filtsig = filtsig(sigrange);

%figure; plot(signal); hold on; plot(filtsig,'r');
