classdef DAQInstron < handle
    properties (SetAccess = private, Hidden = true)
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
        m_fileNameDAQ = '';
        
        % members for filtering and analysis
        m_sampleRate = 0;           % Hz
        m_samplePeriod = 0;         % s
        m_filterCutoff = 0;
        m_filterOrder = 4;
        m_gainDisplacement = 0;     % mm/V
        m_gainLoad = 0;             % N/V        
        
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
    
    methods (Access = public)
        function DI = DAQInstron(specimen)
            % Constructor for the instron DAQ data class. The single input
            % is a Specimen data object. See Specimen.m for details on
            % the specimen data class.
            %
            % DI = DAQInstron(specimen)
            %            
            DI.m_specimen = specimen;
        end
        
        function o = GetSpecimen(DI)
            % A function to get the specimen data object used to construct
            % the DAQ data object.
            %
            % Specimen = DI.GetSpecimen()
            %
            o = DI.m_specimen;
        end
        
        function SetFileName(DI,file)
            % A function to set the name of the DAQ data file.
            %
            % DI.SetFileName(file)
            %
            if ~strcmp(DI.m_fileNameDAQ,file)
                if ~exist(file,'file')
                    error('DAQInstron:DataAvailability','The specified instron DAQ file for %s does not exist.\n',DI.GetSpecimen().GetSpecimenName());
                end
                DI.m_fileNameDAQ = file;
            end
        end

        function o = GetFileName(DI)
            % A function to get the name of the DAQ data file.
            %
            % File = DI.GetFileName()
            %
            o = DI.m_fileNameDAQ;
        end
        
        function SetSampleRate(DI,rate)
            % A function to set the DAQ sample rate in Hz. The sampling
            % period is automatically updated.
            %
            % DI.SetSampleRate(rate)
            %
            if DI.m_sampleRate ~= rate
                DI.m_sampleRate = rate;
                DI.m_samplePeriod = 1/rate;
            end
        end
        function o = GetSampleRate(DI)
            % A function to get the DAQ sample rate in Hz
            %
            % Rate = DI.GetSampleRate()
            %
            o = DI.m_sampleRate;
        end
        function SetSamplePeriod(DI,period)
            % A function to set the DAQ sampling period in seconds. The
            % sampling rate is automatically updated.
            %
            % DI.SetSamplePeriod(period)
            %
            if DI.m_samplePeriod ~= period
                DI.m_samplePeriod = period;
                DI.m_sampleRate = 1/period;
            end
        end
        function o = GetSamplePeriod(DI)
            % A function to get the DAQ sampling period in seconds.
            %
            % Period = DI.GetSamplePeriod()
            %
            o = DI.m_samplePeriod;
        end
        function SetFilterCutoff(DI,cutoff)
            % A function to set the filter cutoff frequency in Hz.
            %
            % DI.SetFilterCutoff(cutoff)
            %
            if DI.m_filterCutoff ~= cutoff
                DI.m_filterCutoff = cutoff;
            end
        end
        function o = GetFilterCutoff(DI)
            % A function to get the filter cutoff frequency in Hz.
            %
            % Cutoff = DI.GetFilterCutoff()
            %
            o = DI.m_filterCutoff;
        end
        function SetFilterOrder(DI,order)
            % A function to set the filter order. The filter order must
            % be even due to the use of the filtfilt algorithm. The value
            % passed to filtfilt will be the specified order/2. Since
            % filtfilt doubles the order of the filter, the resulting
            % order will be the same as specified here. If an odd order
            % is specified, it will be incremented by one.
            %
            % DI.SetFilterOrder(order)
            %
            if DI.m_filterOrder ~= order
                if mod(order,2)
                    warning('InstronDAQ:DataValues','The filter order for %s was set to an odd number. Only even orders are accepted. The order is being increased by one.\n',DI.GetSpecimen().GetSpecimenName());
                    order = order + 1;
                end
                DI.m_filterOrder = order;
            end
        end
        function o = GetFilterOrder(DI)
            % A function to get the filter order.
            %
            % Order = DI.GetFilterOrder()
            %
            o = DI.m_filterOrder;
        end
        function SetGainDisplacement(DI,gain)
            % A function to set the displacement gain in mm/V.
            %
            % DI.SetGainDisplacement(gain)
            %
            if DI.m_gainDisplacement ~= gain
                DI.m_gainDisplacement = gain;
            end
        end
        function o = GetGainDisplacement(DI)
            % A function to get the displacement gain in mm/V.
            %
            % Gain = DI.GetGainDisplacement()
            %
            o = DI.m_gainDisplacement;
        end
        function SetGainLoad(DI,gain)
            % A function to set the load gain in N/V.
            %
            % DI.SetGainLoad(gain)
            %
            if DI.m_gainLoad ~= gain
                DI.m_gainLoad = gain;
            end
        end
        function o = GetGainLoad(DI)
            % A function to get the load gain in N/V.
            %
            % Gain = DI.GetGainLoad()
            %
            o = DI.m_gainLoad;
        end
        
        function ReadFile(DI)
            % A function to read the file specified by DI.SetFileName(file).
            %
            % DI.ReadFile()
            %
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

        function o = GetTime(DI)
            % A function to get the time vector in seconds, with t = 0
            % at the time of the trigger.
            %
            % Time = DI.GetTime()
            %
            if isempty(DI.m_trigger)
                error('InstronDAQ:DataAvailability','GetTime called for %s before the trigger data has been set.\nPerhapse call DAQInstron.CalcFilteredData()',DI.GetSpecimen().GetSpecimenName());
            end
            if isempty(DI.m_time)
                DI.ZeroTimeAtTrigger();
            end
            o = DI.m_time;
        end
        
        function o = GetForceVoltage(DI)
            % A function to get the force voltage read from the input
            % file in volts.
            %
            % Voltage = DI.GetForceVoltage()
            %
            o = DI.m_forceDAQVoltage;
        end
        function o = GetForceRaw(DI)
            % A function to get the unfilterd force in newtons.
            %
            % Force = DI.GetForceRaw()
            %
            o = DI.m_forceDAQ;
        end
        function o = GetDisplacementVoltage(DI)
            % A function to get the displacement voltage read from the
            % input file in volts.
            %
            % Voltage = DI.GetDisplacementVoltage()
            %
            o = DI.m_displacementDAQVoltage;
        end
        function o = GetDisplacementRaw(DI)
            % A function to get the unfiltered displacement in mm.
            %
            % Displacement = DI.GetDisplacement()
            %
            o = DI.m_displacementDAQ;
        end
        function o = GetStrainGauge1Raw(DI)
            % A function to get the unfiltered strain gauge data
            %
            % Strain = DI.GetStrainGauge1Raw()
            %
            o = DI.m_strainGauge1DAQ;
        end
        function o = GetStrainGauge2Raw(DI)
            % A function to get the unfiltered strain gauge data
            %
            % Strain = DI.GetStrainGauge2Raw()
            %
            o = DI.m_strainGauge2DAQ;
        end
        function o = GetStrainGauge3Raw(DI)
            % A function to get the unfiltered strain gauge data
            %
            % Strain = DI.GetStrainGauge3Raw()
            %
            o = DI.m_strainGauge3DAQ;
        end
        function o = GetTriggerRaw(DI)
            % A function to get the unfiltered trigger data. Note that
            % the trigger is never filtered, but is passed to the output
            % vector when CalcFilteredData is called internally.
            %
            % Trigger = DI.GetTriggerData()
            %
            o = DI.m_triggerDAQ;
        end
        function o = GetTimeRaw(DI)
            % A function to get the raw time vector read in from the
            % input file in seconds. This will not have t = 0 with the
            % trigger.
            %
            % Time = DI.GetTimeRaw()
            %
            o = DI.m_timeDAQ;
        end
        
        % methods to get the processed data from the class
        function o = GetForce(DI)
            % A function to get the processed force data in newtons.
            %
            % Force = DI.GetForce()
            %
            o = DI.m_force;
        end
        function o = GetDisplacement(DI)
            % A function to get the processed displacment data in mm.
            %
            % Displacement = DI.GetDisplacement()
            %
            o = DI.m_displacement;
        end
        function o = GetStrainGauge1(DI)
            % A function to get the processed strain data in absolute strain.
            %
            % Strain = DI.GetStrainGauge1()
            %
            o = DI.m_strainGauge1;
        end
        function o = GetStrainGauge2(DI)
            % A function to get the processed strain data in absolute strain.
            %
            % Strain = DI.GetStrainGauge2()
            %
            o = DI.m_strainGauge2;
        end
        function o = GetStrainGauge3(DI)
            % A function to get the processed strain data in absolute strain.
            %
            % Strain = DI.GetStrainGauge3()
            %
            o = DI.m_strainGauge3;
        end
        function o = GetPrincipalStrain1(DI)
            % A function to get the first principal strain in absolute strain.
            %
            % Strain = DI.GetPrincipalStrain1()
            %
            o = DI.m_strainGaugeP1;
        end
        function o = GetPrincipalStrain2(DI)
            % A function to get the second principal strain in absolute strain.
            %
            % Strain = DI.GetPrincipalStrain2()
            %        
            o = DI.m_strainGaugeP2;
        end
        function o = GetPrincipalStrainAngle(DI)
            % A function to get the principal strain angle in radians
            % from gauge A as defined in:
            % Budynas R.G. Advanced Strength and Applied Stress 
            % Analysis, Second ed. McGraw Hill. ISBN 0-07-008985-X
            %
            % Strain = DI.GetStrainGaugeAngle()
            %
            o = DI.m_strainGaugePhi;
        end
        function o = GetTrigger(DI)
            % A function to get the trigger data
            % 
            % Trigger = DI.GetTrigger()
            %
            o = DI.m_trigger;
        end
        
        function PrintSelf(DI)
            % A function to print out the data contained in the class
            % instance.
            %
            % DI.PrintSelf()
            %
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
        
        function Update(DI)
            % A function to call check if all the required data is available
            % and calcualte the output data. Does not call ReadFile(),
            % which must be done by the user.
            %
            % DI.Update()
            %
            
            % first check if the input data is available
            errorFlag = 0; 
            % now check that the data is available
            if ~ischar( DI.GetFileName() )
                warning('DAQInstron:DataAvailability','This error is fatal. No DAQ file name for specimen %s was provided before calling Update.\n',DI.GetSpecimen().GetSpecimenName());
                errorFlag = errorFlag + 1;
            end
            if isempty( DI.GetSampleRate() )
                warning('DAQInstron:DataAvailability','This error is fatal. The sample rate for the DAQ for sepcimen %s was not provided before calling Update.\n',DI.GetSpecimen().GetSpecimenName());
                errorFlag = errorFlag + 1;
            end
            if isempty( DI.GetFilterCutoff() )
                warning('DAQInstron:DataAvailability','This error is fatal. The filter cutoff for DAQ filtering for sepcimen %s was not provided before calling Update.\n',DI.GetSpecimen().GetSpecimenName());
                errorFlag = errorFlag + 1;
            end
            if isempty( DI.GetGainDisplacement() )
                warning('DAQInstron:DataAvailability','This error is fatal. The DAQ displacement gain for sepcimen %s was not provided before calling Update.\n',DI.GetSpecimen().GetSpecimenName());
                errorFlag = errorFlag + 1;
            end
            if isempty( DI.GetGainLoad() )
                warning('DAQInstron:DataAvailability','This error is fatal. The DAQ load gain for sepcimen %s was not provided before calling Update.\n',DI.GetSpecimen().GetSpecimenName());
                errorFlag = errorFlag + 1;
            end
            if (isempty(DI.GetForceVoltage()) || isempty(DI.GetDisplacementVoltage()) || isempty(DI.GetStrainGauge1Raw()) || isempty(DI.GetStrainGauge2Raw()) || isempty(DI.GetStrainGauge3Raw()) )
                warning('DAQInstron:DataAvailability','This error is fatal. Update was called for %s before input data had been specified.\n',DI.GetSpecimen().GetSpecimenName());
                errorFlag = errorFlag + 1;
            end
            if errorFlag
                error('DAQInstron:AnalyzeDAQData','%d errors were detected when preparing to analyze the Instron DAQ data for specimen %s.\n',errorFlag,IA.GetSpecimen().GetSpecimenName());
            end
            
            % apply the gains
            DI.ApplyGainDisplacement();
            DI.ApplyGainLoad();
            
            % filter the data
            DI.CalcFilteredData();
            
            % calculate the principal strains
            DI.CalcPrincipalStrains();
            
            % zero the time at the trigger
            DI.ZeroTimeAtTrigger();
        end
                

    end % public methods
        
    methods (Access = private, Hidden = true)
        function ApplyGainDisplacement(DI)
            % A function to apply the gain to the raw displecement vector
            %
            % DI.ApplyGainDisplacement()
            %
            if ~DI.m_gainDisplacement
                error('InstronDAQ:DataAvailability','Apply displacement gain for %s was attempted when no gain was set.\n',DI.GetSpecimen().GetSpecimenName());
            end
            DI.m_displacementDAQ = DI.m_displacementDAQVoltage * DI.m_gainDisplacement;
        end
        
        function ApplyGainLoad(DI)
            % A function to apply the gain to the raw load vector.
            %
            % DI.ApplyGainLoad()
            %
            if ~DI.m_gainLoad
                error('InstronDAQ:DataAvailability','Apply laod gain for %s was attempted when no gain was set.\n',DI.GetSpecimen().GetSpecimenName());
            end
            DI.m_forceDAQ = DI.m_forceDAQVoltage * DI.m_gainLoad;
        end
        
        function CalcFilteredData(DI)
            % A function to calculate the filtered data. Filtered data
            % will be passed into the processed data vectors. The trigger
            % data will be passed without filtering.
            %
            % DI.CalcFilteredData()
            %
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
        
        function CalcPrincipalStrains(DI)
            % A function to calculate the principal strains from the
            % filtered strain data. Must be called after CalcFilteredData()
            %
            % DI.CalcPrincipalStrains()
            %
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
        
        function ZeroTimeAtTrigger(DI)
            % A function to zero the time at the trigger index
            %
            % DI.ZeroTimeAtTrigger()
            %
            DI.m_time = DI.m_timeDAQ - DI.m_timeDAQ(find(DI.m_triggerDAQ < 4.9,1,'first'));
        end
        
    end % private methods
    
end % classdef
