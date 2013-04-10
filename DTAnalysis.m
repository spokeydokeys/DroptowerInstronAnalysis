classdef DTAnalysis < Specimen
    properties (SetAccess = private)
        % members for the DAQ equipment
        m_forceSixDAQ;
        m_forceOneDAQ;
        m_timeDAQ;
        m_strainGaugeP1DAQ;
        m_strainGaugeP2DAQ;
        m_strainGaugePhiDAQ;
        m_triggerDAQ;
        m_fileNameDAQ;
        
        % members for the DIC
        m_dicData;
        
        % members for the displacement  %% This is another class
        m_displacementData;
        
        % machine members
        m_complianceLoadingPlate = 1/30118000;  % m/N the loading plate compliance from the quasistatic testing
        m_complianceDt = 1/5640000;             % m/N the compliance of the dt base 
        m_massDtBase = 23.18 + 6.419 + 21.36 + 9.94 + 35; % kg, mass of (Angle platen) + loadcell + t-slot + (DT base/3) + mounting apparatus
        
        % results members from interpolation
        m_time;                 % in seconds
        m_forceSix;             % in N
        m_forceOne;             % in N
        m_displacementHammer;   % in mm, impact hammer displacement
        m_displacementTroch;    % in mm, trochanter displacement
        m_displacementPlaten;   % in mm, lower platen displacement
        m_compression;          % in mm, specimen compression
        m_strainGaugeP1;        % in strain
        m_strainGaugeP2;        % in strain
        m_strainGaugePhi;       % in radians
        m_strainDIC;            % in strain, minimum principal strain
        
        % results of the analysis
        m_stiffness;            % kN/mm
        m_energy;               % J
        m_strainAtMax;          % in strain
        m_frameAtMax;           % frame number
        m_forceMax;             % N
        m_timeImpact;           % s, time of start of impact
        m_timeForceMax;         % s
        m_indexForceMax;        
        m_compressionForceMax;  % mm
        
    end
    
    methods
        % constructor
        function DI = DTAnalysis(name,dxa,op,data)
            % name, dxa, op and data are inherited from "Specimen.m". See
            % Specimen.m for details.
            DI = DI@Specimen(name,dxa,op,data);
            if data(3)
                DI.m_displacementData = DTDisplacementData(name,dxa,op,data);
            end
            if data(4)
                DI.m_dicData = DICData(name,dxa,op,data);
            end
        end
        
        % function to set get the file name
        function SetFileNameDAQ(DI,fileName)
            if fileName ~= DI.m_fileNameDAQ
                DI.m_fileNameDAQ = fileName;
            end
        end
        function o = GetFileNameDAQ(DI)
            o = DT.m_fileNameDAQ;
        end
        
        % funtion to get the DIC Class
        function o = GetDICDataClass(DI)
            o = DI.m_dicData;
        end
        
        % function to get the Displacement Class
        function o = GetDisplacementClass(DI)
            o = DI.m_displacementData;
        end
        
        % function to set the loading plate compliance
        function SetComplianceLoadingPlate(DI,compliance)
            if compliance ~= DI.m_complianceLoadingPlate
                DI.m_complianceLoadingPlate = compliance;
            end
        end
        % function to set the base compliance
        function SetComplianceDropTower(DI,compliance)
            if compliance ~= DI.m_complianceDt;
                DI.m_complianceDt = compliance;
            end
        end
        % function to set the base mass
        function SetMassDropTower(DI,mass)
            if mass ~= DI.m_massDtBase
                DI.m_massDtBase = mass;
            end
        end
        
        % function to read the input file
        function ReadFile(DI)
            if isempty(DI.m_fileNameDAQ)
                error('DropTowerAnalysis:DataAvailability','Data file read for %s was requested before the file name was set.\n',DI.m_specimenName);
            end
            load(DI.m_fileNameDAQ);
            DI.m_forceSixDAQ = sixAxis;
            DI.m_forceOneDAQ = oneAxis;
            DI.m_timeDAQ = time;
            DI.m_triggerDAQ = trigger;
            DI.m_strainGaugeP1DAQ = pStrain1;
            DI.m_strainGaugeP2DAQ = pStrain2;
            DI.m_strainGaugePhiDAQ = phi;
            % zero the time at the trigger
            DI.ZeroDAQTimeAtTrigger;
        end
        
        % a function to make the trigger time zero
        function ZeroDAQTimeAtTrigger(DI)
            index = find(DI.m_triggerDAQ < 4.9,1,'first');
            DI.m_timeDAQ = DI.m_timeDAQ - DI.m_timeDAQ(index);
        end
        
        % function to get the daq file inputs
        function o = GetForceSixDAQ(DI)
            o = DI.m_forceSixDAQ;
        end
        function o = GetForceOneDAQ(DI)
            o = DI.m_forceOneDAQ;
        end
        function o = GetTimeDAQ(DI)
            o = DI.m_timeDAQ;
        end
        function o = GetStrainP1DAQ(DI)
            o = DI.m_strainGaugeP1DAQ;
        end
        function o = GetStrainP2DAQ(DI)
            o = DI.m_strainGaugeP2DAQ;
        end
        function o = GetStrainPhiDAQ(DI)
            o = DI.m_strainGaugePhiDAQ;
        end
        function o = GetTriggerDAQ(DI)
            o = DI.m_triggerDAQ;
        end

        function CreateCommonTimeVector(DI)
            DI.m_time = linspace(-.2,.2,2000);
        end
        
    end % methods
end % classdef
            
                
