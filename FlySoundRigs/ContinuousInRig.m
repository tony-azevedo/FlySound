classdef ContinuousInRig < ContinuousRig & EPhysRig
    
    properties (Constant)
        rigName = 'ContinuousInRig';
    end
    
    properties (Hidden, SetAccess = protected)
        prevValue
        listener
        fid
    end
    
    properties (SetAccess = protected)
        D
        flynumber
        cellnumber
        protocol
        name
        n
        expt_n
        block_n
        savelistener
    end
    
    events
    end
    
    methods
        function obj = ContinuousInRig(varargin)
            if nargin<4
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
            
            obj.addDevice('exposure','Exposure')
            
            % check whether a saved data file exists with today's date
            todayname = [obj.D,'\',obj.protocol.protocolName,'_ContRaw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*'];
            rawtrials = dir(todayname);

            obj.n = length(rawtrials)+1;
                        
            fprintf('CONTINUOUSRIG: Fly %s, Cell %s currently has %d %s trials\n',...
                obj.flynumber,obj.cellnumber,obj.n-1,obj.protocol.protocolName);
                        
        end
    
        
        function run(obj,protocol,varargin)
            if obj.aoSession.IsRunning
                return
            end
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            %obj.setOutputs;

            obj.aoSession.Rate = protocol.params.samprateout;
            obj.aoSession.wait;

            obj.setAOSession(protocol);
            obj.listener = obj.aoSession.addlistener('DataRequired',...
                @(src,event) src.queueOutputData(obj.outputs.datacolumns));
           
            obj.name = [obj.D,'\',obj.protocol.protocolName,'_ContRaw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_' num2str(obj.n) '.bin'];

            % Writing to a binary file 1/18/17            
            obj.fid = fopen(obj.name,'a');

            fprintf(1,'%s\n',obj.name);
            % header contains the length of the filename
            fnl = fwrite(obj.fid,length(obj.name),'uint');
            fn = fwrite(obj.fid,obj.name,'char');

            fprintf(1,'protocol %s mode %s gain %d samprate %d \n',protocol.protocolName, obj.devices.amplifier.mode,obj.devices.amplifier.gain,protocol.params.sampratein);
            % header contains the length of the info
            info = sprintf('protocol %s mode %s gain %d samprate %d \n',protocol.protocolName, obj.devices.amplifier.mode,obj.devices.amplifier.gain,protocol.params.sampratein);
            inl = fwrite(obj.fid,length(info),'uint');
            in = fwrite(obj.fid,info,'char');

            inputs = obj.getChannelNames;
            inputs = inputs.in;
            fprintf(1,'Inputs: '); fprintf(1,'%s\t',inputs{:}); fprintf(1,'\n');
            inputs = sprintf('%s ',inputs{:}); inputs = inputs(1:end-1);
            inl = fwrite(obj.fid,length(inputs),'uint');
            in = fwrite(obj.fid,inputs,'char');
            
            obj.savelistener = obj.aoSession.addlistener('DataAvailable',@obj.saveData);
            % obj.listener = obj.aoSession.addlistener('ErrorOccurred',...
            %     @(src,event) error('What the fuck?!'));

            notify(obj,'StartRun');

            obj.aoSession.IsContinuous = true;

            obj.aoSession.startBackground;    
        end
        
        function setAOSession(obj,protocol)
            % figure out what the stim vector should be
            obj.transformOutputs(protocol.next());
            obj.aoSession.queueOutputData(obj.outputs.datacolumns);
        end

        
        function stop(obj)
            obj.aoSession.stop;
            delete(obj.savelistener)
            try 
                fclose(obj.fid);
                obj.n = obj.n + 1;
            catch
                fprintf(1,'FID is invalid, not updating n\n');
            end
        end
        
        function saveData(obj,src,event)
            % fprintf(obj.fid,'%g\t',event.Data);
            % fprintf(obj.fid,'%g\t%g\t%g\n',event.Data(:,1),event.Data(:,2),event.Data(:,3));
            % fprintf(1,'*');
            % fprintf(obj.fid,'\n');
            
            % more complex version
            in = obj.transformInputs(event.Data);
            fwrite(obj.fid,in','double');
            fprintf(1,'*');
        end
        
        function in = transformInputs(obj,in)
            chids = obj.inputchannelidx;
            [~,o] = sort(chids);
            % go from highest channel id to lowest (ai7 -> ai0).  This
            % enters scaled output (always ai0) for either V or I
            for ch = length(o):-1:1
                obj.inputs.data.(obj.aiSession.Channels(chids(ch)).Name) = in(:,o(ch));
            end
            devs = fieldnames(obj.devices);
            for d = 1:length(devs)
                dev = obj.devices.(devs{d});
                if ~isempty(dev)
                    obj.inputs.data = dev.transformInputs(obj.inputs.data);
                end
            end
            for ch = length(o):-1:1
                in(:,o(ch))=obj.inputs.data.(obj.aiSession.Channels(chids(ch)).Name);
            end
        end
        
        function delete(obj)
            obj.stop;
            delete@Rig(obj)
        end
    end
    
    methods (Access = protected)
    end
end
