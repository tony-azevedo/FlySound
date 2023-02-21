classdef TriggerPiezoControlRig < EPhysControlRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'TriggerPiezoControlRig';
        IsContinuous = false;
    end
    
    methods
        function obj = TriggerPiezoControlRig(varargin)
            obj.addDevice('triggeredpiezo','TriggeredPiezo_Control');
            obj.addDevice('refchan','ReferenceChannelControl')
        end
        
        function in = run(obj,protocol,varargin)
            % reimplement a few lines from the EPysiControlRig.run method
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            try in = obj.subrun(protocol,varargin{:}); % run this protected method below
            catch e
                % obj.devices.epi.abort
                e.rethrow
            end
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            % setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})
            % if nargin>3
            %     protocol = varargin{1};
            %     out = protocol.getStimulus;
            %
            %     ax = findobj(obj.TrialDisplay,'tag','outputax');
            %     delete(findobj(ax,'tag','sgsmonitor'));
            %     delete(findobj(ax,'tag','piezocommand'));
            %     line(makeOutTime(protocol),out.piezocommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','piezocommand','displayname','piezocommand');
            %     line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','sgsmonitor','displayname','sgsmonitor');
            %     ylabel(ax,'SGS (V)'); box off; set(gca,'TickDir','out');
            %     xlabel(ax,'Time (s)'); %xlim([0 max(t)]);
            %     linkaxes(get(obj.TrialDisplay,'children'),'x');
            % end
        end
        
        function displayTrial(obj,protocol)
            % if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            % displayTrial@TwoAmpRig(obj,protocol)
            %
            % chnames = obj.getChannelNames;
            %
            % l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','piezocommand');
            % set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'piezocommand')));
            %
            % l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','sgsmonitor');
            % set(l,'ydata',obj.inputs.data.sgsmonitor);
        end

        
    end
    
    methods (Access = protected)
        
        function in = subrun(obj,protocol,varargin)
            
            if nargin>2
                repeats = varargin{1};
            else
                repeats = 1;
            end
            if isprop(obj,'TrialDisplay') && ~isempty(obj.TrialDisplay)
                if ishandle(obj.TrialDisplay)
                    delete(obj.TrialDisplay);
                end
            end
            obj.setDisplay([],[],protocol);
            obj.setTestDisplay();
            
            protocol.setParams('-q','samprateout',protocol.params.sampratein);
            obj.aoSession.Rate = protocol.params.samprateout;
            
            notify(obj,'StartRun_Control');
            
            for n = 1:repeats
                while protocol.hasNext()
                    
                    obj.setAOSession(protocol);
                    obj.devices.triggeredpiezo.setStimulus(protocol.cue); 
                    % "cue" refers to a triggered piezo stimulus that
                    % occurs before th light turns on in the leg
                    % positioning experiment, i.e. a stimulus that could be
                    % used as a conditioned stimulus (cue) that the light
                    % is about to turn on. Stick to this terminology in any
                    % protocol that uses this rig.
                    
                    % setup the data logger
                    notify(obj,'StartTrial_Control',PassProtocolData(protocol));
                    obj.devices.triggeredpiezo.start;
                    
                    in = obj.aoSession.startForeground; % both amp and signal monitor input
                    wait(obj.aoSession);

                    % setup log data
                    % obj.transformInputs(in);
                    notify(obj,'EndTrial_Control');
                                        
                    notify(obj,'SaveData_Control');
                    % obj.displayTrial(protocol);
                    notify(obj,'DataSaved_Control');
                    notify(obj,'IncreaseTrialNum_Control');
                    obj.params.trialnum = obj.params.trialnum+1;
                    
                    obj.devices.triggeredpiezo.stop;

                end
                protocol.reset;
            end
            fprintf(1,'Block complete.\n')
            notify(obj,'EndRun_Control');
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                delete(t)
            end
%             if obj.params.waitForLED
%                 wflt = timerfind('Name','LEDTimeoutTimer');
%                 delete(wflt)
%             end
        end
    end
end
