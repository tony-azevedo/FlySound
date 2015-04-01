function varargout = scimStackChan2Batch(data,params,varargin)
% scimStackChan1Batch(data,params,montageflag)
% see also scimStackChan1Mask
p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('PlotFlag',true,@islogical);
p.addParameter('Channels',[1 2],@isnumeric);
parse(p,varargin{:});

%% Run scimStackChan2Mask once
chk = scimStackChan2Mask(data,params,varargin{:});
if isempty(chk)
    return
end
fig = findobj('tag','scimStackChan2Mask');


%% Batch process the bunch using the same ROI.

[protocol,dateID,flynum,cellnum,trialnum,D,trialStem,datastructfile] = extractRawIdentifiers(data.name);
prtclData = load(datastructfile);
prtclData = prtclData.data;
blocktrials = findLikeTrials('name',data.name,'datastruct',prtclData,'exclude',{'displacement','freq','amp','step'});

for bt = blocktrials;
    data_block = load(fullfile(D,sprintf(trialStem,bt)));
    scimStackChan2Mask(data_block,data_block.params,'NewROI','No','PlotFlag',false,'dFoFfig',fig,varargin{:});
end

data = load(fullfile(D,sprintf(trialStem,data.params.trial)));

scimStackChan2Mask(data,data.params,'NewROI','No','PlotFlag',true,'dFoFfig',fig,varargin{:});

varargout = {data};

systemsound('Notify');


function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
try exp_t = exp_t(1:num_frame);
catch
    warning('stack has more frames than time vector');
    exp_t = exp_t(1:min(num_frame,length(exp_t)));
end
