classdef InstronAnalysis < handle
    properties (SetAccess = private, Hidden = false)
        % members from the specimen
        m_specimen;
        % members from the DAQ equipment
        m_daqData;
        % members from the dic
        m_dicData;          % only used if DIC data is available.
    end
    
    properties( SetAccess = private, Hidden = true)    
        % machine members
        m_instronCompliance = 1/30118000; % m/N loading plate compliance
        m_commonTimeRate = 5000; % Hz
        
        % result vectors members from interpolation analysis
        m_time;             % in seconds
        m_force;            % in newtons, compressive force
        m_displacementTroch;    % in m compression
        m_displacementPlaten;   % in m compression
        m_compression;      % in m. Specimen compression
        m_strainGauge; % [Gauge1, Gauge2, Gauge3]
        m_strainPrincipalGauge; %[P1, P2, Angle]
        m_strainDIC;
        m_strainError;
        
        % results members from analysis
        m_stiffness;        % in kN/mm
        m_energyToForceMax; % J
        m_strainAtMaxDIC;
        m_strainAtMaxGauge; % in strain, minimum principal stain
        m_frameAtMax;       % the dic frame at max force
        m_forceMax;
        m_timeForceMax;
        m_indexForceMax;
        m_strainErrorMean;
        m_strainErrorStdev;
    end % properties
    
    methods
        function IA = InstronAnalysis(specimen)
            % The constructor for the InstronAnalysis class. See
            % Specimen.m for details.
            %
            % IA = InstronAnalysis(specimen)
            %
            IA.m_specimen = specimen;
            if IA.GetSpecimen().GetDataAvailable().InstronDAQ
                IA.m_daqData = DAQInstron(specimen);
            end
            if IA.GetSpecimen().GetDataAvailable().InstronDIC
                IA.m_dicData = DICData(specimen);
            end
        end

        function o = GetSpecimen(IA)
            % A function to get the specimen object
            %
            % Specimen = IA.GetSpecimen()
            %
            o = IA.m_specimen;
        end

        function o = GetDICData(IA)
            % A function to get the DIC data object.
            %
            % DICData = IA.GetDICData()
            %
            o = IA.m_dicData;
        end

        function o = GetDAQData(IA)
            % A function to get the DAQ data object.
            %
            % DAQData = IA.GetDAQData()
            %           
            o = IA.m_daqData;
        end
    
        function SetInstronCompliance(IA,compliance)
            % A function to set the compliance of th testing rig in m/N.
            % The default value is 1/30118000 m/N.
            %
            % Compliance = IA.SetInstronCompliance(compliance)
            %
            IA.m_instronCompliance = compliance;
        end
        
        function o = GetInstronCompliance(IA)
            % A function to get the compliance of the instron in m/N.
            %
            % Compliance = GetInstronCompliance()
            %
            o = IA.m_instronCompliance;
        end

        function o = GetCommonTimeRate(IA)
            % A function to get the common time rate in Hz.
            %
            % Rate = IA.GetCommonTimeRate()
            %
            o = IA.m_commonTimeRate;
        end
        
        function SetCommonTimeRate(IA,rate)
            % A function to set the common time rate in Hz. The default
            % is 5 kHz.
            %
            % IA.SetCommonTimeRate(rate)
            %
            if IA.m_commonTimeRate ~= rate
                IA.m_commonTimeRate = rate;
            end
        end
        
        function InterpolateDICToCommonTime(IA)
            % A function to interpolate the data from the DIC object to the
            % common time vector.
            %
            % IA.InterpolateDICToCommonTime()
            %
            IA.m_strainDIC = interp1(IA.GetDICData.GetTime(), IA.GetDICData().GetStrainData(), IA.GetTime());
        end

        function o = GetTime(IA)
            % A function to get the time vector in seconds.
            %
            % Time = IA.GetTime()
            %
            if isempty(IA.m_time)
                IA.CreateCommonTimeVector();
            end
            o = IA.m_time;
        end
        
        function o = GetForce(IA)
            % A function to get the force in the instron analysis time
            % frame in newtons.
            %
            % Force = IA.GetForce()
            %
            o = IA.m_force;
        end
        
        function o = GetPrincipalStrainGauge(IA)
            % A function to get the first principal strain from the gauge
            % in the instron analysis time frame in absolute strain.
            % Outputs strain as
            %   [principal1,principal2,angle] 
            % with the strains in absolute and the angle in radians
            %
            % PrincipalStrain = IA.GetPrincipalStrainGauge();
            %
            o = IA.m_strainPrincipalGauge;
        end
        
        function o = GetStrainGauge(IA)
            % A function to get the stain gauge data in the instron 
            % anslysis time frame. Output as [gauge1,gauge2,gaue3] in
            % absolute strain.
            %
            % Strain = IA.GetStrainGauge()
            %
            o = IA.m_strainGauge;
        end
        
        function o = GetStrainDIC(IA)
            % A function to get the DIC strain in the instron analysis time
            % frame in absolute strain.
            %
            % Strain = IA.GetStrainDIC()
            %
            o = IA.m_strainDIC;
        end
        
        function o = GetDisplacementTroch(IA)
            % A function to get the trochanter displacement in mm in the
            % instron analysis time frame.
            %
            % Displacement = IA.GetDisplacementTroch()
            %
            o = IA.m_displacementTroch;
        end
        
        function o = GetDisplacementPlaten(IA)
            % A function to get the platen displacement in mm in the
            % instron analysis time frame.
            %
            % Displacement = IA.GetDisplacementPlaten()
            %            
            o = IA.m_displacementPlaten;
        end
        
        function o = GetCompression(IA)
            % A function to get the specimen compression in mm in the
            % instron analysis time frame.
            %
            % Compression = IA.GetCompression()
            %
            o = IA.m_compression;
        end

        function o = GetForceMax(IA)
            % A function to get the max force in newtons.
            %
            % Force = IA.GetForceMax()
            %
            o = IA.m_forceMax;
        end

        function o = GetTimeForceMax(IA)
            % A function to get the time of the max force in seconds.
            %
            % Time = IA.GetTimeForceMax()
            %
            o = IA.m_timeForceMax;
        end

        function o = GetIndexForceMax(IA)
            % A function to get the index of the max force.
            %
            % Index = IA.GetIndexForceMax()
            %
            o = IA.m_indexForceMax;
        end

        function o = GetIndexAtTime(IA,time)
            % A function to get the index at a give time in seconds.
            % Rounds the index down.
            %
            % Index = IA.GetIndexAtTime(time)
            %
            o = find(IA.GetTime() < time,1,'last');
        end

        function o = GetStiffness(IA)
            % A function to get the stiffness of the specimen in N/m.
            %
            % Stiffness = IA.GetStiffness()
            %
            if isempty(IA.m_stiffness)
                IA.CalcStiffness();
            end
            o = IA.m_stiffness;
        end

        function o = GetEnergy(IA)
            % A function to get the energy during loading in J
            %
            % Energy = IA.GetEnergy(IA)
            %
            if isempty(IA.m_energyToForceMax())
                IA.CalcEnergy();
            end
            o = IA.m_energyToForceMax;
        end
        
        function o = GetStrainAtMaxGauge(IA)
            % A function to calc the minimum principal strain at the strain
            % gauge location at the max force. Returns a value that has
            % been median filtered using a radius of 2.
            %
            % Strain = GetStrainAtMaxGauge()
            %
            if isempty(IA.m_strainAtMaxGauge)
                IA.CalcStrainAtMaxGauge();
            end
            o = IA.m_strainAtMaxGauge;
        end
        
        function o = GetStrainAtMaxDIC(IA)
            % A function to calc the minimum principal strain at the strain
            % gauge location at the max force. Returns a value that has
            % been median filtered using a radius of 2.
            %
            % Strain = GetStrainAtMaxGauge()
            %
            if isempty(IA.m_strainAtMaxDIC)
                IA.CalcStrainAtMaxDIC()
            end
            o = IA.m_strainAtMaxDIC;
        end

        function o = GetFrameAtMax(IA)
            % A function to get the DIC frame at the max force
            %
            % Frame = IA.GetFrameAtMax()
            %
            if isempty(IA.m_frameAtMax)
                IA.CalcFrameAtMax();
            end
            o = IA.m_frameAtMax;
        end

        function o = GetStrainError(IA)
            % A function to get the strain error vector in absolute strain.
            %
            % StrainError = IA.GetStrainError()
            %
            if isempty(IA.m_strainError)
                IA.CalcStrainError()
            end
            o =IA.m_strainError;
        end

        function o = GetStrainErrorMean(IA)
            % A function to get the mean strain error in absolute strain.
            %
            % MeanError = IA.GetStrainErrorMean()
            %
            if isempty(IA.m_strainErrorMean)
                IA.CalcStrainErrorMean();
            end
            o = IA.m_strainErrorMean;
        end

        function o = GetStrainErrorStdev(IA)
            % A function to get the strain error standard deviation in
            % absolute strain.
            %
            % StrainStdev = IA.GetStrainErrorStdev()
            %
            if isempty(IA.m_strainErrorStdev)
                IA.CalcStrainErrorStdev();
            end
            o = IA.m_strainErrorStdev;
        end
        


        function o = GetCompressionAtTime(IA,time)
            % A function to get the specimen compression in mm at a given time 
            % in seconds. Output is linearly interpolated from the compression
            % vector.
            %
            % Compression = GetCompressionAtTime(time)
            %
            o = interp1(IA.GetTime(),IA.GetCompression(),time);
        end
        
        function o = GetForceAtTime(IA,time)
            % A function to get the force in newtons at a give time in
            % seconds. The output is linearly interpolated from the time
            % vecvtor.
            %
            % Force = IA.GetForceAtTime(time)
            %
            o = interp1(IA.GetTime(),IA.GetForce(),time);
        end
                
        function Update(IA)
            % A function to update the state of the Instron analysis. Does
            % not execute ReadFile() which must be done by the user.
            %
            % IA.Update()
            %
            
            % Check if DAQ analysis will be done
            if ~isempty(IA.GetDAQData())
                % if there is a DAQ data object. Call its update function
                IA.GetDAQData.Update();
                   
                % next put everything into the common time vector for the
                % analysis. If there is DIC data it will also be
                % interpolated into this time space
                IA.InterpolateDAQToCommonTime()
                
                % Find the max force and its time and index
                IA.CalcForceMax()
                % Find the stiffness
                IA.CalcStiffness()
                % Find the energy to max force
                IA.CalcEnergy()
                % Find the gauge strain at max force
                IA.CalcStrainAtMaxGauge()
            end
            
            if ~isempty(IA.GetDICData()) % check for DIC data
                errorFlag = 0;
                if ~ischar(IA.GetDICData.GetFileName)
                   warning('InstronAnalysis:FileNameDIC','This error is fatal. No DIC file name for specimen %s was provided before calling AnalyzeInstronData.\n',IA.GetSpecimen().GetSpecimenName());
                   errorFlag = errorFlag + 1;
                end
                if isempty(IA.GetDICData.GetTimeStart)
                    warning('InstronAnalysis:StartTimeDIC','This error is fatal. No DIC start time has been set for specimen %s. Without the start time the DIC data cannot be matched to the DAQ data.\n',IA.GetSpecimen().GetSpecimenName());
                    errorFlag = errorFlag + 1;
                end
                if isempty(IA.GetDICData.GetSampleRate)
                    warning('InstronAnalysis:SampleRateDIC','This error is fatal. No DIC sample rate has been set for specimen %s. Without this sample rate the DIC frame corresponding to max force cannot be found.\n',IA.GetSpecimen().GetSpecimenName());
                    errorFlag = errorFlag + 1;
                end
                if errorFlag
                    error('InstronAnalysis:AnalyzeDICData','%d errors were detected when preparing to analyzde the Instron DIC data for specimen %s.\n',errorFlag,IA.GetSpecimen().GetSpecimenName());
                end
                               
                % next interpolate the data to the common time vector
                IA.InterpolateDICToCommonTime()
            end
            
            if ~isempty(IA.GetDICData()) && ~ isempty(IA.GetDAQData()) % things that require both for calculation
                % calculate the error
                IA.CalcStrainError()
                % calculate the mean error
                IA.CalcStrainErrorMean()
                % calculate the error standard deviation
                IA.CalcStrainErrorStdev()
                % determine the frame at which the max force occured
                IA.CalcFrameAtMax()
                % calculate the strain from the DIC at the max force using
                % a median filter radius of 2 (the default)
                IA.CalcStrainAtMaxDIC(2)
            end
        end

        function PrintSelf(IA)
            % A function to print the current state of the Instron analysis
            % object
            %
            % IA.PrintSelf()
            %
            fprintf(1,'\n%%%%%%%%%% Instron Analysis Class Data %%%%%%%%%%\n');
            IA.GetSpecimen().PrintSelf();
            
            fprintf(1,'\n  %%%% Instron Analysis Class Parameters %%%%\n');
            fprintf(1,'Instron compliance: %e m/N\n',IA.GetInstronCompliance());
            fprintf(1,'Specimen stiffness: %f N/m\n',IA.GetStiffness());
            fprintf(1,'Maximum force: %f N\n',IA.GetForceMax());                  
            fprintf(1,'Time at max force: %f seconds\n',IA.GetTimeForceMax());
            fprintf(1,'Index at max force: %d\n',IA.GetIndexForceMax());
            fprintf(1,'Energy to max force: %f J\n',IA.GetEnergy());
            fprintf(1,'DIC min principal strain at max force: %f strain\n',IA.GetStrainAtMaxDIC());
            fprintf(1,'Gauge min principal strain at max force: %f strain\n',IA.GetStrainAtMaxGauge());
            fprintf(1,'DIC frame at max force: %d\n',IA.GetFrameAtMax());
            fprintf(1,'DIC min principal strain mean error: %f strain\n',IA.GetStrainErrorMean());
            fprintf(1,'DIC min principal strain error stdev: %f strain\n',IA.GetStrainErrorStdev());
            
            fprintf(1,'\n  %%%% Instron Analysis Data %%%%\n');
            fprintf(1,'Instron time: [%d,%d] in seconds\n',size(IA.GetTime()));
            fprintf(1,'Instron force: [%d,%d] in newtons\n',size(IA.GetForce()));
            fprintf(1,'Instron trochanter displacement: [%d,%d] in m\n',size(IA.GetDisplacementTroch()));
            fprintf(1,'Instron platen displacement: [%d,%d] in m\n',size(IA.GetDisplacementPlaten()));
            fprintf(1,'Instron specimen compression: [%d,%d] in m\n',size(IA.GetCompression()));
            fprintf(1,'Instron strain gauge: [%d,%d] in strain\n',size(IA.GetStrainGauge()));
            fprintf(1,'Instron gauge principal strain: [%d,%d] in strain and radians\n',size(IA.GetPrincipalStrainGauge()));
            fprintf(1,'Instron DIC principal strain: [%d,%d] in strain\n',size(IA.GetStrainDIC()));
            fprintf(1,'Instron DIC-Guage strain error: [%d,%d] in strain\n',size(IA.GetStrainError()));
            
            if ~isempty(IA.GetDAQData())
                IA.GetDAQData().PrintSelf();
            else
                fprintf(1,'\n%%%%%%%%%% No DAQ Data Available %%%%%%%%%%\n');
            end
            if ~isempty(IA.GetDICData())
                IA.GetDICData().PrintSelf();
            else
                fprintf(1,'\n%%%%%%%%%% No DIC Data Available %%%%%%%%%%\n');
            end
        end
    end % public methods
    methods (Access = private,Hidden = true)
        function CreateCommonTimeVector(IA)
            % A function to create the common time vector to use in the
            % instron analysis in seconds.
            %
            % IA.CreateCommonTimeVector()
            %
            IA.m_time = 0.2:1/IA.GetCommonTimeRate():15;
        end

        function InterpolateDAQToCommonTime(IA)
            % A function to interpolate the data from the DAQ data object
            % into the common time vector
            %
            % IA.InterpolateDAQToCommonTime()
            %
            IA.m_force = -interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetForce(), IA.GetTime() ); % negative to get compressive force
            
            IA.m_displacementTroch = -interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetDisplacement(), IA.GetTime());
            IA.m_displacementPlaten = IA.GetForce().* IA.GetInstronCompliance();
            IA.m_compression = IA.GetDisplacementTroch() - IA.GetDisplacementPlaten;
                     
            IA.m_strainGauge(:,1) = interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetStrainGauge1(), IA.GetTime());
            IA.m_strainGauge(:,2) = interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetStrainGauge2(), IA.GetTime());
            IA.m_strainGauge(:,3) = interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetStrainGauge3(), IA.GetTime());
            
            IA.m_strainPrincipalGauge(:,1) = interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetPrincipalStrain1(), IA.GetTime());
            IA.m_strainPrincipalGauge(:,2) = interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetPrincipalStrain2(), IA.GetTime());
            IA.m_strainPrincipalGauge(:,3) = interp1(IA.GetDAQData.GetTime(), IA.GetDAQData.GetPrincipalStrainAngle(), IA.GetTime());
        end

        function CalcForceMax(IA)
            % A funtion to find the max force in netons.
            %
            % IA.CalcForceMax()
            %
            [maxF,maxFI] = max(IA.GetForce());
            IA.m_forceMax = maxF;
            time = IA.GetTime();
            IA.m_timeForceMax = time(maxFI);
            IA.m_indexForceMax = maxFI;
        end

        function CalcStiffness(IA)
            % A function to calculate the stiffness of the specimen. Uses
            % the max force and the half max force to calcualte the
            % stiffness.
            %
            % IA.CalcStiffness()
            %
            if isempty(IA.GetForceMax())
                IA.CalcForceMax()
                warning('InstronAnalysis:ExecutionOrder','Stiffness requested for %s before calculation of max force.\nMax force calculation being executed now.\n',IA.GetSpecimen().GetSpecimenName())
            end 
            % get the second force level for stiffness calculation
            forceTwo = IA.GetForceMax()/2;
            % get the index for the force at half max force
            indexForceTwo = find(IA.GetForce() > forceTwo,1,'first');
            % get the diplacement at max force
            compression = IA.GetCompression();
            dispForceMax = compression(IA.GetIndexForceMax());
            % get the displacement at force two
            dispForceTwo = compression(indexForceTwo);
            % calculate the stiffness between force two and force max
            stiffness = (IA.GetForceMax() - forceTwo)/(dispForceMax - dispForceTwo);
            % convert to N/m
            IA.m_stiffness = stiffness;
        end

        function CalcEnergy(IA)
            % A function to calculate the energy to the max force
            %
            % IA.CalcEnergy()
            %
            if isempty(IA.GetForceMax())
                warning('InstronAnalysis:ExecutionOrder','Energy to max force requested for %s before calculation of max force.\nMax force calculation being executed now.\n',IA.GetSpecimen().GetSpecimenName())
                 IA.CalcForceMax()           
            end
            % Get the data
            compression = IA.GetCompression();
            force = IA.GetForce();
            % find the valid data
            % numerically integrate using the valid indexes up to the max
            % force index using compression in m.
            IA.m_energyToForceMax = trapz(compression(1:IA.GetIndexForceMax()-1),force(1:IA.GetIndexForceMax()-1));
        end

        function CalcStrainAtMaxGauge(IA,radiusMedianFilter)
            % A function to calculate the minimum principal strain from the
            % strain gague at the max force in absulute strain.  Uses a 
            % median filter for  noise reduction with a default radius of
            % 2.
            %
            % IA.CalcStrainAtMaxGauge(radius(optional))
            %
            if nargin < 2
                radiusMedianFilter = 2;
            end
            principal = IA.GetPrincipalStrainGauge();
            
            IA.m_strainAtMaxGauge = median( principal( IA.GetIndexForceMax()-radiusMedianFilter:IA.GetIndexForceMax()+radiusMedianFilter,2 ) );
        end

        function CalcStrainAtMaxDIC(IA,radiusMedianFilter)
            % A function to calc the DIC strain at the max force. Returns
            % the value in absolute strain, median filtered using a default
            % radius of 2. The optional input can change that radius.
            %
            % IA.CalcStrainAtMaxDIC(radius(optional))
            %
            if nargin < 2
                radiusMedianFilter = 2;
            end
            strain = IA.GetStrainDIC();
            IA.m_strainAtMaxDIC = median( strain( IA.GetIndexForceMax()-radiusMedianFilter:IA.GetIndexForceMax()+radiusMedianFilter ) );
        end

        function CalcFrameAtMax(IA)
            % A function to calculate the DIC frame at the max force.
            %
            % IA.CalcFrameAtMax()
            %
            if isempty(IA.GetTimeForceMax())
                error('InstronAnalysis:DataAvailability','DIC frame at max load for %s requested before time at max load has been set.\n',IA.GetSpecimen().GetSpecimenName());
            end
            if isempty(IA.GetDICData())
                error('InstronAnalysis:DataAvailability','DIC frame at max load for %s requested when no DIC data is available.\n',IA.GetSpecimen().GetSpecimenName());
            end
            IA.m_frameAtMax = floor(( IA.GetTimeForceMax() - IA.GetDICData.GetTimeStart )*IA.GetDICData.GetSampleRate);
        end

        function CalcStrainError(IA)
            % A function to calculate the strain error vector, that is
            % (gauge strain) - (DIC strain) in absolute strain
            %
            % IA.CalcStrainError()
            %
            if ( isempty(IA.GetPrincipalStrainGauge) || isempty(IA.GetStrainDIC()) )
                error('InstronAnalysis:DataAvailability','Strain error requested for %s when either gauge minimum principal strain or DIC minimum principal strain are unavailable.\n',IA.GetSpecimen().GetSpecimenName());
            end
            % subtract the strain gauge P2 from StrainDIC for all time
            principal = IA.GetPrincipalStrainGauge();
            IA.m_strainError = principal(:,2) - IA.GetStrainDIC()';
        end

        function CalcStrainErrorMean(IA)
            % A function to calculate the mean strain error in absolute
            % strain.
            %
            % IA.CalcStrainErrorMean()
            %
            if isempty(IA.GetStrainError())
                error('InstronAnalysis:DataAvailability','Mean strain error requested for %s when strain error vector is unavailable.\n',IA.GetSpecimen().GetSpecimenName());
            end
            % find the last index for which DIC strain is defined and
            % subtract 1 second to remove spike at end of data
            strainError = IA.GetStrainError();
            validData = ~isnan(strainError);
            lastIndex = IA.GetIndexAtTime(IA.GetTimeForceMax+1.5);                     
            IA.m_strainErrorMean = mean(strainError(validData(1:lastIndex)));
        end

        function CalcStrainErrorStdev(IA)
            % A function to calculate the strain error standard deviation
            % in absolute strain
            %
            % IA.CalcStrainErrorStdev()
            %
            if isempty(IA.GetStrainError())
                error('InstronAnalysis:DataAvailability','The standard deviation of the strain error requested for %s when strain error vector is unavailable.\n',IA.GetSpecimen().GetSpecimenName());
            end
            % find the last index for which DIC strain is defined and
            % subtract 1 second to remove spike at end of data
            strainError = IA.GetStrainError();
            validData = ~isnan(strainError);
            lastIndex = find(validData == 1,1,'last')-5000;                        
            IA.m_strainErrorStdev = std(strainError(validData(1:lastIndex)));
        end
    
    end % private methods
end % classdef
