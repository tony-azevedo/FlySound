function varargout = scimStackPiezoAVI(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('ShowMovies',false,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('BGCorrectImages',true,@islogical);
p.addParameter('Channels',[1 2],@isnumeric);
parse(p,varargin{:});

varargout = {[]};

imdir = regexprep(data.name,{'Raw','.mat','Acquisition'},{'Images','','Raw_Data'});
if ~isdir(imdir)
    error('No Camera Input: Exiting %s routine',mfilename);
end
if ~isfield(data,'sgsmonitor')
    error('No sgsmonitor Input: Exiting %s routine',mfilename);
end
if isempty(p.Results.dFoFfig)
    fig = findobj('tag',mfilename);
else
    fig = p.Results.dFoFfig;
end
if isempty(fig);
    if ~isacqpref('AnalysisFigures') ||~isacqpref('AnalysisFigures',mfilename) % rmacqpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'color',[1 1 1],...
            'tag',mfilename,...
            'Position',[1030 10 560 450],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setacqpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getacqpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end

%%  Load the frames from the Image directory
%[filename, pathname] = uigetfile('*.tif', 'Select TIF-file');
imagefiles = dir(fullfile(imdir,[params.protocol '_Image_*']));
if length(imagefiles)==0
    error('No Camera Input: Exiting %s routine',mfilename);
end
i_info = imfinfo(fullfile(imdir,imagefiles(1).name));
chans = regexp(i_info(1).ImageDescription,'state.acq.acquiringChannel\d=1');
num_chan = length(chans);

num_frame = round(length(i_info)/num_chan);
im = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',1,'Info',i_info);
num_px = size(im);

exp_t = makeScimStackTime(i_info,num_frame,params);

I0 = zeros([num_px(:); num_frame; num_chan]', 'double');  %preallocate 3-D array
%read in .tif files
tic; fprintf('Loading: '); 
for frame=1:num_frame
    for chan = 1:num_chan
        [I0(:,:,frame,chan)] = imread(fullfile(imdir,imagefiles(1).name),'tiff',...
            'Index',(2*(frame-1)+chan),'Info',i_info);
    end
end
toc


%% Do motion correction here

I = I0;
ref_frame = I(:,:,1,2);
ref_FFT = fft2(ref_frame);
for frame=2:num_frame
    [~, Greg] = dftregistration(ref_FFT,fft2(I(:,:,frame,2)),1);
    I(:,:,frame,2) = real(ifft2(Greg));
end

I = squeeze(I(:,:,:,2));

%% Subtract Background

% I_bg = mean(I(:,:,exp_t<=0),3);
% I_bg = repmat(I_bg,1,1,num_frame);
% I_rel = (I-I_bg)./I_bg;


I0_bg_baseline = mean(I0(:,:,exp_t<=0),3);

%% Filter
% H = fspecial('gaussian',4,.5);
% If = imfilter(I,H,'replicate');
% 
% sigma = 1.5;
% fsize = 3;
% x = linspace(-fsize / 2, fsize / 2, fsize);
% gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
% gaussFilter = gaussFilter / sum (gaussFilter); 
% 
% for i=1:size(If,1)
%   for j=1:size(If,2)
%     If(i,j,:) = conv(squeeze(If(i,j,:)), gaussFilter, 'same');
%   end
% end
% I_bg_baseline = mean(If(:,:,exp_t<=0),3);
% I_bg = repmat(I_bg_baseline,1,1,num_frame);
% I_rel = (If-I_bg)./I_bg;
% 
% I = I_rel;

%%
I_norm = ...
     (I - min(I0_bg_baseline(:)))/...
     (max(I0_bg_baseline(:)) - min(I0_bg_baseline(:)));

%% Normalize the raw video
I0_norm = ...
    (I0 - min(I0_bg_baseline(:)))/...
    (max(I0_bg_baseline(:)) - min(I0_bg_baseline(:)));

%% Plot the figure for video making
panl = panel(fig);
panl.pack('v',{1/2 1/2})  % response panel, stimulus panel
panl(1).pack('h',{1/2 1/2})  % response panel, stimulus panel
panl.margin = [18 16 2 10];
panl.fontname = 'Arial';
panl(1).marginbottom = 2;
panl(2).margintop = 2;

set(panl(1,1).select(), 'nextplot','replacechildren', 'Visible','off');
set(panl(1,2).select(), 'nextplot','replacechildren', 'Visible','off');
set(panl(2).select(), 'nextplot','replacechildren');

x = ((1:data.params.sampratein*data.params.durSweep) - data.params.preDurInSec*data.params.sampratein)/data.params.sampratein;
sgsmonitor = data.sgsmonitor(1:length(x));
ax2 = panl(2).select();
xlim(panl(2).select(),[x(1), x(end)]);
ylim(panl(2).select(),[min(sgsmonitor) max(sgsmonitor)]);
ylabel(ax2,'SGS monitor (V)'); %xlim([0 max(t)]);
box(ax2,'off'); 
xlabel(ax2,'Time (s)'); %xlim([0 max(t)]);

movieLocation = regexprep(data.name,...
    {'\\','Raw','.mat','Acquisition'},{'\\','Images','','Raw_Data'});
[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);

vidObj = VideoWriter([movieLocation '\' protocol '_' mfilename '_' trialnum],'MPEG-4');
set(vidObj,'FrameRate',round(1/diff(exp_t([1 2]))))

open(vidObj);

% Create an animation.
% set(gca,'nextplot','replacechildren');
for frame=1:num_frame

    imshow(I0_norm(:,:,frame,2),[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
    
    imshow(I_norm(:,:,frame),[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);
    colormap(panl(1,2).select(),'hot');
    
    l = line(x(x<exp_t(frame)),sgsmonitor(x<exp_t(frame)),'parent',panl(2).select(),'color',[0 0 1]);
    
    figFrame = getframe(fig);
    writeVideo(vidObj,figFrame);
    delete(l);

end
close(vidObj);

% Green is always channel 2 for scim


%% Save the trace to the trial
tic; fprintf('Saving: '); 
data.exposureTimes = exp_t;
save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');
toc

varargout = {data};

function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
exp_t = exp_t(1:num_frame);