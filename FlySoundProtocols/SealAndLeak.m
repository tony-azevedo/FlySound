classdef SealAndLeak < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SealAndLeak';
        requiredRig = 'BasicEPhysRig';
    end
    
    properties (Hidden)
    end
    
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = SealAndLeak(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
        

    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            obj.params.sampratein = 100000;
            obj.params.samprateout = 100000;
            obj.params.stepamp = 5; %mV;
            obj.params.stepdur = .0167; %sec;
            obj.params.pulses = 20;
            %             obj.params.stimDurInSec = 2;
            %             obj.params.preDurInSec = .5;
            %             obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses+2);
            
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses);
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            obj.y = zeros(2*obj.params.pulses,obj.params.stepdur*obj.params.samprateout);
            obj.y(1:2:2*obj.params.pulses,:) = 1;
            obj.y = obj.y';
            obj.y = obj.y(:);

            obj.y = obj.y * obj.params.stepamp;
            obj.out.voltage = obj.y;
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef


% function displayTrial(obj)
%     figure(1);
%     redlines = findobj(1,'Color',[1, 0, 0]);
%     set(redlines,'color',[1 .8 .8]);
%     bluelines = findobj(1,'Color',[0, 0, 1]);
%     set(bluelines,'color',[.8 .8 1]);
%     greylines = findobj(1,'Color',[.6 .6 .6]);
%     set(greylines,'color',[.8 .8 .8]);
%     pinklines = findobj(1,'Color',[.5 1 1]);
%     set(pinklines,'color',[.8 .8 .8]);
%
%     % number of samples in a pulse
%     % chop y down
%     ppnts = obj.params.stepdur*obj.params.samprateout;
%     stimx = obj.stimx(ppnts+1:end);
%     % stimx = reshape(stimx,2*ppnts,obj.params.pulses);
%     stimx = stimx(1:2*ppnts);
%     x = obj.x(ppnts+1:end);
%     % stimx = reshape(stimx,2*ppnts,obj.params.pulses);
%     x = x(1:2*ppnts);
%
%     stim = obj.stim;
%     stim = stim(ppnts+1:end);
%     %stim = reshape(stim,2*ppnts,obj.params.pulses);
%     stim = stim(1:2*ppnts);
%
%     y = obj.y(:,1);
%     base = mean(y(1:ppnts));
%     y = y(ppnts+1:end);
%     y = reshape(y,2*ppnts,obj.params.pulses);
%
%     y_bar = mean(y,2) - base;
%
%     % R = V/I(at end of step);
%     sealRes_Est1 = obj.params.stepamp/1000 / (y_bar(ppnts)*1e-12);
%
%     start = x(10);
%     finit = x(ppnts); %s
%     pulse_t = x(x>start & x<finit);
%     % TODO: handle the warnings
%     Icoeff = nlinfit(...
%         pulse_t - pulse_t(1),...
%         y_bar(x>start & x<finit),...
%         @exponential,...
%         [max(y_bar)/3,max(y_bar),obj.params.stepdur]);
%     RCcoeff = Icoeff; RCcoeff(1:2) = obj.params.stepamp/1000 ./(RCcoeff(1:2)*1e-12); % 5 mV step/I_i or I_f
%
%     sealRes_Est2 = RCcoeff(1);
%     % print dlg button reminding to write the value on the checklist in the lab notebook, or the form or in the google sheet.
%
%     ax1 = subplot(3,1,3);
%     line(stimx,stim,'parent',ax1,'color',[0 0 1],'linewidth',1);
%     box off; set(gca,'TickDir','out');
%     xlabel('Time (s)'); xlim([stimx(1) stimx(end)]);
%     ylabel('mV'); %xlim([0 max(t)]);
%
%     ax2 = subplot(3,1,[1 2]);
%     plot(x,y,'parent',ax2,'color',[1 .7 .7],'linewidth',1); hold on
%     line(x,y_bar+base,'parent',ax2,'color',[.7 0 0],'linewidth',1);
%     line(x(x>start & x<finit),...
%         exponential(Icoeff,pulse_t-pulse_t(1))+base,...
%         'color',[0 1 1],'linewidth',1);
%
%     box off; set(gca,'TickDir','out');
%     xlabel('Time (s)'); xlim([stimx(1) stimx(end)]);
%     ylabel('pA'); %xlim([0 max(t)]);
%
%     % write the value in the comments, make a guess based on value
%     % whether it's electrode, seal, CA, whole cell resistance, just
%     % for a checks
%     if sealRes_Est2<100e6
%         guess = '''trode';
%     elseif sealRes_Est2<100e6
%         guess = 'Cell-Attached';
%     elseif sealRes_Est2<4e9
%         guess = 'Whole-Cell';
%     else
%         guess = 'Seal';
%     end
%
%     str = sprintf('R (ohms): \n\test 1 (step end) = %.2e; \n\test 2 (exp fit) = %.2e; \n\tGuessing: %s',...
%         sealRes_Est1,...
%         sealRes_Est2,...
%         guess);
%     obj.comment(str);
%     obj.comment(sprintf('Ri=%.2e, Rs=%.2e, Cm = %.2e',RCcoeff(1),RCcoeff(2),RCcoeff(3)/RCcoeff(2)));
%     msgbox(str);
% end