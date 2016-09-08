classdef M285Rig < EPhysRig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    
    properties 
        latestData
    end
    
    properties (Constant)
        rigName = 'M285Rig';
        IsContinuous = false;
    end
    
    methods
        function obj = M285Rig(varargin)
            % rigDev = getpref('AcquisitionHardware','rigDev');
            % triggerChannelIn = getpref('AcquisitionHardware','triggerChannelIn');
            % triggerChannelOut = getpref('AcquisitionHardware','triggerChannelOut');
            %
            % obj.aiSession.addTriggerConnection([rigDev '/' triggerChannelIn],'External','StartTrigger');
            % obj.aoSession.addTriggerConnection('External',[rigDev '/' triggerChannelOut],'StartTrigger');
            addlistener(obj.aiSession,'DataAvailable', @obj.returnData); 
        end
        
        
        function in = run(obj,protocol,varargin)
            
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
            
            if obj.params.interTrialInterval >0;
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ...
                    fprintf('%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end
            M285_setupScript;
            
            notify(obj,'StartRun');
            
            for n = 1:repeats
                while protocol.hasNext()
                    obj.latestData = [];
                    obj.setAOSession(protocol);
                    notify(obj,'StartTrial',PassProtocolData(protocol));
                    obj.aiSession.startBackground; % both amp and signal monitor input
                    
                    M285_acquisitionScript;
                    
                    wait(obj.aiSession);
                    
                    in = obj.latestData;
                    obj.transformInputs(in);
                    if obj.params.interTrialInterval >0;
                        t = timerfind('Name','ITItimer');
                        start(t)
                        wait(t)
                    end
                    notify(obj,'SaveData');
                    obj.displayTrial(protocol);
                    notify(obj,'DataSaved');
                end
                protocol.reset;
            end
        end
        
        function returnData(obj,fig,evnt,varargin)
            obj.latestData = [obj.latestData;evnt.Data];
        end

        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};            
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                %ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                %out = protocol.getStimulus;
                
                %delete(findobj(ax,'tag','sgsmonitor'));               
                %delete(findobj(ax,'tag','piezocommand'));
                %line(makeOutTime(protocol),out.piezocommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','piezocommand','displayname','V');
                %line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','sgsmonitor','displayname','V');
                %ylabel('SGS (V)'); box off; set(gca,'TickDir','out');
                %xlabel('Time (s)'); %xlim([0 max(t)]);
                %linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end

            if strcmp(obj.devices.amplifier.mode,'VClamp')
                invec = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier.mode))
                invec = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            end
            
            chnames = obj.getChannelNames;
            
%             l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','piezocommand');
%             set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'piezocommand')));

            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);
            
%             l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','sgsmonitor');
%             set(l,'ydata',obj.inputs.data.sgsmonitor);

        end

    end
    
    methods (Access = protected)
    end
end
