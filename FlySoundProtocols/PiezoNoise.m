% Drive piezo with noise stimuli, control displacements, seed, randomseed, 
classdef PiezoNoise < PiezoProtocol
    
    properties (Constant)
        protocolName = 'PiezoNoise';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoRig';
        analyses = {'piezoNoiseDisplay'};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        filter = [];
    end
    
    events
    end
    
    methods
        
        function obj = PiezoNoise(varargin)
            obj = obj@PiezoProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;

            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
            end

        end
        
        function varargout = getStimulus(obj,varargin)            
            persistent seed_cnt
            if isempty(seed_cnt)
                seed_cnt = 1;
            end
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));
            
            if ~obj.params.randomseed
                rng(obj.params.seed);
            else
                rng(25)
                for i = 1:seed_cnt
                obj.params.seed = randi(500,1);
                end
                seed_cnt = seed_cnt+1;
                rng(obj.params.seed);
            end
            
            standardstim = randn(size(stimpnts));
            standardstim = filter(obj.filter,standardstim);
            standardstim = standardstim(:);
            obj.uncorrectedcommand(stimpnts) = double(obj.y(obj.y~=0)~=0) .* standardstim;
            
            calstim = obj.uncorrectedcommand;
            
            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
                calstim(obj.x>=0 & obj.x <obj.params.stimDurInSec) = ...
                    obj.y(obj.x>=0 & obj.x <obj.params.stimDurInSec) .* ...
                    stim(1:obj.params.stimDurInSec*obj.params.samprateout);
            else
                obj.treatUncalibratedStimulus
            end
            
            calstim = obj.params.displacement * obj.y.*calstim + obj.params.displacementOffset;
            
            if max(calstim > 10) || min(calstim < 0)
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            
            obj.out.piezocommand = calstim;
            obj.out.speakercommand = obj.y .* obj.uncorrectedcommand;

            varargout = {obj.out,...
                obj.out.piezocommand,...
                obj.out.speakercommand + obj.params.displacementOffset};
        end
        
        function varargout = getCalibratedStimulus(obj)
            varargout{1} = obj.uncorrectedcommand * obj.params.displacement + obj.params.displacementOffset;
        end
        
        function fn = getCalibratedStimulusFileName(obj)
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\StimulusWaves\',...
                sprintf('%s_sdis%.0f_seed%.0f_disp%.2f',...
                obj.protocolName,...
                obj.params.stimDurInSec,...
                obj.params.seed,...
                obj.params.displacement)];
            fn = regexprep(fn,'\.','_');
        end

    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmacqpref('defaultsPiezoNoise')
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            % [stim,obj.params.samprateout] = wavread('CourtshipSong.wav');
            % stim = flipud(stim);
            
            obj.params.sampratein = obj.params.samprateout;
            obj.params.displacements = [1];
            obj.params.displacement = obj.params.displacements(1);

            obj.params.ramptime = 0.04; %sec;
            
            obj.params.seed = 25;
            obj.params.randomseed = 0;
            
            obj.params.stimDurInSec = 30;
            obj.params.preDurInSec = 2;
            obj.params.postDurInSec = 2;
            
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.displacement = obj.params.displacements(1);
            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [~,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
            end
            
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            y = makeOutTime(obj);
            y = y(:);
            y(:) = 0;

            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));

            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];
                        
            y(stimpnts) = w;
            obj.y = y;
            
            % Allocate
            obj.out.piezocommand = y;
            obj.uncorrectedcommand = y;
            
                       % Filter Design
            rad_per_sample = 2*pi/obj.params.samprateout;
            Fp_Hz = 500;
            Fp_rad_per_samp = Fp_Hz * rad_per_sample;
            Fst_Hz = 800;
            Fst_rad_per_samp = Fst_Hz * rad_per_sample;
            Allowable_ripple = .5; %DB
            Attenuation = 60; %DB
            
            d=fdesign.lowpass('Fp,Fst,Ap,Ast',...
                Fp_rad_per_samp,...
                Fst_rad_per_samp,...
                Allowable_ripple,...
                Attenuation);
            
            % designmethods(d)
            
            Hd = design(d,'butter');
            % fvtool(Hd);
            %
            % [gd,w] = grpdelay(Hd);
            % plot(w,gd)
                        
            obj.filter = Hd;
            
            % Need some control over the seed
            if obj.params.randomseed
                rng(25);
            end            
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef


%             %% debug code
%             figure; 
%             subplot(2,1,1);
%             [Pxx,f] = pwelch(standardstim,obj.params.samprateout,[],[],obj.params.samprateout);
%             loglog(f,Pxx,'color','b'); hold on
%             
%             subplot(2,2,3);
%             [xcor, lags] = xcorr(standardstim);
%             plot(lags(lags>=-200 & lags<=200)/obj.params.samprateout,xcor(lags>=-200 & lags<=200));  hold on
% 
%             subplot(2,2,4);
%             plot(standardstim(1:1000));  hold on

%             %%            
%             %%
%             subplot(2,1,1);
%             [Pxx,f] = pwelch(standardstim,obj.params.samprateout,[],[],obj.params.samprateout);
%             loglog(f,Pxx,'color','r'); hold on
%             
%             subplot(2,2,3);
%             [xcor, lags] = xcorr(standardstim);
%             plot(lags(lags>=-200 & lags<=200)/obj.params.samprateout,xcor(lags>=-200 & lags<=200),'r');  hold on
% 
%             subplot(2,2,4);
%             plot(standardstim(1:1000),'r');  hold on

%             %%            
            
