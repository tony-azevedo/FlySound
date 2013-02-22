function data = Acquire_Single_Odor(expnumber,trialduration)

% expnumber = experiment (fly or cell) number
% Raw data sampled at 10kHz and saved as separate waveforms for each trial
% Odor always on from 8 to 8.5 seconds, will have to pass in more inputs to
% change that.
% 
   
%     %%load stimulus: if stim is complicated, save a vector to be used as stim output waveform as mat file then load it
%     load(['C:\Quentin\ChRd_stim\' stimloc],'stim','samprate');
%     stim = stim';  % make sure stim is a column vector 

%%  make a directory if one does not exist
    if ~isdir(date)
        mkdir(date);
    end  

    %% access data structure and count trials check whether a saved data file exists with today's date
    D = dir([date,'/WCwaveform_',date,'_E',num2str(expnumber),'.mat']);
    if isempty(D)           % if no saved data exists then this is the first trial
        n=1 ;
    else                    %load current data file
        load([date,'/WCwaveform_',date,'_E',num2str(expnumber),'.mat']','data');
        n = length(data)+1;
    end
   
    %% set trial parameters  
    % experiment information
    data(n).date = date;                                 % experiment date
    data(n).expnumber = expnumber;                          % experiment number
    data(n).trial = n;                                        % trial number
    data(n).sampleTime = clock;
    data(n).acquisition_filename = mfilename('fullpath');    %saves name of mfile that generated data
    % sampling rates
    data(n).sampratein = 10000;                              % input sample rate
    data(n).samprateout = 10000;                           % output sample rate becomes input rate as well when both input and output present
    data(n).trialduration = trialduration;                            % trial duration

        % to pass in odor pulse parameters and manipulate them across
        % trials include these in the function definition line
        % data(n).odoronset = odoronset;                   % odor on time to
        % data(n).odorduration = odorduration;             % odor duration

    % amplifier gains to be read or used
    data(n).variableGain1 = NaN;                             %Amplifier 1 alpha
    data(n).variableOffset1 = NaN;                          %Amplifier 1 variable output offset. Determined emperically.
    data(n).ImGain1 = 10;                              
    data(n).ImOffset1 = 0;                             
%     data(n).variableGain2 = NaN;                            %Amplifier 2 alpha.
%     data(n).variableOffset2 = NaN;                          %Amplifier 2 variable output offset. Determined emperically.
%     data(n).ImGain2 = 10;                             
%     data(n).ImOffset2 = 0;                            %Amplifier 2 fixed output offset. Determined emperically.
%   
    %     %make column vector for odor command signal odor always comes on at 8s
    %     data(n).nsampout = data(n).samprateout*data(n).trialduration;
    %     data(n).odoronsetsamp = 8*data(n).samprateout+1; % odor onset sample
    %     data(n).odoroffsetsamp = data(n).odoronsetsamp+(data(n).odorduration*data(n).samprateout)-1; % odor offset sample
    %     data(n).OdorCommand = zeros(data(n).nsampout,1); % make zeros vector
    %     data(n).OdorCommand(data(n).odoronsetsamp:data(n).odoroffsetsamp) = (5*ones((data(n).odorduration*data(n).samprateout),1)) ; % make 5V during odor pulse. 
    %     data(n).OdorCommand = data(n).OdorCommand';
   
    
    %make column vector for use as master8 trigger
    data(n).Master8Trigger = [ (6*ones(100,1)) ; (zeros(((data(n).trialduration*data(n).samprateout)-100),1)) ] ;                          
    
    
    data(n).sampleTimeinexp = round(etime(data(n).sampleTime, data(1).sampleTime));
   

    %% Session based acquisition code for inputs  
    %   CHANNEL SET-UP 
%   5   AMP 1 VAR OUT  2
%   6   AMP 1 Im  2 Through conditioner B
%   7   AMP 1 10Vm  2
%   8   AMP 1 GAIN  2           these are not acquired but plugged in
                              %   1   AMP 2 VAR OUT  1
                              %   2   AMP 2 Im  1    
                              %   3   AMP 2 10 Vm  1
                              %   4   AMP 2 GAIN  1
%   9   ODOR
                              %   10  AMP 3 VAR OUT
                              %   11  AMP 3 Im     Through conditioner A
                              %   12  AMP 3 10Vm
                              %   13  AMP 3 GAIN

    s = daq.createSession('ni');
    s.addAnalogInputChannel('Dev1',[0:8],'Voltage');
    for i=1:9
        s.Channels(1,i).InputType = 'SingleEnded';
    end
%     s.DurationInSeconds = data(n).trialduration;
%     s.Rate = data(n).sampratein;
 
    s.addAnalogOutputChannel('Dev1', [0] , 'Voltage');  
    s.Rate = data(n).samprateout;
    s.queueOutputData(data(n).Master8Trigger)  
    
    x = s.startForeground();
   
    Gain1reading = mean(x(:,8));
    if Gain1reading > 0 && Gain1reading < 2.25 
        data(n).variableGain1 = .5;
    elseif Gain1reading > 2.25 && Gain1reading < 2.75
        data(n).variableGain1 = 1;
    elseif Gain1reading > 2.75 && Gain1reading < 3.25
        data(n).variableGain1 = 2;
    elseif Gain1reading > 3.25 && Gain1reading < 3.75
        data(n).variableGain1 = 5;
    elseif Gain1reading > 3.75 && Gain1reading < 4.25
        data(n).variableGain1 = 10;
    elseif Gain1reading > 4.25 && Gain1reading < 4.75
        data(n).variableGain1 = 20;
    elseif Gain1reading > 4.75 && Gain1reading < 5.25
        data(n).variableGain1 = 50;
    elseif Gain1reading > 5.25 && Gain1reading < 5.75
        data(n).variableGain1 = 100;
    elseif Gain1reading > 5.75 && Gain1reading < 6.25
        data(n).variableGain1 = 200;
    elseif Gain1reading > 6.25 && Gain1reading < 6.75
        data(n).variableGain1 = 500;
    end

    
    voltage1 = x(:,5)/data(n).variableGain1*1000;  %+data(n).variableOffset1;
    current1 = x(:,6)/data(n).ImGain1*1000;  %+data(n).ImOffset1;
  
    tenVm1 = x(:,7)*1000/10; 
    
    data(n).odorpulse = x(:,9); 
    odor = data(n).odorpulse - mean(data(n).odorpulse(1:1000));
    
      
    %% Calculate input resistance and membrane potential 

    
    data(n).Rin1 =1000*(((mean(voltage1(10:190)))- mean(voltage1(4500:5000)))/...
        ((mean(current1(10:190))-mean(current1(4500:5000)))));
    if isnan(data(n).Rin1)
        data(n).Rin1 = 0;
    end
       
%     data(n).Rin2 =1000*(((mean(voltage2(100:1900)))- mean(voltage2(5100:6900)))/...
%         ((mean(current2(100:1900))-mean(current2(5100:6900)))));
%     if isnan(data(n).Rin2)
%         data(n).Rin2 = 0;
%     end
%          
    data(n).Vrest1 =  mean(voltage1(1:200));
%     data(n).Vrest2 =  mean(voltage2(1:200));
    
    sampletimes = NaN(length(data),1); IR1 = NaN(length(data),1);% IR2 = NaN(length(data),1);
    VR1 = NaN(length(data),1);% VR2 = NaN(length(data),1);
    for i=1:length(data); sampletimes(i) = data(i).sampleTimeinexp;...
            IR1(i)=data(i).Rin1;  VR1(i)=data(i).Vrest1; end % IR2(i)=data(i).Rin2; VR2(i)=data(i).Vrest2; end
        
        

    %% PLOTS
    
    figure (1); 
    set(gcf,'Position',[25 350 1250 550],'Color',[1 1 1]);
    plot(voltage1) ;
    title(['Trial Number ' num2str(n) ]);
    ylabel('Vm (mV)');
    set(gca, 'Xlim',[0 data(n).trialduration*data(n).sampratein]);
    set(gca, 'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
    set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
    set(gca, 'Ylim' , [-70 0]);

    box off
    
    figure (2);
    plot(current1); 
    set(gcf,'Position',[25 50 1250 200],'Color',[1 1 1]);
    ylabel('Im (pA)');
    set(gca,'Xlim',[0 data(n).trialduration*data(n).sampratein]);
    set(gca,'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
    set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
    box off;
    
   
    
    figure(3);
    subplot(2,1,1), plot(sampletimes, IR1,'LineStyle','none','Marker','o',...
        'MarkerSize',7,'MarkerFaceColor', [0 0.4 0], 'MarkerEdgeColor', 'none' );
    ylabel('Rin (MOhm)');
    set(gca, 'Ylim' , [0 2000]);
    subplot(2,1,2), plot(sampletimes, VR1, 'LineStyle','none','Marker','o',...
        'markersize',7,'markerfacecolor', [0.6 0 0.4], 'markeredgecolor', 'none');
    set(gcf,'Position',[875 700 400 250],'Color',[0.8 0.4 0]);
    ylabel('Vrest (mV)');


%     figure (4);
%     set(gcf,'Position',[1300 400 1250 550],'Color',[1 1 1]);
%     plot(voltage2) ;
%     title(['Trial Number ' num2str(n) ]);
%     ylabel('Vm (mV)');
%     set(gca,'Xlim',[0 data(n).trialduration*data(n).sampratein]);
%     set(gca,'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
%     set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
%     set(gca, 'Ylim' , [-80 0]);
%     box off
%     
%     figure (5);
%     plot(current2); 
%     set(gcf,'Position',[1300 100 1250 200],'Color',[1 1 1]);
%     ylabel('Im (pA)');
%     set(gca,'Xlim',[0 data(n).trialduration*data(n).sampratein]);
%     set(gca,'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
%     set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
%     box off;
%     
%     figure(6);
%     subplot(2,1,1), plot(sampletimes, IR2,'LineStyle','none','Marker','o',...
%         'MarkerSize',7,'MarkerFaceColor', [0 0.4 0], 'MarkerEdgeColor', 'none' );
%     title('Input Resistance and Resting Potential');
%     ylabel('Rin (MOhm)');
%     subplot(2,1,2), plot(sampletimes, VR2, 'LineStyle','none','Marker','o',...
%         'markersize',7,'markerfacecolor', [0.6 0 0.4], 'markeredgecolor', 'none');
%     set(gcf,'Position',[2125 100 450 300],'Color',[0.8 0.4 0]);
%     ylabel('Vrest (mV)');
%     
    
    
    %% save data(n)
    save([date,'/WCwaveform_' data(n).date,'_E',num2str(expnumber)],'data');
    save([date,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expnumber),'_',num2str(n)],'current1','voltage1','tenVm1','odor');
    

