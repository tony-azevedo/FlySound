classdef SealAndLeakExternal < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SealAndLeakExternal'
    end

    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = SealAndLeakExternal(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            obj.createDataStructBoilerPlate();  % protocol specific Params
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            p = inputParser;
            addOptional(p,'famN',1);
            addOptional(p,'vm_id',0);
            parse(p,varargin{:});
            famN = p.Results.famN;
            
            % stim_mat = generateStimFamily(obj);
            trialdata = obj.dataBoilerPlate;
            trialdata.durSweep = 1;
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for fam = 1:famN

                fprintf('Trial %d\n',obj.n);

                trialdata.trial = obj.n;

                obj.y = obj.aiSession.startForeground; %plot(x); drawnow
                voltage = obj.y;
                current = obj.y;
                
                % apply scaling factors
                current = (current-trialdata.currentoffset)*trialdata.currentscale;
                voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
                
                switch obj.rec_mode
                    case 'VClamp'
                        obj.y = current;
                        obj.y_units = 'pA';
                    case 'IClamp'
                        obj.y = voltage;
                        obj.y_units = 'mV';
                end
                                
            end
            [trialdata.Rinput,trialdata.Rseries,trialdata.Cm] = obj.displayRun();
            obj.saveData(trialdata,current,voltage)% save data(n)

        end
                
        function varargout = displayRun(obj)
            a = gradient(obj.y);
            aa = gradient(a);
            pulseon_crit1 = a > max(a)/2;
            pulseon_crit2 = aa < min(aa)/2;
            
            pulseon = pulseon_crit1(1:end-1) & pulseon_crit2(2:end);
            pulseon(end+1) = false;
            pulseon = [0;diff(pulseon)];
            pulseon = pulseon>0;
            
            ind = find(pulseon);
            deltax = min(diff(ind));
            ind = ind(1:end-1);
            if ind(1) < 10
                ind = ind(2:end);
            end
            
            pulse_t = obj.x(ind(1)-8+1:ind(1)+deltax)-obj.x(ind(1));
            pulse_t = pulse_t(:);
            mat = nan(deltax+9,length(ind));
            for i = 1:length(ind)
                mat(:,i) = obj.y(ind(i)-9+1:ind(i)+deltax);
            end
            diffmat = diff(mat);
            for i = 1:length(ind)
                rise = find(diffmat(1:60,i)==max(diffmat(1:60,i)));
                diffmat(:,i) = mat(rise-8+1:rise+deltax,i);
                %RCtau = nlinfit(obj.x
            end
            
            figure(1);
            plot(pulse_t,diffmat,'color',[1 .7 .7])
            pulseresp = mean(diffmat,2);
            base = mean(pulseresp(1:6));
            pulseresp = pulseresp-base;
            Icoeff = nlinfit(...
                pulse_t(pulse_t>.0004 & pulse_t<.007),...
                pulseresp(pulse_t>.0004 & pulse_t<.007),...
                @exponential,...
                [pulseresp(1),max(pulseresp),0.004]);

            RCcoeff = Icoeff; RCcoeff(1:2) = 0.005./(RCcoeff(1:2)*1e-12);
            line(pulse_t,pulseresp+base,'color',[.7 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            line(pulse_t(pulse_t>.0004 & pulse_t<.007),...
                exponential(Icoeff,pulse_t(pulse_t>.0004 & pulse_t<.007))+base,...
                'color',[.7 0 0],'linewidth',3);
            text(0.001,exponential(Icoeff,0.0004),sprintf('Ri=%.2e, Rs=%.2e, Cm = %.2e',RCcoeff(1),RCcoeff(2),RCcoeff(3)/RCcoeff(2)));
            switch obj.rec_mode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlim([-0.0005 0.007]);
            xlabel('Time (s)'); %xlim([0 max(t)]);
            varargout = {RCcoeff(1),RCcoeff(2),RCcoeff(3)/RCcoeff(2)};
        end

    end % methods
    
    methods (Access = protected)
                        
        function createDataStructBoilerPlate(obj)
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            dbp = obj.dataBoilerPlate;
            dbp.Rinput = [];
            dbp.Rseries = [];
            dbp.Cm = [];
            obj.dataBoilerPlate = dbp;
        end
                
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef