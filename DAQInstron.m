classdef DAQInstron < Specimen
    properties (SetAccess = Private)
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
        function DI = DAQInstron(name,dxa,op,data)
            DI = DI@Specimen(name,dxa,op,data)
        end
        
        % function to set the file name
        function SetFileName(DI,file)
            if DI.m_fileNameDAQ ~= file
                if ~exists(file,'file')
                    error('DAQInstron:DataAvailability','The specified instron DAQ file for %s does not exist.\n',DI.m_specimenName);
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
                    warning('InstronDAQ:DataValues','The filter order for %s was set to an odd number. Only even orders are accepted. The order is being increased by one.\n',DTDD.m_specimenName);
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
                error('InstronDAQ:DataAvailablity','File read was called for %s when no file name was set.\n',DI.m_specimenName);
            end
            % read the file
            instron = importdata(DI.m_fileNameDAQ,',');
            % put the raw data into the correct vectors
            DI.m_timeDAQ = instron.data(:,1);
            DI.m_forceDAQ = instron.data(:,6);
            DI.m_displacementDAQ = instron.data(:,5);
            DI.m_triggerDAQ = instron.data(:,7);
            DI.m_strainGauge1DAQ = instron.data(:,2);
            DI.m_strainGauge2DAQ = instron.data(:,3);
            DI.m_strainGauge3DAQ = instron.data(:,4);
        end
        
        % function to apply the displacement gain
        function ApplyGainDisplacement(DI)
            if isempty(DI.m_gainDisplacement)
                error('InstronDAQ:DataAvailability','Apply displacement gain for %s was attempted when no gain was set.\n',DI.m_specimenName);
            end
            DI.m_displacementDAQ = DI.m_displacementDAQVoltage * DI.m_gainDisplacement;
        end
        
        function ApplyGainLoad(DI)
            if isempty(DI.m_gainLoad)
                error('InstronDAQ:DataAvailability','Apply laod gain for %s was attempted when no gain was set.\n',DI.m_specimenName);
            end
            DI.m_forceDAQ = DI.m_forceDAQVoltage * DI.m_gainLoad;
        end
        
        % function to filter the instron data
        function CalcFilteredData(DI)
            if ( isempty(DI.m_sampleRate) || isempty(DI.m_filterCutoff) || isempty(DI.m_filterOrder) )
                error('InstronDAQ:DataAvailability','Filtering was requested for %s when either sample rate, filter cutoff, or filter order had not been specified.\n',DI.m_specimenName);
            end
            % design the filter
            cutoffNormal = DI.m_filterCutoff/DI.m_sampleRate;
            [b,a] = butter(DI.m_filterOrder/2,cutoffNormal); % divide order by two since filtfilt doubles the order
            
            % filter the data
            if isempty(DI.m_forceDAQ)
                warning('InstronDAQ:ExecutionOrder','Filtering of DAQ data was requested for %s before the force gain had been applied. Applying gain now.\n',DI.m_specimenName);
                DI.ApplyGainLoad;
            end
            DI.m_force          = filtfilt(b,a,DI.m_forceDAQ);
            if isempty(DI.m_displacementDAQ)
                warning('InstronDAQ:ExecutionOrder','Filtering of DAQ data was requested for %s before the displcaement gain had been applied. Applying gain now.\n',DI.m_specimenName);
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
                error('InstronDAQ:DataAvailability','Principal strains were requested for %s before all strain data was available.\nPerhapse you should call DAQInstron.CalcFilteredData()?',DI.m_specimenName);
            end
            eA = DI.m_strainGauge1;
            eB = DI.m_strainGauge2;
            eC = DI.m_strainGauge3;
            DI.m_strainGaugeP1 = (eA+eC)./2+1/2.*sqrt((eA-eC).^2+(2.*eB-eA-eC).^2);
            DI.m_strainGaugeP2 =  eA+eC)./2-1/2.*sqrt((eA-eC).^2+(2.*eB-eA-eC).^2);
            DI.m_strainGaugePhi =  1/2.*atan((eA-2.*eB+eC)./(eA-eC));
        end
        
        % function to get the time with t=0 at the trigger
        function o = GetTime(DI)
            if isempty(DI.m_trigger)
                error('InstronDAQ:DataAvailabiliyt','GetTime called for %s before the trigger data has been set.\nPerhapse call DAQInstron.CalcFilteredData()',DI.m_specimenName);
            end
            if isempty(DI.m_time)
                DI.m_time = DI.m_timeDAQ - find(DI.m_trigger < 4.9,1,'first');
            end
            o = DI.m_time;
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
        
    end % methods
    
end % classdef
