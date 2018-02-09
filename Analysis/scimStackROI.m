function varargout = scimStackROI(data,params,varargin)
% scimStackROIBatch(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('MakeMovie',false,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('Channels',[1 2],@isnumeric);
p.addParameter('PlotFlag',true,@islogical);
p.addParameter('Masks',{},@iscell);

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
chans = regexp(i_info(1).ImageDescription,'state.acq.acquiringChannel\d=1');
num_chan = length(chans);

num_frame = round(length(i_info)/num_chan);
im = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',1,'Info',i_info);
num_px = size(im);

exp_t = makeScimStackTime(i_info,num_frame,params);

I0 = zeros([num_px(:); num_frame; num_chan]', 'double');  %preallocate 3-D array
%read in .tif files
[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
fprintf([protocol '_' dateID '_' flynum '_' cellnum '_' trialnum '\n'])
tic; fprintf('Loading: '); 
for frame=1:num_frame
    for chan = 1:num_chan
        [I0(:,:,frame,chan)] = imread(fullfile(imdir,imagefiles(1).name),'tiff',...
            'Index',(2*(frame-1)+chan),'Info',i_info);
    end
end
toc

%% Spatial filter frames here
% gauss_filter = fspecial('gaussian', [3 3], 1.5);
% I_processed = I0;
% for ch_ind = 1:num_chan
%     for fr_ind = 1:num_frame
%         I_processed(:,:,fr_ind,ch_ind) = imfilter(I0(:,:,fr_ind,ch_ind), gauss_filter, 'replicate');
%     end
% end
% 
% I0 = I_processed;

%% Do motion correction here

I = I0;
if p.Results.MotionCorrection
    ref_frame = I(:,:,1,2);
    ref_FFT = fft2(ref_frame);
    for frame=2:num_frame
        [~, Greg] = dftregistration(ref_FFT,fft2(I(:,:,frame,2)),1);
        I(:,:,frame,2) = real(ifft2(Greg));
    end
end

if 0
    I_processed = I;
    
    % Gaussian Smoothing across frames
    %     sigma = 4;
    %     fsize = size(I_processed,3);
    %     x = linspace(-fsize+1,fsize,2*fsize);
    %     gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
    %     gaussFilter = gaussFilter / sum (gaussFilter);
    %
    %     for i=1:size(I_processed,1)
    %         for j=1:size(I_processed,2)
    %             I_temp = squeeze(I_processed(i,j,:,2));
    %             nel = length(I_temp);
    %             I_temp = [I_temp; flipud(I_temp(end-20:end))];
    %             I_temp = conv(I_temp, gaussFilter, 'same');
    %             I_processed(i,j,:,2) = I_temp(1:nel);
    %         end
    %     end
    
    % simple smoothing across frames
    for frame=2:2:num_frame
        I_processed(:,:,frame/2,2) = mean(I(:,:,frame-[1 0],2),3);
    end
    I_processed = I_processed(:,:,1:frame/2,2);

    curdir = pwd;
    cd(imdir);
    
    outputFileName = ['Scim_movCor_' imagefiles(1).name];
    if exist(outputFileName,'file')
        delete(outputFileName);
    end
    
    % make tif stacks of dff and maximum intensity
    for frame = 1:size(I_processed,3)
        if frame ==1
            t = Tiff(outputFileName, 'w');
            tagstruct.ImageLength = size(I,1);
            tagstruct.ImageWidth = size(I,2);
            tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
            tagstruct.BitsPerSample = 16;
            tagstruct.SamplesPerPixel = 1;
            tagstruct.RowsPerStrip = 16;
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.Software = 'MATLAB';
            t.setTag(tagstruct);
            % t.write(uint16(I_processed(:, :, frame,2)));
            t.write(uint16(I_processed(:, :, frame)));
            t.close();
        else
            t = Tiff(outputFileName, 'a');
            tagstruct.ImageLength = size(I,1);
            tagstruct.ImageWidth = size(I,2);
            tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
            tagstruct.BitsPerSample = 16;
            tagstruct.SamplesPerPixel = 1;
            tagstruct.RowsPerStrip = 16;
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.Software = 'MATLAB';
            t.setTag(tagstruct);
            % t.write(uint16(I_processed(:, :, frame,2)));
            t.write(uint16(I_processed(:, :, frame)));
            t.close();
        end    
    end
    cd(curdir);

end

% %% Filter over frames here
% I_processed = I;
% 
% sigma = 1;
% fsize = size(I_processed,3);
% x = linspace(-fsize+1,fsize,2*fsize);
% gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
% gaussFilter = gaussFilter / sum (gaussFilter); 
% 
% for i=1:size(I_processed,1)
%     for j=1:size(I_processed,2)
%         I_temp = squeeze(I_processed(i,j,:,2));
%         nel = length(I_temp);
%         I_temp = [I_temp flipud(I_temp(end-20:end))];
%         I_temp = conv(I_temp, gaussFilter, 'same');
%         I_processed(i,j,:,2) = I_temp(1:nel);
%     end
% end
% 
% figure
% subplot(1,1,1), hold on
% 
% plot(pixel_1_initial,'b')
% plot(squeeze(I(32,32,:,2)),'r')
% plot(squeeze(I_processed(32,32,:,2)),'k','Linewidth',1)
% 
% plot(pixel_2_initial,'color',[.8 .8 1])
% plot(squeeze(I(1,1,:,2)),'color',[1 .8 .8])
% plot(squeeze(I_processed(1,1,:,2)),'color',[.8 .8 .8],'Linewidth',1)
% pause

%I = I_processed;

%% select ROI 
I_green = squeeze(nanmean(I(:,:,:,2),3));
I_red = squeeze(nanmean(I(:,:,:,1),3));
temp.ROI = getacqpref('quickshowPrefs','roiScimStackROI');
if ~isfield(data,'ROI')
    data.ROI = temp.ROI;
end
Masks = {};
if strcmp(button,'Yes');
    roifig = figure;
    set(roifig,'position',[680   361   646   646]);
    
    panl = panel(roifig);
    panl.pack('v',{1/4 3/4})  % response panel, stimulus panel
    panl(1).pack('h',{1/2 2/2})  % response panel, stimulus panel
    panl(1).margin = [2 2 2 2];

    imshow(I_red,[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
    imshow(I_green,[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);
    
    imshow(cat(3,I_red/max(I_green(:)),I_green/max(I_green(:)),I_red/max(I_green(:))),[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
    title('Draw ROI, close figure when done')
    roidrawax = panl(2).select();
    
    for roi_ind = 1:length(data.ROI)
        line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',roidrawax,'color',[1 0 0]);
    end 
    button = questdlg('Make new ROI?','ROI','No');
    if strcmp(button,'No')
        for roi_ind = 1:length(data.ROI)
            tic; fprintf('Drawing impoly: ');
            roihand = impoly(roidrawax,data.ROI{roi_ind});
            toc
            Masks{roi_ind} = createMask(roihand);
        end
        %close(roifig)
    end
    if strcmp(button,'Cancel')
        close(roifig)
        fprintf('Quiting analysis\n');
        return
    end
end
if strcmp(button,'Yes');
    data.ROI = {};
    roihand = imfreehand(roidrawax,'Closed',1);
    roi_temp = wait(roihand);
    data.ROI{1} = roi_temp;
    Masks{1} = createMask(roihand);
    while ishandle(roifig) && sum(roi_temp(3:end)>2)
        roihand = imfreehand(roidrawax,'Closed',1);
        roi_temp = wait(roihand);
        if size(roi_temp,1)<=2
            break
        end
        data.ROI{end+1} = roi_temp;
        Masks{end+1} = createMask(roihand);

    end
    %close(roifig);
    toc, fprintf('Closing');
    temp.ROI = data.ROI;
    setacqpref('quickshowPrefs','roiScimStackROI',temp.ROI)
end
if isempty(Masks)
    try Masks = p.Results.Masks;
    catch
        error('There is no mask with which to choose an ROI');
    end
end


%% Calculate across ROIs 
tic; fprintf('Calculating: ');
I_traces = nan(num_frame,num_chan,length(data.ROI));
for roi_ind = 1:length(data.ROI)
    I_masked = I;
    mask = Masks{roi_ind};
    
    I_masked(~repmat(mask,[1 1 num_frame num_chan]))=nan;
    I_trace = squeeze(nanmean(nanmean(I_masked,2),1));
    I_traces(:,:,roi_ind) = I_trace;
end
toc

%% temporal Filter over frames here
I_processed = I_traces;

sigma = 6;
fsize = size(I_processed,3);
x = linspace(-fsize+1,fsize,2*fsize);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); 

for i=1:size(I_processed,2)
    for j=1:size(I_processed,3)
        I_temp = squeeze(I_processed(:,i,j));
        nel = length(I_temp);
        I_temp = [I_temp; flipud(I_temp(end-20:end))];
        I_temp = conv(I_temp, gaussFilter, 'same');
        I_processed(:,i,j) = I_temp(1:nel);
    end
end

I_traces = I_processed;

%% Save the trace to the trial
tic; fprintf('Saving: '); 
data.roiScimStackTrace = I_traces;
data.exposureTimes = exp_t;

% if isfield(data,'lineScanChan1Mask')
% data = rmfield(data,'lineScanChan1Mask')
% end
% if isfield(data,'scimStackTrace')
% data = rmfield(data,'scimStackTrace')
% end


save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');
toc

varargout = {data};

%% plotting traces
if p.Results.PlotFlag

    figure(fig);
    set(fig,'color',[1 1 1])
    panl = panel(fig);
    
    panl.pack('v',{1/2 1/2})  % response panel, stimulus panel
    panl.margin = [18 16 2 2];
    panl.fontname = 'Arial';
    panl(1).marginbottom = 2;
    panl(2).margintop = 2;
    panl(1).pack('h',{1/2 1/2})
    
    set(panl(1,1).select(), 'nextplot','replacechildren', 'Visible','off');
    set(panl(1,2).select(), 'nextplot','replacechildren', 'Visible','off');
    set(panl(2).select(), 'nextplot','replacechildren');
    
    red_roi_ax = panl(1,1).select();
    green_roi_ax = panl(1,2).select();
    absolute_ax = panl(2).select();
    
    [protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
    panl.title([protocol '\_' dateID '\_' flynum '\_' cellnum '\_' trialnum])
    
    % ROI
    imshow(I_green,[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);
    imshow(I_red,[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
    colors = [0 0 1; 0 1 0];
    
    for roi_ind = 1:length(data.ROI)
        line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',green_roi_ax,...
            'color',[0 1 0]+[1 0 1]*(roi_ind-1)/length(data.ROI),'tag',['roi_',num2str(roi_ind)]);
        line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',red_roi_ax,...
            'color',[1 0 0]+[0 1 1]*(roi_ind-1)/length(data.ROI),'tag',['redroi_',num2str(roi_ind)]);
        for n = p.Results.Channels
            line(exp_t,I_traces(:,n,roi_ind),...
                'parent',absolute_ax,...
                'tag',['fluo_trace_',num2str(n),'_',num2str(roi_ind)],...
                'color',colors(n,:)*(1-(roi_ind-1)/length(data.ROI)),...
                'displayname',[num2str(n),'_',num2str(roi_ind)])
        end
    end
    
    axis(panl(2).select(),'tight');
    ylabel(absolute_ax,'F (counts)')
    xlabel(absolute_ax,'Time (s)')
    
    h = legend(absolute_ax,'show','location','best');
    set(h,'fontsize',6,'box','off')
    
    % if sum(exp_t<0)
    %     bsln = exp_t<0 & exp_t>exp_t(1)+.02;
    % else
    %     bsln = exp_t<1 & exp_t>exp_t(1)+.02;
    % end
    %
    % for roi_ind = 1:length(data.ROI)
    %     for n = p.Results.Channels
    %         line(exp_t,I_traces(:,n,roi_ind)/nanmean(I_traces(bsln,n,roi_ind))*100,...
    %             'parent',ax,...
    %             'tag',['fluo_trace_',num2str(n),'_',num2str(roi_ind)],...
    %             'color',colors(n,:)*(1-(roi_ind-1)/length(data.ROI)),...
    %             'displayname',[num2str(n),'_',num2str(roi_ind)])
    %     end
    % end
    % % l = line(exp_t,dFoverF_fulltrace,'parent',ax,'color','k');
    % % set(l,'tag','dFoverF_trace','displayname',imdir)
    % axis(ax,'tight');
    % ylabel(ax,'% \Delta F / F')
    % xlabel(ax,'Time (s)')
end
%% Make a movie if needed
if p.Results.MakeMovie
    movieLocation = regexprep(data.name,...
        {'\\','Raw','.mat','Acquisition'},{'\\','Images','','Raw_Data'});
    [protocol,~,~,~,trialnum] = extractRawIdentifiers(data.name);
    
    vidObj = VideoWriter([movieLocation '\' protocol '_' mfilename '_' trialnum],'MPEG-4');
    set(vidObj,'FrameRate',round(1/diff(exp_t([1 2]))))
    
    I = squeeze(I(:,:,:,2));
    I_norm = ...
        (I - min(I_masked(:)))/...
        (max(I_masked(:)) - min(I_masked(:)));
    
    open(vidObj);
    
    clims = [min(I_norm(:)) max(I_norm(:))];
    
    
    % Create an animation.
    % set(gca,'nextplot','replacechildren');
    for frame=1:num_frame        
        imshow(I_norm(:,:,frame),clims,'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);
        colormap(panl(1,2).select(),'hot');
        
        plot(exp_t(exp_t<exp_t(frame)),I_traces(exp_t<exp_t(frame),2,1),'parent',absolute_ax,'color',[0 1 0]);
        
        figFrame = getframe(fig);
        writeVideo(vidObj,figFrame);
    end
    close(vidObj);
end


function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
exp_t = exp_t(1:num_frame);