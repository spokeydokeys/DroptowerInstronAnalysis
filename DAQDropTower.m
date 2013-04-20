classdef DAQDropTower < handle
    properties (SetAccess = private, Hidden = false)
        m_specimen;    
    end
    properties (SetAccess = private, Hidden = true)
        % members for the raw data
        m_forceSixDAQVoltage;
        m_forceSixDAQ;
        m_forceOneDAQVoltage;
        m_forceOneDAQ;
        m_strainGauge1DAQ;
        m_strainGauge2DAQ;
        m_strainGauge3DAQ;
        m_triggerDAQ;
        m_timeDAQ;
        m_fileNameDAQ = '';
        m_forceOneZeroed = false; % flag to check if the force trace has be zeroed. Used in the filtering method
        m_forceSixZeroed = false;
        m_indexTrigger;
        
        % members for the filtering and analysis
        m_sampleRate = 20000; %Hz
        m_samplePeriod = 1/20000; %s
        m_filterCutoff = 500; % Hz
        m_filterOrder = 4;
        m_excitation = 12; %V
        m_calibrationForceSix = [13344.7/-.0023141 13344.7/.0023088 13344.7/-.0009144 451.9/-.0018758 451.9/.0019116 226/.0015509];
        m_calibrationForceOne = 22241.1/.00300293;
        
        % post filtering data
        m_forceSix;
        m_forceOne;
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
        function DD = DAQDropTower(specimen)
            % A class to perform the Drop Tower DAQ analysis. It is
            % constructed using a specimen. See Specimen.m for details
            % on the specimen type.
            %
            % DD = DAQDropTower(specimen)
            %
            DD.m_specimen = specimen;
        end
        
        function SetFileName(DD,file)
            % A function to set the file name for the drop tower DAQ
            % analysis.
            %
            % DD.SetFileName(file)
            %
            if ~strcmp(DD.m_fileNameDAQ,file)
                if ~exist(file,'file')
                    error('DAQDropTower:DataAvailability','The DAQ file specified for %s does not exist.\n',DD.GetSpecimen().GetSpecimenName());
                end
                DD.m_fileNameDAQ = file;
            end
        end
        function o = GetFileName(DD)
            % A function to get the file name for the drop tower DAQ.
            %
            % FileName = DD.GetFileName()
            %
            o = DD.m_fileNameDAQ;
        end
        
        
        function o = GetSpecimen(DD)
            o = DD.m_specimen;
        end
        
        function SetSampleRate(DD,rate)
            % A function to set the sample rate of the drop tower DAQ in
            % Hz.
            % The default value is 20000 Hz.
            % Automatically updates the sample period.
            %
            % DD.SetSampleRate(rate)
            %
            if DD.m_sampleRate ~= rate
                DD.m_sampleRate = rate;
                DD.m_samplePeriod = 1/rate;
            end
        end
        function o = GetSampleRate(DD)
            % A function to get the drop tower sample rate.
            %
            % SampleRate = DD.GetSampleRate()
            %
            o = DD.m_sampleRate;
        end
        
        function SetSamplePeriod(DD,period)
            % A function to set the sample period of the drop tower DAQ
            % in seconds.
            % The default value is 50 microseconds (rate = 20 kHz)
            % Automatically updates the sample rate.
            %
            % DD.SetSamplePeriod(period)
            %
            if DD.m_samplePeriod ~= period
                DD.m_samplePeriod = period;
                DD.m_sampleRate = 1/period;
            end
        end
        function o = GetSamplePeriod(DD)
            % A function to get the drop tower sample period.
            %
            % SamplePeriod = DD.GetSamplePeriod()
            %
            o = DD.m_samplePeriod;
        end
        
        function SetFilterCutoff(DD,cutoff)
            % A function to set the drop tower filter cutoff frequency
            % in Hz.
            %
            % DD.SetFilterCutoff(cutoff)
            %
            if DD.m_filterCutoff ~= cutoff
                DD.m_filterCutoff = cutoff;
            end
        end
        function o = GetFilterCutoff(DD)
            % A function to get the cutoff frequency of the drop tower
            % filter in Hz.
            %
            % Cutoff = DD.GetFilterCutoff()
            %
            o = DD.m_filterCutoff;
        end
        
        function SetFilterOrder(DD,order)
            % A function to set the order of the drop tower DAQ filter.
            % Since the data is forward-reversed filtered, only even 
            % filter orders are accepted. During filtering a value equal
            % to order/2 will be passed to filtfilt, resulting in a
            % final filter order equal to the input of this function.
            %
            % The order input here must be even, and if an odd order is
            % supplied, the final order will be supplied order + 1.
            %
            % DD.SetFilterOrder(order)
            %
            if DD.m_filterOrder ~= order
                 if mod(cutoff,2)
                    warning('DAQDropTower:DataValues','The filter order for %s was set to an odd number. Only even filter orders are accepted. The order of the filter will be incremented by one.\n',DD.GetSpecimen().GetSpecimenName());
                    order = order + 1;
                end
                DD.m_filterOrder = order;
            end
        end
        function o = GetFilterOrder(DD)
            % A function to get the filter order used to filter the drop
            % tower data.
            %
            % Order = DD.GetFilterOrder()
            %
            o = DD.m_filterOrder;
        end
        
        function SetExcitation(DD,volts)
            % A function to set the exitation of the load cells in 
            % volts. The default value is 12 V.
            % 
            % DD.SetExcitation(volts)
            %
            if DD.m_excitation ~= volts
                DD.m_excitation = volts;
            end
        end
        function o = GetExcitation(DD)
            % A function to get the exictation of the load cells in 
            % volts.
            %
            % Excitation = DD.GetExcitation()
            %
            o = DD.m_excitation;
        end        
        
        function SetCalibrationForceSix(DD,cal)
            % A function to set the calibration vector for the six axis
            % load cell. The default value is:
            % [13344.7/-.0023141 13344.7/.0023088 13344.7/-.0009144 451.9/-.0018758 451.9/.0019116 226/.0015509] N/mV/V_excitation
            %
            % DD.SetCalibrationForceSix(calibration)
            %
            if DD.m_calibrationForceSix ~= cal
                DD.m_calibrationForceSix = cal;
            end            
        end
        function o = GetCalibrationForceSix(DD)
            % A function to get the calibration vector for the six axis
            % load cell in N/mV/V_excitation.
            %
            % Calibration = DD.GetCalibrationForceSix()
            %
            o = DD.m_calibrationForceSix;
        end
        
        function SetCalibrationForceOne(DD,cal)
            % A function to set the calibration for the single axis load
            % cell. The default value is: 22241.1/.00300293 N/mV/V_excitation
            %
            % DD.SetCalibrationForceOne(calibration)
            %
            if DD.m_calibrationForceOne ~= cal
                DD.m_calibrationForceOne = cal;
            end
        end
        function o = GetCalibrationForceOne(DD)
            % A function to get the calibration for the single axis load
            % cell in N/mV/V_excitation.
            %
            % Calibration = DD.GetCalibrationForceOne()
            %
            o = DD.m_calibrationForceOne;
        end
        
        function ReadFile(DD)
            % A function to read the DAQ file specified. To set the file
            % name use DD.SetFileName(file)
            %
            % DD.ReadFile()
            %
            
            % check if m_fileName is full
            if isempty(DD.GetFileName())
                error('DropTowerDAQ:DataAvailablity','File Read was called for %s before the file name was set.\nUse DD.SetFileName(name) to set the file name.\n',DD.GetSpecimen().GetSpecimenName());
            end           
            
            % read file
            droptowerFID = fopen(DD.GetFileName(),'r');
            droptower = textscan(droptowerFID,'%f %f %f %f %f %f %f %f %f %f %f %f','delimiter',',');
            fclose(droptowerFID);
            
            % put data into members            
            DD.m_timeDAQ = droptower{1};
            
            DD.m_strainGauge1DAQ = droptower{2};
            DD.m_strainGauge2DAQ = droptower{3};
            DD.m_strainGauge3DAQ = droptower{4};
            
            DD.m_forceSixDAQVoltage(:,1) = droptower{5}; % f_x
            DD.m_forceSixDAQVoltage(:,2) = droptower{6}; % f_y
            DD.m_forceSixDAQVoltage(:,3) = droptower{7}; % f_z
            DD.m_forceSixDAQVoltage(:,4) = droptower{8}; % m_x
            DD.m_forceSixDAQVoltage(:,5) = droptower{9}; % m_y
            DD.m_forceSixDAQVoltage(:,6) = droptower{10};% m_z
            
            DD.m_forceOneDAQVoltage = droptower{11};
            
            DD.m_triggerDAQ = droptower{12};
        end
        
        function o = GetTime(DD)
            % A function to get the time vector starting with t = 0s at
            % the trigger.
            %
            % Time = DD.GetTime()
            %
            o = DD.m_time;
        end
        
        function o = GetForceSix(DD)
            % A function to get the six axis load cell matrix. The matrix
            % is in the format [F_x,F_y,F_z,M_x,M_y,M_z]. Returns the
            % fully processed matrix of data with forces in N and
            % moments in Nm.
            %
            % ForceData = DD.GetForceSix()
            %
            o = DD.m_forceSix;
        end
        function o = GetForceOne(DD)
            % A function to get the single axis load cell vector.
            % Returns the fully processed vector in N.
            %
            % ForceData = DD.GetForceOne()
            %
            o = DD.m_forceOne;
        end
        function o = GetStrainGauge1(DD)
            % A function to get the strain data from the first gauge.
            % Returns the strain in absolute strain.
            %
            % Strain = DD.GetStrainGauge1()
            %
            o = DD.m_strainGauge1;
        end
        function o = GetStrainGauge2(DD)
            % A function to get the strain data from the second gauge.
            % Returns the strain in absolute strain.
            %
            % Strain = DD.GetStrainGauge2()
            %
            o = DD.m_strainGauge2;
        end
        function o = GetStrainGauge3(DD)
            % A function to get the strain from the thrid gauge.
            % Returns the strain in absolute strain.
            %
            % Strain = DD.GetStrainGauge3()
            %
            o = DD.m_strainGauge3;
        end
        function o = GetPrincipalStrain1(DD)
            % A function to get the first principal strain. Returns
            % the strain in absolute strain.
            %
            % Strain = DD.GetPrincipalStrain1()
            %
            o = DD.m_strainGaugeP1;
        end
        function o = GetPrincipalStrain2(DD)
            % A function to get the second principal strain. Returns
            % the strain in absolute strain.
            %
            % Strain = DD.GetPrincipalStrain2()
            %
            o = DD.m_strainGaugeP2;
        end
        function o = GetPrincipalStrainAngle(DD)
            % A function to get the principal strain angle. Returns the
            % angle in radians from gauge A as defined in Appendix G of:
            % Budynas R.G. Advanced Strength and Applied Stress 
            % Analysis, Second ed. McGraw Hill. ISBN 0-07-008985-X
            %
            % Angle = DD.GetPrincipalStrainAngle()
            %
            o = DD.m_strainGaugePhi;
        end
        function o = GetTrigger(DD)
            % A function to get the trigger vector. The trigger vector
            % is never filtered, but is transferred from the raw data
            % vector to the output data vector when 
            % DD.CalcFilteredData() is called.
            %
            % Trigger = DD.GetTrigger()
            %
            o = DD.m_trigger;
        end
        function o = GetForceSixVoltage(DD)
            % A function to get the six axis load cell voltage data.
            % Returns the raw data loaded from the input file in the
            % form [F_x,F_y,F_z,M_x,M_y,M_z].
            %
            % Voltages = DD.GetForceSixVoltage()
            %
            o = DD.m_forceSixDAQVoltage;
        end
        function o = GetForceSixRaw(DD)
            % A function to get the six axis loac cell raw force data.
            % Returns the calibrated force data with no offset removal or
            % filtering in [F_x,F_y,F_z,M_x,M_y,M_z] with forces in N
            % and moments in Nm.
            %
            % Forces = DD.GetForceSixRaw()
            %
            o = DD.m_forceSixDAQ;
        end
        function o = GetForceOneVoltage(DD)
            % A function to get the single axis load cell voltage data.
            % Returns the raw data loaded from the input file.
            %
            % Voltage = DD.GetForceOneVoltage(DD)
            %
            o = DD.m_forceOneDAQVoltage;
        end
        function o = GetForceOneRaw(DD)
            % A function to get the single axis load cell raw force data.
            % Returns the calibrated force data with no offset removal or
            % filtering in N.
            %
            % Force = DD.GetForceOneRaw()
            %
            o = DD.m_forceOneDAQ;
        end
        function o = GetStrainGauge1Raw(DD)
            % A function to get the raw strain gauge data read from the
            % input file.
            %
            % Strain = DD.GetStrainGauge1Raw()
            %
            o = DD.m_strainGauge1DAQ;
        end
        function o = GetStrainGauge2Raw(DD)
            % A function to get the raw strain gauge data read from the
            % input file.
            %
            % Strain = DD.GetStrainGauge2Raw()
            %
            o = DD.m_strainGauge2DAQ;
        end
        function o = GetStrainGauge3Raw(DD)
            % A function to get the raw strain gauge data read from the
            % input file.
            %
            % Strain = DD.GetStrainGauge3Raw()
            %
            o = DD.m_strainGauge3DAQ;
        end
        function o = GetTriggerRaw(DD)
            % A function to get the raw trigger data from the input file.
            %
            % Trigger = DD.GetTriggerRaw()
            %
            o = DD.m_triggerDAQ;
        end
        function o = GetTimeRaw(DD)
            % A function to get the raw time data read from the input
            % file. This time will not be zeroed at the time of the
            % trigger.
            %
            % Time = DD.GetTimeRaw()
            %
            o = DD.m_timeDAQ;
        end
        
        function Update(DD)
            % A funtion that checks for all needed data and executes the
            % filter in the correct order. It does not read the input file
            % so that must be done first by the user.
            %
            % DD.Update()
            %
            
            % first check the input data is available
            if (isempty(DD.m_forceSixDAQVoltage) || isempty(DD.m_forceOneDAQVoltage) || isempty(DD.m_strainGauge1DAQ) || isempty(DD.m_strainGauge2DAQ) || isempty(DD.m_strainGauge3DAQ) || isempty(DD.m_triggerDAQ) || isempty(DD.m_timeDAQ))
                  error('DropTowerDAQ:DataAvailability','Update called for %s when no raw data is available.\nPerhapse call DD.ReadFile().\n',DD.GetSpecimen().GetSpecimenName());
            end
            
            % calibrate the load cells
            DD.CalibrateForceSix();
            DD.CalibrateForceOne();
            
            % zero the data
            DD.ZeroForceSix();
            DD.ZeroForceOne();
            
            % filter the data
            DD.CalcFilteredData();
            
            % calculate the principal strains
            DD.CalcPrincipalStrains();
            
        end
        
        function PrintSelf(DD)
            % A function to print out all of the data contained in the class
            %
            % DD.PrintSelf()
            %
            fprintf(1,'\n%%%%%%%%%% DAQDropTower Class Parameters %%%%%%%%%%\n');
            DD.GetSpecimen().PrintSelf();
            fprintf(1,'\n %%%% Scalar Members and Properties %%%%\n');
            fprintf(1,'DAQ file name: %s\n',DD.GetFileName());
            fprintf(1,'DAQ sample rate: %f Hz\n',DD.GetSampleRate());
            fprintf(1,'DAQ sample period: %f s\n',DD.GetSamplePeriod());
            fprintf(1,'DAQ filter cutoff frequency: %f Hz\n',DD.GetFilterCutoff());
            fprintf(1,'DAQ filter order: %d\n',DD.GetFilterOrder());
            fprintf(1,'Load cell excitation: %f V\n',DD.GetExcitation());
            fprintf(1,'Six axis calibration vector:\n\t[%13.2f\n\t %13.2f\n\t %13.2f\n\t %13.2f\n\t %13.2f\n\t %13.2f] (N/mV)/V_excite\n',DD.GetCalibrationForceSix);
            fprintf(1,'Single axis calibration: %13.2f (N/mV)/V_excite\n',DD.GetCalibrationForceOne());
            fprintf(1,'Six axis load cell data zeroed: %i\n',DD.m_forceSixZeroed);
            fprintf(1,'Single axis load cell data zeroed: %i\n',DD.m_forceOneZeroed);
            
            fprintf(1,'\n  %%%% Raw input data %%%%  \n');
            fprintf(1,'DAQ six axis force voltage: [%d,%d] in volts\n',size( DD.GetForceSixVoltage() ));
            fprintf(1,'DAQ six axis force raw: [%d,%d] in newtons\n',size( DD.GetForceSixRaw() ));
            fprintf(1,'DAQ single axis force voltage: [%d,%d] in volts\n',size( DD.GetForceOneVoltage() ));
            fprintf(1,'DAQ single axis force raw: [%d,%d] in newtons\n',size( DD.GetForceOneRaw() ));           
            fprintf(1,'DAQ strain gauge 1 raw: [%d,%d] in strain\n',size( DD.GetStrainGauge1Raw() ));
            fprintf(1,'DAQ strain gauge 2 raw: [%d,%d] in strain\n',size( DD.GetStrainGauge2Raw() ));
            fprintf(1,'DAQ strain gauge 3 raw: [%d,%d] in strain\n',size( DD.GetStrainGauge3Raw() ));
            fprintf(1,'DAQ trigger raw: [%d,%d] in volts\n',size( DD.GetTriggerRaw() ));
            fprintf(1,'DAQ time raw: [%d,%d] in seconds\n',size( DD.GetTimeRaw() ));
            
            fprintf(1,'\n  %%%% Analyzed data %%%%  \n');
            fprintf(1,'DAQ six axis force: [%d,%d] in newtons\n',size( DD.GetForceSix() ));
            fprintf(1,'DAQ single axis force: [%d,%d] in newtons\n',size( DD.GetForceOne() ));           
            fprintf(1,'DAQ strain gauge 1: [%d,%d] in strain\n',size( DD.GetStrainGauge1() ));
            fprintf(1,'DAQ strain gauge 2: [%d,%d] in strain\n',size( DD.GetStrainGauge2() ));
            fprintf(1,'DAQ strain gauge 3: [%d,%d] in strain\n',size( DD.GetStrainGauge3() ));
            fprintf(1,'DAQ principal strain 1: [%d,%d] in strain\n',size( DD.GetPrincipalStrain1() ));
            fprintf(1,'DAQ principal strain 2: [%d,%d] in strain\n',size( DD.GetPrincipalStrain2() ));
            fprintf(1,'DAQ principal strain angle: [%d,%d] in radians\n',size( DD.GetPrincipalStrainAngle() ));
            fprintf(1,'DAQ trigger: [%d,%d] in volts\n',size( DD.GetTrigger() ));
            fprintf(1,'DAQ time: [%d,%d] in seconds\n\n',size( DD.GetTime() ));
            
        end
    end % methods public
        
    methods (Access = private, Hidden = true)                    
        function CalibrateForceSix(DD)
            % A function that applies the exitation value to the 
            % six axis load cell calibration vector and scales the
            % voltages in the six axis load cell voltage matrix to get 
            % the force.
            %
            % DD.CalibrateForceSix()
            %
            if isempty(DD.GetForceSixVoltage())
                error('DropTowerDAQ:DataAvailablity','Unable to calibrate six axis load cell for %s. Load cell data not loaded.\n',DD.GetSpecimen().GetSpecimenName())
            end
            
            cal = DD.GetCalibrationForceSix().*1/DD.GetExcitation();
            
            DD.m_forceSixDAQ = zeros(size(DD.GetForceSixVoltage()));
            forceVoltages = DD.GetForceSixVoltage();
            
            for i = 1:length(DD.GetForceSixVoltage())
                DD.m_forceSixDAQ(i,:) = forceVoltages(i,:).*cal;
            end           
        end
        
        function CalibrateForceOne(DD)
            % A function that applies the exitation value to the single
            % axis load cell calibration value and scales teh voltages
            % in the single axis load cell vector to get forces.
            %
            % DD.CalibrateForceOne()
            %
            if isempty(DD.GetForceOneVoltage())
                error('DropTowerDAQ:DataAvailablity','Unable to calibrate single axis load cell for %s. Load cell data not loaded.\n',DD.GetSpecimen().GetSpecimenName())
            end
            
            cal = DD.GetCalibrationForceOne()*1/DD.GetExcitation();
            
            DD.m_forceOneDAQ = DD.GetForceOneVoltage()*cal;
            
        end
        
        function ZeroForceSix(DD)
            % A function to zero the six axis load cell data. Uses the
            % average data before the trigger to zero the entire data
            % trace. Operates only on calibrated data, so will call
            % DD.CalibrateForceSix() if the six axis data vectors are
            % empty.
            %
            % DD.ZeroForceSix()
            %
            if isempty(DD.GetForceSixRaw() )
                warning('DropTowerDAQ:DataAvailability','Zeroing of the six axis load cell for %s was requested before calibration. Calibration will be carried out now.\n',DD.GetSpecimen().GetSpecimenName());
                DD.CalibrateForceSix();
            end
            
            idxTrig = DD.GetIndexTrigger();
            forceRaw = DD.GetForceSixRaw();
            
            forcePreTrig = mean(forceRaw(1:idxTrig,:));
            DD.m_forceSixDAQ(:,1) = DD.m_forceSixDAQ(:,1) - forcePreTrig(1);
            DD.m_forceSixDAQ(:,2) = DD.m_forceSixDAQ(:,2) - forcePreTrig(2);
            DD.m_forceSixDAQ(:,3) = DD.m_forceSixDAQ(:,3) - forcePreTrig(3);
            DD.m_forceSixDAQ(:,4) = DD.m_forceSixDAQ(:,4) - forcePreTrig(4);
            DD.m_forceSixDAQ(:,5) = DD.m_forceSixDAQ(:,5) - forcePreTrig(5);
            DD.m_forceSixDAQ(:,6) = DD.m_forceSixDAQ(:,6) - forcePreTrig(6);
            
            DD.m_forceSixZeroed = true;
        end
        
        function ZeroForceOne(DD)
            % A function to zero the single axis load cell data. Uses
            % the average data before the tirgger to zero the entire
            % data trace. Operates only on calibrated data, so will call
            % DD.CalibrateForceOne() if the single axis data vectro is
            % empty.
            %
            % DD.ZeroForceOne()
            %
            if isempty(DD.GetForceOneRaw() )
                warning('DropTowerDAQ:DataAvailability','Zeroing of the single axis load cell for %s was requested before calibration. Calibration will be carried out now.\n',DD.GetSpecimen().GetSpecimenName());
                DD.CalibrateForceOne()
            end
            
            idxTrig = DD.GetIndexTrigger();
            forceRaw = DD.GetForceOneRaw();
            
            forcePreTrig = mean(forceRaw(1:idxTrig));
            DD.m_forceOneDAQ = DD.m_forceOneDAQ - forcePreTrig;
            
            DD.m_forceOneZeroed = true;
            
        end
                
        function CalcFilteredData(DD)
            % A function to filter the data suppled in the input file.
            % To supply input data, use DD.SetFileName(file), followed
            % by DD.ReadFile(). The filtering is performed using a
            % Butterworth filter of order found in DD.GetFilterOrder(),
            % and at a cut off frequency found in DD.GetFilterCutoff().
            %
            % DD.CalcFilteredData()
            %
            
            % Check if the data has been zeroed and calibrated
            if (~DD.m_forceOneZeroed || ~DD.m_forceSixZeroed)
                error('DropTowerDAQ:ExecutionOrder','Data filtering for %s called before the data was calibrated and zeroed.\n',DD.GetSpecimen().GetSpecimenName())
            end
                        
            % design the filter
            cutoffNomal = DD.GetFilterCutoff()/DD.GetSampleRate();
            [b,a] = butter(DD.GetFilterOrder/2,cutoffNomal);
            forceSixRaw = DD.GetForceSixRaw();
            
            % filter the six axis load cell
            for i = 1:size(DD.GetForceSixRaw(),2)
                DD.m_forceSix(:,i) = filtfilt(b,a,forceSixRaw(:,i));
            end
            % filter the single axis load cell
            DD.m_forceOne = filtfilt(b,a,DD.GetForceOneRaw());            
            % filter the strain gauge data
            DD.m_strainGauge1 = filtfilt(b,a,DD.GetStrainGauge1Raw());
            DD.m_strainGauge2 = filtfilt(b,a,DD.GetStrainGauge2Raw());
            DD.m_strainGauge3 = filtfilt(b,a,DD.GetStrainGauge3Raw());
            
            % transfter the trigger data without filtering
            DD.m_trigger = DD.m_triggerDAQ;
            
            % zero the time vector at the trigger
            DD.ZeroTimeAtTrigger();
            
        end
        
        function CalcPrincipalStrains(DD)
            % A function to calculate the principal strains from the
            % strain gauge data.
            %
            % DD.CalcPrincipalStrains()
            %
            
            % check if strain data is available
            if (isempty(DD.GetStrainGauge1()) || isempty(DD.GetStrainGauge2()) || isempty(DD.GetStrainGauge3()) )
                error('DropTowerDAQ:DataAvailability','An attempt to calculate the principal strains for %s was attempted before the strains were available.\nPossibly DD.CalcFilteredData() needs to be called?\n',DD.GetSpecimen().GetSpecimenName());
            end

            % calculate the principal strains.
            gA = DD.GetStrainGauge1();
            gB = DD.GetStrainGauge2();
            gC = DD.GetStrainGauge3();
            DD.m_strainGaugeP1 = ( (gA+gC)./2 + 1/2.*sqrt( (gA-gC).^2 + (2.*gB-gA-gC).^2 ) );
            DD.m_strainGaugeP2 = ( (gA+gC)./2 - 1/2.*sqrt( (gA-gC).^2 + (2.*gB-gA-gC).^2 ) );
            DD.m_strainGaugePhi = 0.5.*atan( (2.*gB-gA-gC) ./ (gA-gC) );    
        end
        
        function o = GetIndexTrigger(DD)
            % A function to return the trigger index in the DAQ index
            % (rather than experiment) index space.
            %
            % Index = DD.GetIndexTrigger()
            %
            if isempty(DD.m_indexTrigger)
                DD.m_indexTrigger = find(DD.m_triggerDAQ < 4.9,1,'first');
            end
            o = DD.m_indexTrigger;
        end
        
        function ZeroTimeAtTrigger(DD)
            % A function to zero the time at the moment of the trigger.
            %
            % DD.ZeroTimeAtTrigger()
            %
            rawTime = DD.GetTimeRaw;
            DD.m_time = DD.GetTimeRaw() - rawTime(DD.GetIndexTrigger());
        end
        
    end % private methods

end % classdef
