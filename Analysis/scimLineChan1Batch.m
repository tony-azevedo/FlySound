function varargout = scimLineChan1Batch(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('PlotFlag',true,@islogical);
p.addParameter('Channels',[1 2],@isnumeric);
parse(p,varargin{:});

varargout = {[]};

imdir = regexprep(data.name,{'Raw','.mat','Acquisition'},{'Images','','Raw_Data'});
if ~isdir(imdir)
    error('No Camera Input: Exiting %s routine',mfilename);
end
if isempty(p.Results.dFoFfig)
    fig = findobj('tag',mfilename);
else
    fig = p.Results.dFoFfig;
end
if isempty(fig);
    if ~isacqpref('AnalysisFigures') ||~isacqpref('AnalysisFigures',mfilename) % rmacqpref('AnalysisFigures','powerSpectrum')
        proplist = {...
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

button = p.Results.NewROI;

%%  Load the frames from the Image directory
%[filename, pathname] = uigetfile('*.tif', 'Select TIF-file');
imagefiles = dir(fullfile(imdir,[params.protocol '_Image_*']));
if length(imagefiles)==0
    error('No Camera Input: Exiting %s routine',mfilename);
end
i_info = imfinfo(fullfile(imdir,imagefiles(1).name));
num_frame = length(i_info);
chans = regexp(i_info(1).ImageDescription,'state.acq.acquiringChannel\d=1');
num_chan = length(chans);

im = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',1,'Info',i_info);
num_px = size(im);

exp_t = makeLineScanTime(i_info,params);

I = zeros([num_px(:); num_frame; 1]', 'double');  %preallocate 3-D array
%read in .tif files
for frame=1:num_frame
    [I(:,:,frame,1)] = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',frame,'Info',i_info);
end

I = squeeze(I);

%% select ROI 
I_red = I(:,:,1);
I_green = I(:,:,2);

red_pix = mean(I_red,1);
Chan1mean = mean(red_pix);
Chan1sd = std(red_pix);
Chan1TH = Chan1mean+.2*Chan1sd;
I_mask = red_pix;
I_mask(red_pix>Chan1TH) = 1;
I_mask(red_pix<=Chan1TH) = 0;
I_mask = repmat(I_mask,size(I_red,1),1);

roi_temp = getacqpref('quickshowPrefs','scimLineChan1Mask');
if strcmp(button,'Yes')
    
    roifig = figure;
    set(roifig,'position',[680     9   560   988]);
    
    panl = panel(roifig);
    panl.pack('h',{1/3 1/3 1/3})  % response panel, stimulus panel
    
    imshow(I_red,[],'initialmagnification','fit','parent',panl(1).select());%,'DisplayRange',[0 1000]);
    imshow(I_green,[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
    
    imshow(cat(3,I_mask,I_green/max(I_green(:)),I_mask),[],'initialmagnification','fit','parent',panl(3).select());%,'DisplayRange',[0 1000]);
    
    roi_temp = [roi_temp(1),0,roi_temp(3),num_px(1)];
    rectangle('position',roi_temp,'parent',panl(3).select(),'edgecolor',[1 0 0]);
    button = questdlg('Make new ROI?','ROI','No');
    if strcmp(button,'Cancel')
        close(roifig)
        fprintf('Quiting analysis\n');
        return
    end
end
if strcmp(button,'Yes');
    data.ROI = {};
    roi_rect = imrect(panl(3).select());
    roi_temp = wait(roi_rect);
    roi_temp = [roi_temp(1),0,roi_temp(3),num_px(1)];
    setPosition(roi_rect,roi_temp);
    close(roifig)

end

roi_temp(1) = max(1,floor(roi_temp(1)));
roi_temp(2) = max(1,floor(roi_temp(2)));
roi_temp(3) = ceil(roi_temp(3));
roi_temp(4) = ceil(roi_temp(4));

%% Save the trace to the trial
setacqpref('quickshowPrefs','scimLineChan1Mask',roi_temp)

%% Batch process the bunch using the same ROI.

[protocol,dateID,flynum,cellnum,trialnum,D,trialStem,datastructfile] = extractRawIdentifiers(data.name);
prtclData = load(datastructfile);
prtclData = prtclData.data;
blocktrials = findLikeTrials('name',data.name,'datastruct',prtclData,'exclude',{'displacement','freq','amp','step'});

for bt = blocktrials;
    data_block = load(fullfile(D,sprintf(trialStem,bt)));
    scimLineChan1Mask(data_block,data_block.params,'NewROI','No','PlotFlag',false,'dFoFfig',fig,varargin{:});
end

data = load(fullfile(D,sprintf(trialStem,data.params.trial)));

scimLineChan1Mask(data,data.params,'NewROI','No','PlotFlag',true,'dFoFfig',fig,varargin{:});

varargout = {data};




function exp_t = makeLineScanTime(i_info,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.msPerLine=','end');
delta_t = str2double(dscr(strstart+1))/1000;
t = makeInTime(params);
delta_t_ind = find(t==t(1)+delta_t);
exp_t = t(1:delta_t_ind-1:length(t));
try exp_t = exp_t(1:i_info(1).Height);
catch
    warning('Line scan has more lines than time vector');
    exp_t = exp_t(1:min(i_info(1).Height,length(exp_t)));
end

