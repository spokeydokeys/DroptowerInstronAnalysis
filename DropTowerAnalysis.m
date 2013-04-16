classdef DropTowerAnalysis < handle
    properties (SetAccess = private)
        % members for the specimen
        m_specimen;
        
        % members for the DAQ equipment
        m_daqData;
        
        % members for the displcement
        m_displacementData;
        
        % members for the DIC data
        m_dicData;
        
        % machine members
        m_dropTowerCompliance = 1/5640000; % (m/N) measured in project 13-009
        
        % result vecotrs members
        m_time;
        m_forceSix;
        m_forceOne;
        m_displacementTroch;
        m_displacementPlaten;
        m_compression
        m_strainGauge1;
        m_strainGauge2;
        m_strainGauge3;
        m_strainGaugeP1;
        m_strainGaugeP2;
        m_strainGaugePhi;
        m_strainDIC;
        
        % results from analysis
        m_stiffness;
        
        m_energyToForceMax;
        m_energyToForceInstronMax;
        
        m_strainDICToForceMax;
        m_strainDICToForceInstronMax;
        
        m_frameAtForceInstronMax;
        m_frameAtForceMax
        
        m_timeAtForceInstronMax;
        m_timeAtForceMax;
        m_timeAtImpactStart;
        
        m_indexAtForceInstronMax;
        m_indexAtForceMax;
        m_indexAtImpactStart;
    end % properties
    
    methods
        function DA = DropTowerAnalysis(specimen)
            % Input a specimen see Specimen.m for details
            DA.m_specimen = specimen;
            if DA.GetSpecimen().GetDataAvailable().DropTowerDAQ
                DA.m_daqData = DAQDropTower(specimen);
            end
            if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                DA.m_displacementData = DTDisplacement(specimen);
            end
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                DA.m_dicData = DICData(specimen);
            end
        end
        
        function o = GetSpecimen(DA)
            % A function that returns the specimen class
            if isempty(DA.m_specimen)
                error('DropTowerAnalysis:DataAvailable','A specimen was requested when no valid specimen was set.\n');
            end
            o = DA.m_specimen;
            
        end
        function o = GetDAQData(DA)
            % A function that returns the DAQ data class
            if isempty(DA.m_daqData)
                error('DropTowerAnalysis:DataAvailable','DAQ data for %s was requested when no valid specimen was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            o = DA.m_daqData;
        end
        function o = GetDisplcementData(DA)
            % A function that returns the displacement data class
            if isempty(DA.m_displacementData)
                error('DropTowerAnalysis:DataAvailable','Displacement data for %s was requested when no valid specimen was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            o = DA.m_displacementData;
        end
        function o = GetDICData(DA)
            % A function that returns the DIC data class
            if isempty(DA.m_dicData)
                error('DropTowerAnalysis:DataAvailable','DIC data for %s was requested when no valid specimen was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            o = DA.m_dicData;
        end
    
    
    
    end %methods
end % classdef
