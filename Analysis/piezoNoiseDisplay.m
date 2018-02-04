function varargout = piezoNoiseDisplay(data,params,varargin)
% proplist = getacqpref('AnalysisFigures','average');
% rmacqpref('AnalysisFigures','average');

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~isacqpref('AnalysisFigures') ||~isacqpref('AnalysisFigures',mfilename) % rmacqpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[584   563   560   420],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setacqpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getacqpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
figure(fig);
clf;

x = varargin{1};
p = varargin{4};
wind = x>=0 & x<p.params.stimDurInSec;

y_out = p.out.piezocommand-p.params.displacementOffset;
y_out = y_out(wind);

subplot(2,1,1);
[Pxx,f] = pwelch(y_out,p.params.samprateout,[],[],p.params.samprateout);
loglog(f,Pxx,'color','b'); hold on

subplot(2,2,3);
[xcor, lags] = xcorr(y_out);
plot(lags(lags>=-200 & lags<=200)/p.params.samprateout,xcor(lags>=-200 & lags<=200),'b');  hold on

subplot(2,2,4);
plot(y_out(1:1000),'b');  hold on


y_in = data.sgsmonitor-mean(data.sgsmonitor(x>p.params.stimDurInSec));
y_in = y_in(wind);

subplot(2,1,1);
[Pxx,f] = pwelch(y_in,p.params.samprateout,[],[],p.params.samprateout);
loglog(f,Pxx,'color','r'); hold on

subplot(2,2,3);
[xcor, lags] = xcorr(y_in);
plot(lags(lags>=-200 & lags<=200)/p.params.samprateout,xcor(lags>=-200 & lags<=200),'r');  hold on

subplot(2,2,4);
plot(y_in(1:1000),'r');  hold on

