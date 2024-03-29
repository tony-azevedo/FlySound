classdef ContinuousRig < Rig
    
    properties (Constant,Abstract)
        rigName;
    end
    
    properties (Constant)
        IsContinuous = true;
    end

    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        D
        flynumber
        cellnumber
        protocol
        name
        n
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = ContinuousRig(varargin)
            ...
        end
        
        function updateFileNames(obj,varargin)%,metprop,propevnt)
            if nargin<3
                error('continuousInRig:notEnoughInputs','Not enough inputs')
            end
            p = inputParser;
            p.PartialMatching = 0;
            p.addParameter('amplifier1Device','MultiClamp700A',@ischar);
            p.addParameter('directory','/tony/Acquisition',@ischar);
            p.addParameter('flynumber','0',@ischar);
            p.addParameter('cellnumber','0',@ischar);
            p.addParameter('protocol',[]);
            parse(p,varargin{:});
            
            obj.D = p.Results.directory;
            obj.flynumber = p.Results.flynumber;
            obj.cellnumber = p.Results.cellnumber;
            obj.protocol = p.Results.protocol;

            % check whether a saved data file exists with today's date
            todayname = [obj.D,'\',obj.protocol.protocolName,'_ContRaw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*_A.bin'];
            rawtrials = dir(todayname);
            if isempty(rawtrials)
                obj.n = 1;
            else
                trials_sofar = zeros(size(rawtrials));
                for t_idx = 1:length(trials_sofar)
                    nstr = regexp(rawtrials(t_idx).name,'_(\d+)_A.bin','match','once');
                    trials_sofar(t_idx) = str2double(nstr(2:regexp(nstr(2:end),'_')));
                end
                obj.n = max(trials_sofar)+1;
            end
            
            cd(obj.D);
        end
    
    end
    
    methods (Abstract)
        stop(obj)
    end
end
