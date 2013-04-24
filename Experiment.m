classdef Experiment < handle
    properties (SetAccess = private, Hidden = false)
        % objects for data sets
        m_specimen;
        m_dropTower;
        m_instron;
    end
    properties (SetAccess = private, Hidden = true)
        % analysis properties
        m_stiffnessDelta;
        m_energyToForceInstronMaxDelta;
        m_strainAtForceInstronMaxDelta;
    end % properties
    
    methods
        function EXP = Experiment(specimen)
            % A constructor for an experiment. Takes a specimen as the
            % input. See Specimen.m for details on creating a specimen.
            %
            % EXP = Experiment(specimen)
            %
            EXP.m_specimen = specimen;
            if (specimen.GetDataAvailable().InstronDAQ || specimen.GetDataAvailable().InstronDIC )
                EXP.m_instron = InstronAnalysis(specimen);
            end
            if (specimen.GetDataAvailable().DropTowerDAQ || specimen.GetDataAvailable().DropTowerDisplacement || specimen.GetDataAvailable().DropTowerDIC)
                EXP.m_dropTower = DropTowerAnalysis(specimen);
            end
        end
        
        function o = GetSpecimen(EXP)
            % A function to get the specimen object used to create the
            % Experiment object
            %
            % Specimen = EXP.GetSpecimen()
            %
            o = EXP.m_specimen;
        end
        
        function o = GetDropTower(EXP)
            % A function to get the drop tower analysis object.
            %
            % DropTowerAnalysis = EXP.GetDropTower()
            %
            o = EXP.m_dropTower;
        end
        
        function o = GetInstron(EXP)
            % A function to get the instron analysis object.
            %
            % InstronAnalysis = EXP.GetInstron()
            %
            o = EXP.m_instron;
        end
        
        function o = GetStiffnessDelta(EXP)
            % A function to get the difference in stiffness betweeen the
            % instron and drop tower in N/m, calculated as:
            %    InstronStiffness - DropTowerStiffness
            %
            % Difference = EXP.GetStiffnessDelta()
            %
            o = EXP.m_stiffnessDelta;
        end
        
        function o = GetEnergyToForceInstronMaxDelta(EXP)
            % A function to get the difference in energy in J between the
            % instron and drop tower, calculated as:
            %    InstronEnergy - DropTowerEnergy
            %
            % Difference = EXP.GetEnergyToForceInstronMaxDelta()
            %
            o = EXP.m_energyToForceInstronMaxDelta;
        end
        
        function o = GetStrainAtForceInstronMaxDelta(EXP)
            % A function to get the difference in strain at the 
            % max instron force in absolute strain. Uses the strain gauge
            % on the instron side, and DIC on the drop tower.
            % The calculation is:
            %    InstronStrain - DropTowerStrain
            %
            % Difference = EXP.GetStrainAtForceInstronMaxDelta()
            %
            o = EXP.m_strainAtForceInstronMaxDelta;
        end        
        
        function Update(EXP,recalcMax)
            % A function to update the state of the analysis.
            %
            % The optional input "recalcMax" is a bool flag to indicate if
            % the drop tower max force should be recalculated. The default
            % value is 1 (yes, recalculate)
            %
            % EXP.Update(recalcMax)
            %
            if nargin<1
                recalcMax = 1;
            end
            ins = EXP.GetInstron();
            dt = EXP.GetDropTower();
            
            % update the child objects
            if ~isempty(ins)
                ins.Update();
                insExist = 1;
                % if the drop tower analysis is present, set the instron max force
                if ~isempty(dt)
                    dt.SetForceInstronMax(ins.GetForceMax())
                end
            else
                insExist = 0;
            end
            if ~isempty(dt)
                dt.Update(recalcMax);
                dtExist = 1;
            else
                dtExist = 0;
            end
            
            
            % if both stiffnesses are available, calculate the stiffness difference
            if ( dtExist && insExist )
                if ( ~isempty(dt.GetStiffness()) && ~isempty(ins.GetStiffness()) )
                    EXP.CalcStiffnessDelta();
                end
            end
            
            % if both energies to max instron are available, calc difference
            if ( dtExist && insExist )
                if ( ~isempty(dt.GetEnergyToForceInstronMax()) && ~isempty(ins.GetEnergy()) )
                    EXP.CalcEnergyDelta();
                end
            end
            
            % if both strains to max instron ara available, calc difference
            if (dtExist && insExist )
                if ( ~isempty(dt.GetStrainDICAtForceInstronMax()) && ~isempty(ins.GetStrainAtMaxGauge()) )
                    EXP.CalcStrainAtForceInstronMaxDelta();
                end
            end
        end
        
        function PrintSelf(EXP)
            % A function to print the current state of the experimental
            % analysis.
            %
            % EXP.PrintSelf()
            %
            
            fprintf(1,'\n%%%%%%%%%% Experiment Class Data %%%%%%%%%%\n');
            EXP.GetSpecimen().PrintSelf();
            fprintf(1,'\n %%%% Scalar Members %%%%\n');
            fprintf(1,'Instron - Drop tower stiffness: %f N/m\n',EXP.GetStiffnessDelta());
            fprintf(1,'Instron - Drop tower energy: %f J\n',EXP.GetEnergyToForceInstronMaxDelta());
            fprintf(1,'Instron - Drop tower strain: %f strain\n',EXP.GetStrainAtForceInstronMaxDelta());
            
            if ~isempty(EXP.GetInstron())
                EXP.GetInstron.PrintSelf();
            else
                fprintf(1,'No InstronAnalysis object associated');
            end
            if ~ isempty(EXP.GetDropTower())
                EXP.GetDropTower().PrintSelf();
            else
                fprintf(1,'No DropTowerAnalysis object associated');
            end
        end
    end % public methods
    
    methods (Access = private, Hidden = true)
        function CalcStiffnessDelta(EXP)
            % A function to calculate the difference in stiffness between
            % the instron and drop tower tests. The calculation is:
            %   InstronStiffness - DropTowerStiffness
            %
            % EXP.CalcStiffnessDelta()
            %
            stiffnessInstron = EXP.GetInstron().GetStiffness();
            stiffnessDropTower = EXP.GetDropTower().GetStiffness();
            
            EXP.m_stiffnessDelta = stiffnessInstron - stiffnessDropTower;
        end
        
        function CalcEnergyDelta(EXP)
            % A function to calculate the differenc in energy between the
            % instron and drop tower tests. The calculation is:
            %    InstronEnergy - DropTowerEnergy
            %
            % EXP.CalcEnergyDelta()
            %
            energyInstron = EXP.GetInstron().GetEnergy();
            energyDropTower = EXP.GetDropTower().GetEnergyToForceInstronMax();
            
            EXP.m_energyToForceInstronMaxDelta = energyInstron - energyDropTower;
        end
        
        function CalcStrainAtForceInstronMaxDelta(EXP)
            % A function to calculate the difference in strain at the 
            % max instron force in absolute strain. Uses the strain gauge
            % on the instron side, and DIC on the drop tower.
            % The calculation is:
            %    InstronStrain - DropTowerStrain
            %
            % EXP.CalcStrainAtForceInstronMaxDelta()
            %
            strainInstron = EXP.GetInstron().GetStrainAtMaxGauge();
            strainDropTower = EXP.GetDropTower().GetStrainDICAtForceInstronMax();
            
            EXP.m_strainAtForceInstronMaxDelta = strainInstron - strainDropTower;
        end
    end % private methods
end
