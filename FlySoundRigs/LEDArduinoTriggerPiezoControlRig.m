classdef LEDArduinoTriggerPiezoControlRig < EPhysControlRig & EpiOrLEDRig 
    % current hierarchy:
    
    properties (Constant)
        rigName = 'LEDArduinoTriggerPiezoControlRig';
        IsContinuous = false;
    end
    
    methods
        function obj = LEDArduinoTriggerPiezoControlRig(varargin)
            obj.addDevice('triggeredpiezo','TriggeredPiezo_Control');
        end
        
        function in = run(obj,protocol,varargin)
            % reimplement a few lines from the EPysiControlRig.run method
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            try in = obj.subrun(protocol,varargin{:});
            catch e
                obj.devices.epi.abort
                e.rethrow
            end
        end
        
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
            
            obj.setUpITITimer();
            [on_cntr, off_cntr] = obj.setUpWaitTimers();
            notify(obj,'StartRun_Control');
            
            for n = 1:repeats
                while protocol.hasNext()
                    
                    if obj.params.waitForLED
                        [on_cntr, off_cntr] = obj.handleTrialFailures(on_cntr,off_cntr);
                        if on_cntr<0
                            protocol.reset
                            return
                        end
                    end
                    obj.setAOSession(protocol);
                    obj.devices.triggeredpiezo.setStimulus(protocol.cue);
                    
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
                    
                    % options for what to do if light is still on. Else,
                    % just leave the led on
                    if obj.params.turnoffLED
                        obj.itiWait()
                        notify(obj,'EndTimer_Control')
                    elseif obj.params.waitForLED
                        LEDstate = in(end,obj.ardout_col);
                        if ~LEDstate && obj.devices.epi.params.blueToggle
                            on_cntr = 0;
                            off_cntr = off_cntr + 1;
                            obj.itiWait()
                        elseif LEDstate
                            [on_cntr, off_cntr] = obj.waitForLEDOff(on_cntr,off_cntr);
                        end
                    end
                    
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
            if obj.params.waitForLED
                wflt = timerfind('Name','LEDTimeoutTimer');
                delete(wflt)
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
    end
end
