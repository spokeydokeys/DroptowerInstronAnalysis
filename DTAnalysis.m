classdef DTAnalysis < Specimen
    properties (SetAccess = private)
        % members for the DAQ equipment
        m_forceSixDAQ;
        m_forceOneDAQ;
        m_timeDAQ;
        m_strainGauge1DAQ;
        m_strainGauge2DAQ;
        m_strainGauge3DAQ;
        m_triggerDAQ;
        m_fileNameDAQ;
        
        % members for the DIC
        m_dicData;
        
        % members for the displacement  %% This is another class
        m_displacementData;
        
        % machine members
        m_loadingPlateCompliance = 1/30118000;  % N/m the loading plate compliance from the quasistatic testing
        m_dtCompliance = 1/5640000;             % N/m the compliance of the dt base 
        m_dtMass = 23.18 + 6.419 + 21.36 + 9.94 + 35; % kg, mass of (Angle platen) + loadcell + t-slot + (DT base/3) + mounting apparatus
        
        % results members from interpolation
        m_time;
        m_forceSix;
        m_forceOne;
        m_displacement;
        m_strainGauge1;
        m_strainGauge2;
        m_strainGauge3;
        m_strainGaugeP1;
        m_strainGaugeP2;
        m_strainGaugePhi;
        m_strainDIC;
        
        % results of the analysis
        m_stiffness;
        m_energy;
        m_strainAtMax;
        m_frameAtMax;
        m_forceMax;
        m_timeForceMax;
        m_indexForceMax;
        m_displacementForceMax;
        
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
        
    end % methods
end % classdef
            
                