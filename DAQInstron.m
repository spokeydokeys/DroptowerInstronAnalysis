classdef DAQInstron < handle
    properties (SetAccess = private)
        m_specimen;
        
        m_forceDAQVoltage;
        m_forceDAQ;
        m_displacementDAQVoltage;
        m_displacementDAQ;
        m_strainGauge1DAQ;
        m_strainGauge2DAQ;
        m_strainGauge3DAQ;
        m_triggerDAQ;
        m_timeDAQ;
        m_fileNameDAQ;
        
        % members for filtering and analysis
        m_sampleRate;           % Hz
        m_samplePeriod;         % s
        m_filterCutoff;
        m_filterOrder = 4;
        m_gainDisplacement;     % mm/V
        m_gainLoad;             % N/V        
        
        % post filtering data
        m_force;
        m_displacement;
        m_strainGauge1;
        m_strainGauge2;
        m_strainGauge3;
        m_strainGaugeP1;
        m_strainGaugeP2;
        m_strainGaugePhi;
        m_trigger;
        m_time;
    end % properties
    
    methods
        % constructor
        function DI = DAQInstron(specimen)
            DI.m_specimen = specimen;
            DI.m_sampleRate = 0;
            DI.m_samplePeriod = 0;
            DI.m_filterCutoff = 0;
            DI.m_gainDisplacement = 0;
            DI.m_gainLoad = 0;
            DI.m_fileNameDAQ = '';
        end
        
        function o = GetSpecimen(DI)
            o = DI.m_specimen;
        end
        
        % function to set the file name
        function SetFileName(DI,file)
            if ~strcmp(DI.m_fileNameDAQ,file)
                if ~exist(file,'file')
                    error('DAQInstron:DataAvailability','The specified instron DAQ file for %s does not exist.\n',DI.GetSpecimen().GetSpecimenName());
                end
                DI.m_fileNameDAQ = file;
            end
        end
        % function to get the file name
        function o = GetFileName(DI)
            o = DI.m_fileNameDAQ;
        end
        
        % fuctions to get set filtering members
        function SetSampleRate(DI,rate)
            if DI.m_sampleRate ~= rate
                DI.m_sampleRate = rate;
                DI.m_samplePeriod = 1/rate;
            end
        end
        function o = GetSampleRate(DI)
            o = DI.m_sampleRate;
        end
        function SetSamplePeriod(DI,period)
            if DI.m_samplePeriod ~= period
                DI.m_samplePeriod = period;
                DI.m_sampleRate = 1/period;
            end
        end
        function o = GetSamplePeriod(DI)
            o = DI.m_samplePeriod;
        end
        function SetFilterCutoff(DI,cutoff)
            if DI.m_filterCutoff ~= cutoff
                DI.m_filterCutoff = cutoff;
            end
        end
        function o = GetFilterCutoff(DI)
            o = DI.m_filterCutoff;
        end
        function SetFilterOrder(DI,order)
            if DI.m_filterOrder ~= order
                if mod(order,2)
                    warning('InstronDAQ:DataValues','The filter order for %s was set to an odd number. Only even orders are accepted. The order is being increased by one.\n',DI.GetSpecimen().GetSpecimenName());
                    order = order + 1;
                end
                DI.m_filterOrder = order;
            end
        end
        function o = GetFilterOrder(DI)
            o = DI.m_filterOrder;
        end
        function SetGainDisplacement(DI,gain)
            if DI.m_gainDisplacement ~= gain
                DI.m_gainDisplacement = gain;
            end
        end
        function o = GetGainDisplacement(DI)
            o = DI.m_gainDisplacement;
        end
        function SetGainLoad(DI,gain)
            if DI.m_gainLoad ~= gain
                DI.m_gainLoad = gain;
            end
        end
        function o = GetGainLoad(DI)
            o = DI.m_gainLoad;
        end
        
        % function to read the raw daq file
        function ReadFile(DI)
            if isempty(DI.m_fileNameDAQ)
                error('InstronDAQ:DataAvailablity','File read was called for %s when no file name was set.\n',DI.GetSpecimen().GetSpecimenName());
            end
            % read the file
            instron = importdata(DI.m_fileNameDAQ,',');
            % if there was a file header, the result would be a strcut. We
            % want only the data.
            if isstruct(instron)
                instron = instron.data;
            end
            % put the raw data into the correct vectors
            DI.m_timeDAQ = instron(:,1);
            DI.m_forceDAQVoltage = instron(:,6);
            DI.m_displacementDAQVoltage = instron(:,5);
            DI.m_triggerDAQ = instron(:,7);
            DI.m_strainGauge1DAQ = instron(:,2);
            DI.m_strainGauge2DAQ = instron(:,3);
            DI.m_strainGauge3DAQ = instron(:,4);
        end
        
        % function to apply the displacement gain
        function ApplyGainDisplacement(DI)
            if ~DI.m_gainDisplacement
                error('InstronDAQ:DataAvailability','Apply displacement gain for %s was attempted when no gain was set.\n',DI.GetSpecimen().GetSpecimenName());
            end
            DI.m_displacementDAQ = DI.m_displacementDAQVoltage * DI.m_gainDisplacement;
        end
        
        function ApplyGainLoad(DI)
            if ~DI.m_gainLoad
                error('InstronDAQ:DataAvailability','Apply laod gain for %s was attempted when no gain was set.\n',DI.GetSpecimen().GetSpecimenName());
            end
            DI.m_forceDAQ = DI.m_forceDAQVoltage * DI.m_gainLoad;
        end
        
        % function to filter the instron data
        function CalcFilteredData(DI)
            if ( ~DI.m_sampleRate || ~DI.m_filterCutoff || ~DI.m_filterOrder )
                error('InstronDAQ:DataAvailability','Filtering was requested for %s when either sample rate, filter cutoff, or filter order had not been specified.\n',DI.GetSpecimen().GetSpecimenName());
            end
            % design the filter
            cutoffNormal = DI.m_filterCutoff/DI.m_sampleRate;
            [b,a] = butter(DI.m_filterOrder/2,cutoffNormal); % divide order by two since filtfilt doubles the order
            
            % filter the data
            if isempty(DI.m_forceDAQ)
                warning('InstronDAQ:ExecutionOrder','Filtering of DAQ data was requested for %s before the force gain had been applied. Applying gain now.\n',DI.GetSpecimen().GetSpecimenName());
                DI.ApplyGainLoad;
            end
            DI.m_force          = filtfilt(b,a,DI.m_forceDAQ);
            if isempty(DI.m_displacementDAQ)
                warning('InstronDAQ:ExecutionOrder','Filtering of DAQ data was requested for %s before the displcaement gain had been applied. Applying gain now.\n',DI.GetSpecimen().GetSpecimenName());
                DI.ApplyGainDisplacement;
            end
            DI.m_displacement   = filtfilt(b,a,DI.m_displacementDAQ);
            DI.m_strainGauge1   = filtfilt(b,a,DI.m_strainGauge1DAQ);
            DI.m_strainGauge2   = filtfilt(b,a,DI.m_strainGauge2DAQ);
            DI.m_strainGauge3   = filtfilt(b,a,DI.m_strainGauge3DAQ);
            DI.m_trigger        = DI.m_triggerDAQ;                      % do not filter the trigger signal
        end
        
        % function to calculate the principal strains
        function CalcPrincipalStrains(DI)
            if ( isempty(DI.m_strainGauge1) || isempty(DI.m_strainGauge2) || isempty(DI.m_strainGauge3) )
                error('InstronDAQ:DataAvailability','Principal strains were requested for %s before all strain data was available.\nPerhapse you should call DAQInstron.CalcFilteredData()?',DI.GetSpecimen().GetSpecimenName());
            end
            eA = DI.m_strainGauge1;
            eB = DI.m_strainGauge2;
            eC = DI.m_strainGauge3;
            DI.m_strainGaugeP1 = (eA+eC)./2+1/2.*sqrt((eA-eC).^2+(2.*eB-eA-eC).^2);
            DI.m_strainGaugeP2 =  (eA+eC)./2-1/2.*sqrt((eA-eC).^2+(2.*eB-eA-eC).^2);
            DI.m_strainGaugePhi =  1/2.*atan((eA-2.*eB+eC)./(eA-eC));
        end
        
        % function to get the time with t=0 at the trigger
        function o = GetTime(DI)
            if isempty(DI.m_trigger)
                error('InstronDAQ:DataAvailabiliyt','GetTime called for %s before the trigger data has been set.\nPerhapse call DAQInstron.CalcFilteredData()',DI.GetSpecimen().GetSpecimenName());
            end
            if isempty(DI.m_time)
                DI.ZeroTimeAtTrigger();
            end
            o = DI.m_time;
        end
        function ZeroTimeAtTrigger(DI)
            DI.m_time = DI.m_timeDAQ - DI.m_timeDAQ(find(DI.m_triggerDAQ < 4.9,1,'first'));
        end
        
        % methods to get the raw data from the class
        function o = GetForceVoltage(DI)
            o = DI.m_forceDAQVoltage;
        end
        function o = GetForceRaw(DI)
            o = DI.m_forceDAQ;
        end
        function o = GetDisplacementVoltage(DI)
            o = DI.m_displacementDAQVoltage;
        end
        function o = GetDisplacementRaw(DI)
            o = DI.m_displacementDAQ;
        end
        function o = GetStrainGauge1Raw(DI)
            o = DI.m_strainGauge1DAQ;
        end
        function o = GetStrainGauge2Raw(DI)
            o = DI.m_strainGauge2DAQ;
        end
        function o = GetStrainGauge3Raw(DI)
            o = DI.m_strainGauge3DAQ;
        end
        function o = GetTriggerRaw(DI)
            o = DI.m_triggerDAQ;
        end
        function o = GetTimeRaw(DI)
            o = DI.m_timeDAQ;
        end
        
        % methods to get the processed data from the class
        function o = GetForce(DI)
            o = DI.m_force;
        end
        function o = GetDisplacement(DI)
            o = DI.m_displacement;
        end
        function o = GetStrainGauge1(DI)
            o = DI.m_strainGauge1;
        end
        function o = GetStrainGauge2(DI)
            o = DI.m_strainGauge2;
        end
        function o = GetStrainGauge3(DI)
            o = DI.m_strainGauge3;
        end
        function o = GetPrincipalStrain1(DI)
            o = DI.m_strainGaugeP1;
        end
        function o = GetPrincipalStrain2(DI)
            o = DI.m_strainGaugeP2;
        end
        function o = GetPrincipalStrainAngle(DI)
            o = DI.m_strainGaugePhi;
        end
        function o = GetTrigger(DI)
            o = DI.m_trigger;
        end
        
        function PrintSelf(DI)
            fprintf(1,'\n%%%%%%%%%% DAQInstron Class Parameters %%%%%%%%%%\n');
            DI.GetSpecimen().PrintSelf();
            fprintf(1,'DAQ file name: %s\n',DI.m_fileNameDAQ);
            fprintf(1,'DAQ sample rate: %f Hz\n',DI.m_sampleRate);
            fprintf(1,'DAQ sample period: %f seconds\n',DI.m_samplePeriod);
            fprintf(1,'DAQ filter cutoff frequency: %f Hz\n',DI.m_filterCutoff);
            fprintf(1,'DAQ filter order: %d\n',DI.m_filterOrder);
            fprintf(1,'Instron displacement gain %f mm/V\n',DI.m_gainDisplacement);
            fprintf(1,'Instron load gain %f N/V\n',DI.m_gainLoad);
            
            fprintf(1,'\n  %%%% Raw input data %%%%  \n');
            fprintf(1,'DAQ force voltage: [%d,%d] in volts\n',size(DI.m_forceDAQVoltage));
            fprintf(1,'DAQ force raw: [%d,%d] in newtons\n',size(DI.m_forceDAQ));
            fprintf(1,'DAQ displacement voltage: [%d,%d] in volts\n',size(DI.m_displacementDAQVoltage));
            fprintf(1,'DAQ displacement raw: [%d,%d] in mm\n',size(DI.m_displacementDAQ));
            fprintf(1,'DAQ strain gauge 1 raw: [%d,%d] in strain\n',size(DI.m_strainGauge1DAQ));
            fprintf(1,'DAQ strain gauge 2 raw: [%d,%d] in strain\n',size(DI.m_strainGauge2DAQ));
            fprintf(1,'DAQ strain gauge 3 raw: [%d,%d] in strain\n',size(DI.m_strainGauge3DAQ));
            fprintf(1,'DAQ trigger raw: [%d,%d] in volts\n',size(DI.m_triggerDAQ) );
            fprintf(1,'DAQ time raw: [%d,%d] in seconds\n',size(DI.m_timeDAQ) );
            
            fprintf(1,'\n  %%%% Analyzed data %%%%  \n');
            fprintf(1,'DAQ force: [%d,%d] in newtons\n',size(DI.m_force));
            fprintf(1,'DAQ displacement: [%d,%d] in mm\n',size(DI.m_displacement));
            fprintf(1,'DAQ strain gauge 1: [%d,%d] in strain\n',size(DI.m_strainGauge1));
            fprintf(1,'DAQ strain gauge 2: [%d,%d] in strain\n',size(DI.m_strainGauge2));
            fprintf(1,'DAQ strain gauge 3: [%d,%d] in strain\n',size(DI.m_strainGauge3));
            fprintf(1,'DAQ principal strain 1: [%d,%d] in strain\n',size(DI.m_strainGaugeP1));
            fprintf(1,'DAQ principal strain 2: [%d,%d] in strain\n',size(DI.m_strainGaugeP2));
            fprintf(1,'DAQ principal strain angle: [%d,%d] in radians\n',size(DI.m_strainGaugePhi));
            fprintf(1,'DAQ trigger: [%d,%d] in volts\n',size(DI.m_trigger));
            fprintf(1,'DAQ time: [%d,%d] in seconds\n\n',size(DI.m_time));
          
        end
        
    end % methods
    
end % classdef
