classdef InstronAnalysis < Specimen
    properties (SetAccess = private)
        % members from the DAQ equipment
        m_forceDAQ
        m_displacementDAQ;
        m_strainGaugeP1DAQ;
        m_strainGaugeP2DAQ;
        m_strainGaugePhiDAQ;
        m_triggerDAQ;
        m_timeDAQ;
        m_fileNameDAQ;
        
        % members from the dic
        m_dicData;          % only used if DIC data is available.
        
        % machine members
        m_instronCompliance = 1/30000; % m/N loading plate compliance
        
        % results members from interpolation analysis
        m_time;             % in seconds
        m_force;            % in newtons, compressive force
        m_displacementTroch;    % in mm compression
        m_displacementPlaten;   % in mm compression
        m_compression;      % in mm. Specimen compression
        m_strainGaugeP1;    % in strain
        m_strainGaugeP2;    % in strain
        m_strainGaugePhi;   % in rad
        m_strainDIC;        % in strain, minimum principal strain on surface
        
        % results members from analysis
        m_stiffness;        % in kN/mm
        m_energy;           % J           
        m_strainAtMaxDIC;
        m_strainAtMaxGauge; % in strain, minimum principal stain
        m_frameAtMax;       % the dic frame at max force
        m_forceMax;
        m_timeForceMax;
        m_indexForceMax;
        m_strainError;
        m_strainErrorMean;
        m_strainErrorStdev;
    end % properties
    
    methods
        % constructor
        function IA = InstronAnalysis(name,dxa,op,data)
            % name, dxa, op and data are inherited from "Specimen.m". See
            % Specimen.m for details.
            IA = IA@Specimen(name,dxa,op,data);
            if data(2)
                IA.m_dicData = DICData(name,dxa,op,data);
            end
        end
        
        function SetFileNameDAQ(IA,fileDAQ)
           while(~exist(fileDAQ,'file'))
                sprintf('The specified DAQ data file does not exist\n');
                fileDAQ = input('Please enter a valid DAQ file location');
            end 
            IA.m_fileNameDAQ = fileDAQ;
        end
        
        % Function to read in the data from the DAQ file
        function ReadDAQFile(IA)
            if isempty(IA.m_fileNameDAQ)
                error('InstronAnalysis:DataAvailability','Data file read for %s was requested before the file name was set.\n',IA.m_specimenName);
            end
            load(IA.m_fileNameDAQ);
            IA.m_timeDAQ = time;
            IA.m_forceDAQ = force;
            IA.m_displacementDAQ = displacement;
            IA.m_strainGaugeP1DAQ = pStrain1;
            IA.m_strainGaugeP2DAQ = pStrain2;
            IA.m_strainGaugePhiDAQ = phi;
            IA.m_triggerDAQ = trigger;
            % zero time at the trigger
            IA.ZeroDAQTimeAtTrigger;
        end     
        
        function o = GetDICDataClass(IA)
            o = IA.m_dicData;
        end
    
        function SetInstronCompliance(IA,compliance)
            IA.m_instronCompliance = compliance;
        end
        
        function ZeroDAQTimeAtTrigger(IA)
            index = find(IA.m_triggerDAQ<4.9,1,'first');
            IA.m_timeDAQ = IA.m_timeDAQ - IA.m_timeDAQ(index);
        end
        
        % Functions to get the DAQ data. Can only be set using ReadDAQFile
        function o = GetForceDAQ(IA)
            o = IA.m_forceDAQ;
        end
        function o = GetTimeDAQ(IA)
            o = IA.m_timeDAQ;
        end
        function o = GetDisplacementDAQ(IA)
            o = IA.m_displacementDAQ;
        end
        function o = GetStrainP1DAQ(IA)
            o = IA.m_strainGaugeP1DAQ;
        end
        function o = GetStrainP2DAQ(IA)
            o = IA.m_strainGaugeP2DAQ;
        end
        function o = GetStrainPhiDAQ(IA)
            o = IA.m_strainGaugePhiDAQ;
        end
        function o = GetTriggerDAQ(IA)
            o = IA.m_triggerDAQ;
        end
        function o = GetFileNameDAQ(IA)
            o = IA.m_fileNameDAQ;
        end
        
        function CreateCommonTimeVector(IA)
            IA.m_time = linspace(-.2,15,76000);
        end
        
        function InterpolateDAQToCommonTime(IA)
            if isempty(IA.m_time)
                IA.CreateCommonTimeVector
            end
            IA.m_force = -interp1(IA.m_timeDAQ, IA.m_forceDAQ, IA.m_time); % negative to get compressive force
            IA.m_strainGaugeP1 = interp1(IA.m_timeDAQ, IA.m_strainGaugeP1DAQ, IA.m_time);
            IA.m_strainGaugeP2 = interp1(IA.m_timeDAQ, IA.m_strainGaugeP2DAQ, IA.m_time);
            IA.m_strainGaugePhi = interp1(IA.m_timeDAQ, IA.m_strainGaugePhiDAQ, IA.m_time);
            % interpolate the displacement and account for the instron compression at the same time.
            IA.m_displacementTroch = -interp1(IA.m_timeDAQ, IA.m_displacementDAQ, IA.m_time);
            IA.m_displacementPlaten = IA.m_force.*IA.m_instronCompliance;
            IA.m_compression = IA.m_displacementTroch - IA.m_displacementPlaten;
        end
        
        function InterpolateDICToCommonTime(IA)
            if isempty(IA.m_time)
                IA.CreateCommonTimeVector
            end
            % interpolate the DIC strain an convert from % to strain
            IA.m_strainDIC = interp1(IA.m_dicData.GetTime(), IA.m_dicData.GetStrainData(), IA.m_time)./100;
        end
        
        % functions to get the interpolated data
        function o = GetTime(IA)
            o = IA.m_time;
        end
        function o = GetForce(IA)
            o = IA.m_force;
        end
        function o = GetStrainP1(IA)
            o = IA.m_strainGaugeP1;
        end
        function o = GetStrainP2(IA)
            o = IA.m_strainGaugeP2;
        end
        function o = GetStrainPhi(IA)
            o = IA.m_strainGaugePhi;
        end
        function o = GetStrainDIC(IA)
            o = IA.m_strainDIC;
        end
        function o = GetDisplacementTroch(IA)
            o = IA.m_displacementTroch;
        end
        function o = GetDisplacementPlaten(IA)
            o = IA.m_displacementPlaten;
        end
        function o = GetCompression(IA)
            o = IA.m_compression;
        end
        
        % function to find the max force
        function CalcForceMax(IA)
            [maxF,maxFI] = max(IA.m_force);
            IA.m_forceMax = maxF;
            IA.m_timeForceMax = IA.m_time(maxFI);
            IA.m_indexForceMax = maxFI;
        end
        % function to get the mas force
        function o = GetForceMax(IA)
            o = IA.m_forceMax;
        end
        % function to get the time of the max force
        function o = GetTimeForceMax(IA)
            o = IA.m_timeForceMax;
        end
        % function to get the index of the max force in the interpolated
        % time vector
        function o = GetIndexForceMax(IA)
            o = IA.m_indexForceMax;
        end
        
        % function to find the index at a given time.
        % returns the last index before a given time value
        function o = GetIndexAtTime(IA,time)
            if isempty(IA.m_time)
                error('InstronAnalysis:DataAvailability','The index of a certain time was requested for specimen %s before the time vector has been defined.\n',IA.m_specimenName);
            end
            o = find(IA.m_time < time,1,'last');
        end
        
        % function to calculate the stiffness
        function CalcStiffness(IA)
            if isempty(IA.m_forceMax)
                IA.CalcForceMax
                warning('InstronAnalysis:ExecutionOrder','Stiffness requested for %s before calculation of max force.\nMax force calculation being executed now.\n',IA.m_specimenName)
            end 
            % get the second force level for stiffness calculation
            forceTwo = IA.m_forceMax/2;
            % get the index for the force at half max force
            indexForceTwo = find(IA.m_force > forceTwo,1,'first');
            % get the diplacement at max force
            dispForceMax = IA.m_compression(IA.m_indexForceMax);
            % get the displacement at force two
            dispForceTwo = IA.m_compression(indexForceTwo);
            % calculate the stiffness between force two and force max
            stiffness = (IA.m_forceMax - forceTwo)/(dispForceMax - dispForceTwo);
            % convert to kN/mm
            IA.m_stiffness = stiffness./1000;
        end
        % function to get the stiffness value
        function o = GetStiffness(IA)
            o = IA.m_stiffness;
        end
        
        % function to calculate the energy during loading
        function CalcEnergy(IA)
            if isempty(IA.m_forceMax)
                IA.CalcForceMax
                warning('InstronAnalysis:ExecutionOrder','Energy to max force requested for %s before calculation of max force.\nMax force calculation being executed now.\n',IA.m_specimenName)
            end
            energy = 0;
            for i = 1:IA.m_indexForceMax-1
                if ( isnan(IA.m_compression(i)) || isnan(IA.m_force(i)) )  % skip all the data until we have valid displacements and forces
                    continue
                end
                forceA = IA.m_force(i);
                forceB = IA.m_force(i+1);
                dispA = IA.m_compression(i)/1000; %mm to m
                dispB = IA.m_compression(i+1)/1000;
                energy = energy + (dispB-dispA)* mean([forceA forceB]);
            end
            IA.m_energy = energy;
        end
        
        % function to get the energy during loading
        function o = GetEnergy(IA)
            o = IA.m_energy;
        end
        
        % functin to calculate the strain at the gauge max
        function CalcStrainAtMaxGauge(IA,radiusMedianFilter)
            % get the minimum principal strain at the max force. Uses a
            % median filter for noise reduction. If no median filter radius
            % is give, a value of 2 is used.
            if nargin < 2
                radiusMedianFilter = 2;
            end
            IA.m_strainAtMaxGauge = median( IA.m_strainGaugeP2( IA.m_indexForceMax-radiusMedianFilter:IA.m_indexForceMax+radiusMedianFilter ) );
        end
        function o = GetStrainAtMaxGauge(IA)
            o = IA.m_strainAtMaxGauge;
        end

        function CalcStrainAtMaxDIC(IA,radiusMedianFilter)
            % get the minimum principal strain at the max force. Uses a
            % median filter for noise reduction. If no median filter radius
            % is give, a value of 2 is used.
            if nargin < 2
                radiusMedianFilter = 2;
            end
            IA.m_strainAtMaxDIC = median( IA.m_strainDIC( IA.m_indexForceMax-radiusMedianFilter:IA.m_indexForceMax+radiusMedianFilter ) );
        end
        function o = GetStrainAtMaxDIC(IA)
            o = IA.m_strainAtMaxDIC;
        end
        
        function CalcFrameAtMax(IA)
            % get the experiment time of the max force.
            % subtract the DIC time from that time
            % multiply that time in seconds by the rate of the DIC            
            IA.m_frameAtMax = ( IA.m_timeForceMax - IA.GetDICDataClass.GetStartTime )*IA.GetDICDataClass.GetSampleRate;
        end
        function o = GetFrameAtMax(IA)
            o = IA.m_frameAtMax;
        end
        
        function CalcStrainError(IA)
            % subtract the strain gauge P2 from StrainDIC for all time
            IA.m_strainError = IA.m_strainGaugeP2 - IA.m_strainDIC;
        end
        function o = GetStrainError(IA)
            o =IA. m_strainError;
        end
       
        function CalcStrainErrorMean(IA)     
            % find the last index for which DIC strain is defined and
            % subtract 1 second to remove spike at end of data
            validData = ~isnan(IA.m_strainError);
            lastIndex = find(validData == 1,1,'last')-5000;                        
            IA.m_strainErrorMean = mean(IA.m_strainError(validData(1:lastIndex)));
        end
        function o = GetStrainErrorMean(IA)
            o = IA.m_strainErrorMean;
        end
         
        function CalcStrainErrorStdev(IA)
            % find the last index for which DIC strain is defined and
            % subtract 1 second to remove spike at end of data
            validData = ~isnan(IA.m_strainError);
            lastIndex = find(validData == 1,1,'last')-5000;                        
            IA.m_strainErrorStdev = std(IA.m_strainError(validData(1:lastIndex)));
        end
        function o = GetStrainErrorStdev(IA)
            o = IA.m_strainErrorStdve;
        end
        
        % function to get the specimen compression at a give time using
        % linear interpolation
        function o = GetCompressionAtTime(IA,time)
            o = interp1(IA.m_time,IA.m_compression,time);
        end
        
        % function to get the force at a given time using linear
        % interpolation
        function o = GetForceAtTime(IA,time)
            o = interp1(IA.m_time,IA.m_force,time);
        end
                
        function AnalyzeInstronData(IA)
            % Check if DAQ analysis will be done
            if IA.m_instronDAQ
                % Warnings will be issued so that you get a list of all
                % data errors, then this will be used as a flag to stop
                % execution at the end of the integrety check
                errorFlag = 0; 
                % now check that the data is available
                if ~ischar(IA.m_fileNameDAQ)
                    warning('InstronAnalysis:FileNameDAQ','This error is fatal. No DAQ file name for specimen %s was provided before calling AnalyzeInstronData.\n',IA.m_specimenName);
                    errorFlag = errorFlag + 1;
                end
                if IA.m_instronCompliance == 0
                    warning('InstronAnalysis:Compliance','The compliance of the instron is set to zero for specimen %s. Continuing with execution.\n',IA.m_specimenName);
                end
                if errorFlag
                    error('InstronAnalysis:AnalyzeDAQData','%d errors were detected when preparing to analyze the Instron DAQ data for specimen %s.\n',errorFlag,IA.m_specimenName);
                end
                
                % first read in and account for the trigger
                IA.ReadDAQFile;
                % next put everything into the common time vecotr for the
                % analysis. If there is DIC data it will also be
                % interpolated into this time space
                IA.InterpolateDAQToCommonTime
                % Find the max force and its time and index
                IA.CalcForceMax
                % Find the stiffness
                IA.CalcStiffness
                % Find the energy to max force
                IA.CalcEnergy
                % Find the gauge strain at max force using a median filter
                % radius of 2 (the default)
                IA.CalcStrainAtMaxGauge(2)
            end
            
            if IA.m_instronDIC && IA.m_instronDAQ % requires both DIC and DAQ data for analysis
                errorFlag = 0;
                if ~ischar(IA.GetDICDataClass.GetFileName)
                   warning('InstronAnalysis:FileNameDIC','This error is fatal. No DIC file name for specimen %s was provided before calling AnalyzeInstronData.\n',IA.m_specimenName);
                   errorFlag = errorFlag + 1;
                end
                if isempty(IA.GetDICDataClass.GetStartTime)
                    warning('InstronAnalysis:StartTimeDIC','This error is fatal. No DIC start time has been set for specimen %s. Without the start time the DIC data cannot be matched to the DAQ data.\n',IA.m_specimenName);
                    errorFlag = errorFlag + 1;
                end
                if isempty(IA.GetDICDataClass.GetSampleRate)
                    warning('InstronAnalysis:SampleRateDIC','This error is fatal. No DIC sample rate has been set for specimen %s. Without this sample rate the DIC frame corresponding to max force cannot be found.\n',IA.m_specimenName);
                    errorFlag = errorFlag + 1;
                end
                if errorFlag
                    error('InstronAnalysis:AnalyzeDICData','%d errors were detected when preparing to analyzde the Instron DIC data for specimen %s.\n',errorFlag,IA.m_specimenName);
                end
                
                % first read in the DIC data file
                IA.GetDICDataClass.ReadDataFile
                % next interpolate the data to the common time vector
                IA.InterpolateDICToCommonTime
                % calculate the error
                IA.CalcStrainError
                % calculate the mean error
                IA.CalcStrainErrorMean
                % calculate the error standard deviation
                IA.CalcStrainErrorStdev
                % determine the frame at which the max force occured
                IA.CalcFrameAtMax
                % calculate the strain from the DIC at the max force using
                % a median filter radius of 2 (the default)
                IA.CalcStrainAtMaxDIC(2)
            end
        end
    end % methods
end % classdef
        
            
            