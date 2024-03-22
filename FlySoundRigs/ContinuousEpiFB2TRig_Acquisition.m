% ContinuousRig defines abstract property IsContinuous.
% TwoAmpRig defines RigName
classdef ContinuousEpiFB2TRig_Acquisition < ContinuousRig & TwoAmpRig 
    
    properties (Constant)
        rigName = 'ContinuousEpiFB2TRig_Acquisition';
    end
    
    properties (Hidden, SetAccess = protected)
        prevValue
        listener
        fid_analog
        fid_digital
        count
    end
    
    properties (SetAccess = protected)
        savelistener
        aiChannelNames
        aiXChannelNames
        aiXGain
        aiXRange
        aixchannelidx
        diChannelNames
        dichannelidx
        diXChannelNames 
        dixchannelidx
    end
    
    events
    end
    
    methods
        function obj = ContinuousEpiFB2TRig_Acquisition(varargin)
                         
            % ----- Make sure to add analog inputs first. ---- 
            % At some point a final channel is added for the probe_position
            obj.addDevice('refchan','ReferenceChannelAcquisition')
            obj.addDevice('piezo','Piezo_Acquisition')
            % Just add the arduino (used to depend on light
            if nargin<4
                error('continuousInRig:notEnoughInputs','Not enough inputs')
            end
            obj.updateFileNames(varargin{3:end})

            obj.addDevice('epi','LED_Arduino_Acquisition');
            % addlistener(obj.devices.epi,'ControlFlag',@obj.setArduinoControl);
            % addlistener(obj.devices.epi,'Abort',@obj.turnOffEpi);
            % addlistener(obj.devices.epi,'Override',@obj.turnOnEpi);
            % addlistener(obj,'EndRun',@obj.turnOffEpi);
            
            obj.addDevice('forceprobe','Position_Arduino')
                        
            fprintf('CONTINUOUSRIG: Fly %s, Cell %s currently has %d %s trials\n',...
                obj.flynumber,obj.cellnumber,obj.n-1,obj.protocol.protocolName);
                        
            obj.setAnalogInputs;
            obj.setDigitalInputs;
        end
    
        
        function run(obj,protocol,varargin)
            if obj.daq.Running
                return
            end
            if ~isempty(fopen('all'))
                fids = fopen('all');
                for fid = 1:length(fids)
                    [filename] = fopen(fids(fid));
                    if contains(filename,'.bin') && contains(filename,obj.name(1:35))
                        st = fclose(fids(fid));
                        if ~st
                            fprintf('Closing previously opened file:\n%s\n',filename)
                        end
                    end
                end
            end
            obj.devices.amplifier_1.getmode;
            obj.devices.amplifier_1.getgain;

            obj.devices.amplifier_2.getmode;
            obj.devices.amplifier_2.getgain;
            %obj.setOutputs;

            obj.daq.Rate = protocol.params.samprateout;

            obj.setDaq(protocol);

            obj.daq.ScansRequiredFcn = @obj.writeMoreData;
            obj.setAnalogInputs;
            obj.setDigitalInputs;
            obj.mapInputNamesToInColumns;
            obj.getInputChannelGain;
            
            [obj.name,aname,dname] = obj.getFileName;

            % Writing to two binary files, one analog, one digital
            % one more check to ensure that the file name is ok and no data
            % is overwritten.
            while exist(aname,'file')
                warning('File already exists');
                obj.n = obj.n+1;
                [obj.name,aname,dname] = obj.getFileName;
            end

            obj.fid_analog = fopen(aname,'w');
            obj.fid_digital = fopen(dname,'w');

            obj.writeHeader
            
            % obj.savelistener = obj.daq.addlistener('DataAvailable',@obj.saveData);
            obj.daq.ScansAvailableFcnCount = obj.daq.Rate;
            obj.daq.ScansAvailableFcn = @obj.saveData;

            notify(obj,'StartRun');

            obj.count = 0;
            notify(obj,'SaveData');
            
            msgbox('Use Pyas to send the target values','Target');

            obj.daq.start("Continuous")

        end
        
        function writeMoreData(obj,source,event)
            write(obj.daq,obj.outputs.datacolumns)
        end

        function setDaq(obj,protocol)
            % figure out what the stim vector should be
            obj.daq.flush()
            obj.transformOutputs(protocol.next());
            
            columnsforfirsttime = obj.outputs.datacolumns;
            % the first time through, wait the preperiod to turn on epi
            for ch = 1:length(obj.outputchannelidx)
                if strcmp('epittl',obj.daq.Channels(obj.outputchannelidx(ch)).Name)
                    epioffcolumn = obj.outputs.datacolumns(:,ch);
                    epioffcolumn(1:protocol.params.preDurInSec*protocol.params.samprateout) = 0;
                    columnsforfirsttime(:,ch) = epioffcolumn;
                end
            end
            obj.daq.preload(columnsforfirsttime);
        end

        
        function stop(obj)
            obj.daq.stop;
            obj.daq.flush;
            % obj.daq.wait;
            % obj.devices.epi.abort
            delete(obj.savelistener)
            try 
                fclose(obj.fid_analog);
                fclose(obj.fid_digital);
                obj.n = obj.n + 1;
                notify(obj,'IncreaseTrialNum');
            catch
                fprintf(1,'Analog and digital FIDs not open. n = %d\n',obj.n);
                notify(obj,'IncreaseTrialNum');
            end
            systemsound('Notify');
        end
        
        function [filename,aname,dname] = getFileName(obj)
            % double check the names here. Don't overwrite files
            filename = [obj.D,'\',obj.protocol.protocolName,'_ContRaw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_' num2str(obj.n) '.bin'];
            aname = regexprep(filename,'.bin','_A.bin');
            dname = regexprep(filename,'.bin','_D.bin');
        end
            
        
        function writeHeader(obj)
            % using < to open, > to close
            
            fprintf(1,'<%s>\n',obj.name);
            % header contains the length of the filename
            [~,aname,dname] = obj.getFileName;
            fwrite(obj.fid_analog,['<',aname,'>'],'char');
            fwrite(obj.fid_digital,['<',dname,'>'],'char');

            fprintf(1,'<protocol %s samprate %d >\n',obj.protocol.protocolName, obj.protocol.params.sampratein);
            % header contains the length of the info
            info = sprintf('<protocol %s samprate %d>',obj.protocol.protocolName, obj.protocol.params.sampratein);
            fwrite(obj.fid_analog,info,'char');
            fwrite(obj.fid_digital,info,'char');

            % add the ch names and gains to analog header
            fprintf(1,'Analog Inputs: '); fprintf(1,'%s\t',obj.aiXChannelNames{:}); fprintf(1,'\n');
            inputs = sprintf('%s ',obj.aiXChannelNames{:}); 
            inputs = inputs(1:end-1);
            inputs = ['<',inputs,'>'];
            fwrite(obj.fid_analog,inputs,'char');
            
            fprintf(1,'Gains: '); fprintf(1,'%g\t',obj.aiXGain(:)); fprintf(1,'\n');
            fwrite(obj.fid_analog,'<','char');
            fwrite(obj.fid_analog,obj.aiXGain,'double');
            fwrite(obj.fid_analog,'>','char');
            
            % add channel names to digital channel (no gain - bits)
            fprintf(1,'Inputs: '); fprintf(1,'%s\t',obj.diXChannelNames{:}); fprintf(1,'\n');
            inputs = sprintf('%s ',obj.diXChannelNames{:}); 
            inputs = inputs(1:end-1);
            inputs = ['<',inputs,'>'];
            fwrite(obj.fid_digital,inputs,'char');

            % To debug in future, saves all the bit signals for int12
            % probe_position
            % fprintf(1,'Digital Inputs: '); fprintf(1,'%s\t',obj.diChannelNames{~contains(obj.diChannelNames,'b_sign')}); fprintf(1,'\n');
            % inputs = sprintf('%s ',obj.diChannelNames{~contains(obj.diChannelNames,'b_sign')}); 
            % inputs = inputs(1:end-1);
            % inputs = ['<',inputs,'>'];
            % fwrite(obj.fid_digital,inputs,'char');
        end
            
        function saveData(obj,temp,event)
            in = event.Source.read;
            [ain,din] = obj.transformInputs(in.Data);
            fwrite(obj.fid_analog,ain','int16');
            fwrite(obj.fid_digital,din','ubit1');
            fprintf(1,'*');
            obj.count = obj.count+1;
            if obj.count>=60
                fprintf(1,'\n');
                obj.count = 0;
            end
            % obj.stop;
        end
        
        function [ain_int16,din] = transformInputs(obj,in2)
            % In this overwritten function, I need to maitain the 16
            % values of the input, but also transorm the probe_position.
            % I do not need to calculate gains
            persistent range
            if isempty(range)
                range = repmat(obj.aiXRange,size(in2,1),1);
            elseif size(range,1) ~= size(in2,1)
                range = repmat(obj.aiXRange,size(in2,1),1);
            end
            
            chids = obj.inputchannelidx;
            [~,o] = sort(chids);
            for ch = length(o):-1:1
                if startsWith(obj.daq.Channels(chids(ch)).Name,'b_')
                    obj.inputs.data.(obj.daq.Channels(chids(ch)).Name) = in2(:,o(ch));
                    %obj.inputs.data.(obj.daq.Channels(chids(ch)).Name) = in.(obj.daq.Channels(chids(ch)).Name);
                end
            end
            obj.inputs.data = obj.devices.forceprobe.transformInputs(obj.inputs.data,'int12');
            
            ain = in2(:,obj.aixchannelidx); % obj.aix has an additional channel for probeposition
            ain_int16 = int16(ain ./ range * 2^15);
            ain_int16(:,strcmp(obj.aiXChannelNames,'probe_position')) = int16(obj.inputs.data.probe_position);
            
            
            din = in2(:,obj.dixchannelidx);
            % If you want to keep all the bits for int12 probe position
            %din = in(:,obj.dichannelidx);
        end
        
        function getInputChannelGain(obj)
            % In this overwritten function, I need to maitain the 16 bit
            % values of the input, but also transorm the probe_position
             
            chids = obj.inputchannelidx;
            [~,o] = sort(chids);
            % go from highest channel id to lowest (e.g. ai7 -> ai0).  This
            % enters scaled output (always ai0) for either V or I
            in = ones(size(chids));
            for ch = length(o):-1:1
                gain.(obj.daq.Channels(chids(ch)).Name) = in(:,o(ch));
                if isa(obj.daq.Channels(chids(ch)),'daq.ni.AnalogInputVoltageChannel')
                    range.(obj.daq.Channels(chids(ch)).Name) = abs(obj.daq.Channels(chids(ch)).Range.Min);
                end
            end
            % Probe position range
            range.probe_position = 4096;
            
            devs = fieldnames(obj.devices);
            for d = 1:length(devs)
                dev = obj.devices.(devs{d});
                if ~isempty(dev)
                    gain = dev.transformInputs(gain);
                end
            end
            
            for ch = 1:length(obj.aiXChannelNames)
                % obj.aiXGain will be the number to multiply by double converted int16 values 
                % e.g. a value of -2^15 will be  -10V, then muliplied by
                % gain
                if strcmp(obj.aiXChannelNames{ch},'probe_position')
                    % the 12bit values will be stored as in16
                    % when read, double(x)*aiXGain will divide by 2^12 and
                    % multiply by window width
                    obj.aiXGain(:,ch)=gain.(obj.aiXChannelNames{ch}) / range.(obj.aiXChannelNames{ch}) ;                    
                    obj.aiXRange(:,ch)= range.(obj.aiXChannelNames{ch}) ;                    
                else
                    % 16 bit values will be stored as in16
                    % when read, double(x)*aiXGain will divide by 2^12 and
                    % multiply by window width
                    obj.aiXGain(:,ch)=gain.(obj.aiXChannelNames{ch}) * range.(obj.aiXChannelNames{ch}) / 2^15;
                    obj.aiXRange(:,ch)= range.(obj.aiXChannelNames{ch}) ;                    
                end
            end
        end 
        
        
        function delete(obj)
            obj.stop;
            delete@Rig(obj)
        end
    end
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.testcurrentstepamp = 0;
            obj.params.testvoltagestepamp = 0;
            obj.params.teststep_start = 0.010;
            obj.params.teststep_dur = 0.050;
            obj.params.interTrialInterval = 0;
        end

        function setAnalogInputs(obj)
            % These will be stored with a gain value in the header, below
            % the column name, as 16 bit values
            [inputs,avsd] = obj.getChannelNames;
            obj.aiChannelNames = inputs.in(avsd.in);
            obj.aiXChannelNames = [obj.aiChannelNames,{'probe_position'}];
        end
        
        function setDigitalInputs(obj)
            % These will be stored with a gain value in the header, below
            % the column name
            [inputs,avsd] = obj.getChannelNames;
            obj.diChannelNames = inputs.in(~avsd.in);
            obj.diXChannelNames = obj.diChannelNames(~startsWith(obj.diChannelNames,'b_'));
        end

        function mapInputNamesToInColumns(obj)
            chids = obj.inputchannelidx;
            [~,o] = sort(chids); % o is the column order for each input
            obj.aixchannelidx = false(size(o));
            obj.dixchannelidx = false(size(o));
            obj.dichannelidx = false(size(o));
            % Find the columns with analog input, plus an extra
            for ch = length(o):-1:1
                if any(contains(obj.aiXChannelNames, obj.daq.Channels(chids(ch)).Name)) ...
                        || strcmp('b_sign', obj.daq.Channels(chids(ch)).Name)
                    obj.aixchannelidx(ch) = true;
                end
                if any(contains(obj.diXChannelNames, obj.daq.Channels(chids(ch)).Name))
                    obj.dixchannelidx(ch) = true;
                end
                if any(contains(obj.diChannelNames, obj.daq.Channels(chids(ch)).Name)) ...
                        && ~strcmp('b_sign', obj.daq.Channels(chids(ch)).Name)
                    obj.dichannelidx(ch) = true;
                end
            end
        end
                
    end
end
