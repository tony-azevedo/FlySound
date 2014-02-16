% Electrophysiology Protocol Base Class
classdef PiezoProtocol < FlySoundProtocol
    % PiezoAM.m
    % PiezoBWCourtshipSong.m
    % PiezoChirp.m
    % PiezoCourtshipSong.m
    % PiezoSine.m
    % PiezoSquareWave.m
    % PiezoStep.m
    % PiezeTest.m

    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (SetAccess = protected, Abstract)
    end
            
    % The following properties can be set only by class methods
    properties (Hidden, SetAccess = protected)
        calibratedStimulus;
        calibratedStimulusFileName;
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
        uncorrectedcommand
        correctedcommand
    end
    
    events
        Calibrating
    end
    
    methods
        
        function obj = PiezoProtocol(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function treatUncalibratedStimulus(obj)
            % if not clibrating, notify that this is an uncalibrated
            % stimulus and ask if we should proceed 
            if ~strcmp(obj.modusOperandi,'Cal')
                ButtonName = questdlg('Uncalibrated Stimulus. Continue?', ...
                         'Uncalibrated!', ...
                         'Yes','No', 'No');
                switch ButtonName
                    case 'No'
                        error('Uncalibrated Stimulus');
                end
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'));
            end
            
            % if either calibrating or continuing, save a file (would be the
            % first)
            audiowrite([obj.getCalibratedStimulusFileName,'.wav'],...
                obj.uncorrectedcommand(obj.x>=0),...
                obj.params.samprateout,...
                'BitsPerSample',32);

        end
    end % methods
    
    methods (Abstract, Static, Access = protected)
    end
    
    methods (Abstract,Static)
    end
    
    methods (Abstract)
        getCalibratedStimulus(obj)
        getCalibratedStimulusFileName(obj)
    end

    
    methods (Access = protected)
    end % protected methods
    
    methods (Static)
        function CalibrateStimulus(A)
            if ~strcmp(A.protocol.modusOperandi,'Cal')
                error('A.protocol is not in calibration mode.  Call A.setProtocol(''<protocol>'',''modusOperandi'',''Cal'')');
            end
            
            fprintf('Calibration stimulus should not be ramped\n')
            fprintf('Calibration stimulus should use maximal displacement\n')
            
            ramptime = A.protocol.params.ramptime;
            displacements = A.protocol.params.displacements;
            
            A.protocol.setParams('ramptime',0);
            A.protocol.setParams('displacements',max(displacements));
            
            t = makeInTime(A.protocol);
            N = 3;
            
            trials = zeros(length(t),N);
            paramsToIter = A.protocol.paramsToIter;
            paramIter = A.protocol.paramIter;
            
            for p_ind = 1:size(paramIter,2)
                if ~isempty(paramIter)
                    ps = [paramsToIter',num2cell(paramIter(:,p_ind))]';
                    ps = ps(:)';
                    A.protocol.setParams(ps{:});
                end
                for n = 1:N;
                    A.run;
                    trials(:,n) = A.rig.inputs.data.sgsmonitor;
                    if abs(mean(A.rig.inputs.data.sgsmonitor(t<0))-A.protocol.params.displacementOffset) > .5
                        error('Is the Piezo on?');
                    end
                end
                sgs = mean(trials,2);
                
                f = figure(101);clf
                ax = subplot(1,1,1,'parent',f); hold(ax,'on');
                
                [~,stim,targetstim] = A.protocol.getStimulus;

                plot(ax,A.protocol.x,stim,'color',[.7 .7 .7])
                plot(ax,A.protocol.x,targetstim,...
                    'color',[1 0 0])
                plot(ax,t,trials,'color',[.7 .7 1])
                plot(ax,t,sgs,'color',[0 0 1])
                
                sgs = sgs - mean(sgs(10:2000));
                stim = stim - stim(1);
                targetstim = targetstim - targetstim(1);
                
                [C, Lags] = xcorr(sgs,stim,'coeff');
                figure(102);
                plot(Lags,C);
                
                i_del = Lags(C==max(C));  % assume lag is causal.  If not it's an error.
                
                if i_del < 0
                    disp(i_del)
                    [~,locs]= findpeaks(C);
                    lags = Lags(locs);
                    i_del = lags(find(lags>0,1));
                    warning('No causal delay between stimulus and response')
                    disp(i_del)
                end
                %     t_del = t(end)-t(end+i_del+1);
                % else
                %     t_del = t(i_del+1) - t(1);
                % end
                %
                figure(103); %clf
                plot(t(1:end-i_del),targetstim(1:end-i_del),'color',[.7 .7 .7]), hold on
                plot(t(1:end-i_del),sgs(i_del+1:end)), hold off
                
                diff = targetstim(1:end-i_del)-sgs(i_del+1:end);
                diff = diff/A.protocol.params.displacement;

                % end of the stimulus can produce transients in diff that
                % are impossible to get rid of.  Taper instead
                stimpnts = round(A.protocol.params.samprateout*A.protocol.params.preDurInSec+1:...
                    A.protocol.params.samprateout*(A.protocol.params.preDurInSec+A.protocol.params.stimDurInSec));
                
                taper_time = 0.005;
                w = window(@triang,2*taper_time*A.protocol.params.samprateout);
                w = [w(1:taper_time*A.protocol.params.samprateout);...
                    ones(length(stimpnts)-length(w),1);...
                    w(taper_time*A.protocol.params.samprateout+1:end)];
                
                taper = zeros(size(t));
                taper(stimpnts) = w;
                diff = diff .* taper(1:length(diff));
                diff = diff(t(1:end-i_del)>=0 & t(1:end-i_del)<A.protocol.params.stimDurInSec);
                
                [oldstim,fs] = audioread([A.protocol.getCalibratedStimulusFileName,'.wav']);
                info = audioinfo([A.protocol.getCalibratedStimulusFileName,'.wav']);
                NBITS = info.BitsPerSample;
                
                newstim = diff+oldstim(1:length(diff));
                
                figure(104),clf, hold on
                plot(oldstim,'color',[.7 .7 .7])
                plot(newstim,'r')
                plot(diff),
                
                fn = A.protocol.getCalibratedStimulusFileName;
                cur_cs_fn = length(dir([fn,'_*.wav']));
                copyfile([fn,'.wav'],[fn '_' num2str(cur_cs_fn) '.wav'],'f')
                
                audiowrite([fn,'.wav'],newstim,fs,'BitsPerSample',NBITS);
                if mean(sqrt(diff.^2)) > .01 || max(abs(diff)) > 0.05
                    disp(mean(sqrt(diff.^2)))
                    disp(max(abs(diff)))
                    A.protocol.CalibrateStimulus(A);
                end
            end
            
            if ~isempty(paramIter)
                for p_ind = 1:length(paramsToIter);
                    ps{2*p_ind-1} = paramsToIter{p_ind};
                    ps{2*p_ind} = unique(paramIter(p_ind,:));
                end
                A.protocol.setParams(ps{:});
                A.protocol.setParams('ramptime',ramptime);
                A.protocol.setParams('displacements',displacements);
            end
        end
    end
end % classdef