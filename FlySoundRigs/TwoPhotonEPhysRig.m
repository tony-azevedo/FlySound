classdef TwoPhotonEPhysRig < TwoPhotonRig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    
    properties (Constant)
        rigName = 'TwoPhotonEPhysRig';
        IsContinuous = false;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = TwoPhotonEPhysRig(varargin)
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            if nargin>3
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            else
            setDisplay@Rig(obj,fig,evnt)
            end
            if nargin>3
                protocol = varargin{1};   
                if strcmp(protocol.protocolName,get(obj.TrialDisplay,'Name')) &&...
                        isequal(get(obj.TrialDisplay,'UserData'),protocol.params)
                    return
                end
                
                set(obj.TrialDisplay,'Name',protocol.protocolName)
                set(obj.TrialDisplay,'UserData',protocol.params)
                
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                delete(findobj(ax,'tag','ampinput_alt'));
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[1 .7 1],'linewidth',1,'tag','exposure','displayname','io');
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput_alt','displayname','altinput');
                
                out = protocol.getStimulus;
                delete(findobj(ax,'tag','ampoutput'));
                outlabel = fieldnames(out);
                if ~isempty(outlabel)
                    line(makeOutTime(protocol),out.(outlabel{1}),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput','displayname','output');
                    ylabel('out'); box off; set(gca,'TickDir','out');
                else
                    line(makeOutTime(protocol),makeOutTime(protocol),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput','displayname','output');
                    box off; set(gca,'TickDir','out');
                end
                xlabel('Time (s)'); %xlim([0 max(t)]);
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end

            if strcmp(obj.devices.amplifier.mode,'VClamp')                
                invec = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};

                invecalt = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inaltunits = obj.devices.amplifier.inputUnits{ind(1)};
            elseif sum(strcmp({'IClamp','IClamp_fast','I=0'},obj.devices.amplifier.mode))
                invec = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                
                invecalt = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inaltunits = obj.devices.amplifier.inputUnits{ind(1)};
            end
            ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            ylabel(findobj(obj.TrialDisplay,'tag','outputax'),inaltunits);

            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);

            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampinput_alt');
            set(l,'ydata',invecalt);
            
            
            out = protocol.getStimulus;
            outlabels = fieldnames(out);
            chnames = obj.getChannelNames;
            if ~isempty(outlabels)
                if strcmp(obj.devices.amplifier.mode,'VClamp')
                    outvec = out.voltage;
                elseif sum(strcmp({'IClamp','IClamp_fast','I=0'},obj.devices.amplifier.mode))
                    outvec = obj.outputs.datacolumns(:,strcmp(chnames.out,'current'));
                end

                l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampoutput');
                set(l,'ydata',outvec);                
            end
        end
    end
    
    methods (Access = protected)
    end
end
