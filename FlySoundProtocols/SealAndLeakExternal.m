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
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            trialdata = runtimeParameters(obj,varargin{:});
            obj.writePrologueNotes()

            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for repeat = 1:trialdata.repeats

                trialdata.trial = obj.n;

                obj.y = obj.aiSession.startForeground; %plot(x); drawnow
                voltage = obj.y;
                current = obj.y;
                
                % apply scaling factors
                current = (current-trialdata.scaledcurrentoffset)*trialdata.scaledcurrentscale;
                voltage = (voltage-trialdata.scaledvoltageoffset)*trialdata.scaledvoltagescale;
                
                switch obj.recmode
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
            obj.writeTrialNotes(trialdata.Rinput,trialdata.Rseries,trialdata.Cm)

        end
                
        function varargout = displayRun(obj)
            pre = round(9/10000*obj.params.sampratein);
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
            if ind(1) <= pre
                ind = ind(2:end);
            end
            
            pulse_t = obj.x(ind(1)-pre+1:ind(1)+deltax)-obj.x(ind(1));
            pulse_t = pulse_t(:);
            mat = nan(deltax+pre,length(ind));
            for i = 1:length(ind)
                mat(:,i) = obj.y(ind(i)-pre+1:ind(i)+deltax);
            end
            if obj.params.sampratein <= 10000
                pulse_t = obj.x(ind(1)-(pre-1)+1:ind(1)+deltax)-obj.x(ind(1));
                pulse_t = pulse_t(:);
                
                diffmat = diff(mat);
                for i = 1:length(ind)
                    rise = find(diffmat(1:(pre*8),i)==max(diffmat(1:(pre*8),i)));
                    diffmat(:,i) = mat(rise-pre+1:rise+deltax,i);
                    %RCtau = nlinfit(obj.x
                end
            else
                diffmat = mat;
            end

            figure(1);
            plot(pulse_t,diffmat,'color',[1 .7 .7])
            pulseresp = mean(diffmat,2);
            base = mean(pulseresp(1:6));
            pulseresp = pulseresp-base;
            start = .0002;
            finit = .007; %s
            Icoeff = nlinfit(...
                pulse_t(pulse_t>start & pulse_t<finit),...
                pulseresp(pulse_t>start & pulse_t<finit),...
                @exponential,...
                [max(pulseresp)/3,max(pulseresp),0.004]);

            RCcoeff = Icoeff; RCcoeff(1:2) = 0.005./(RCcoeff(1:2)*1e-12); % 5 mV step/I_i or I_f
            line(pulse_t,pulseresp+base,'color',[.7 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            line(pulse_t(pulse_t>start & pulse_t<finit),...
                exponential(Icoeff,pulse_t(pulse_t>start & pulse_t<finit))+base,...
                'color',[.7 0 0],'linewidth',3);
            ylims = get(gca,'ylim');
            text(0.001, base+.9*(max(ylims)-base),sprintf('Ri=%.2e, Rs=%.2e, Cm = %.2e',RCcoeff(1),RCcoeff(2),RCcoeff(3)/RCcoeff(2)));
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlim([-0.0005 finit]);
            xlabel('Time (s)'); %xlim([0 max(t)]);
            varargout = {RCcoeff(1),RCcoeff(2),RCcoeff(3)/RCcoeff(2)};
        end

    end % methods
    
    methods (Access = protected)
        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            
        end
        
        function createDataStructBoilerPlate(obj)
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            dbp = obj.dataBoilerPlate;
            dbp.Rinput = [];
            dbp.Rseries = [];
            dbp.Cm = [];
            obj.dataBoilerPlate = dbp;
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.durSweep = 1;
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end
        
        function writeTrialNotes(obj,Rinput,Rseries,Cm)
            % In case more construction is needed
            writeTrialNotes@FlySoundProtocol(obj);
            fprintf(obj.notesFileID,'\t**** Rinput = %.2e, Rseries = %.2e, Cm = %.2e\n',Rinput,Rseries,Cm);
            fprintf(1,'\t**** Rinput = %.2e, Rseries = %.2e, Cm = %.2e\n',Rinput,Rseries,Cm);
        end

        
    end % protected methods
    
    methods (Static)
    end
end % classdef