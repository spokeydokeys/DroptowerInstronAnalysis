classdef DropTowerAnalysis < handle
    properties (SetAccess = private, Hidden = false)
        % members for the specimen
        m_specimen;
        % members for the DAQ equipment
        m_daqData;
        % members for the displcement
        m_displacementData;
        % members for the DIC data
        m_dicData;
    end
    
    properties(SetAccess = private, Hidden = true)    
        % machine members
        m_complianceDropTower = 1/5640000; % (m/N) measured in project 13-009
        m_massDropTower = 23.18 + 6.419 + 21.36 + 9.94 + (4*.474+2.327+13.656+14.542+.507); % kg, mass of (Angle platen) + loadcell + t-slot + (DT base/3) + mounting apparatus
        m_complianceLoadingPlate = 1/30118000;  % m/N the loading plate compliance from the quasistatic testing
        
        % result vecotrs members
        m_time;
        m_forceSix;
        m_forceOne;
        m_displacementTroch;
        m_displacementHammer;
        m_displacementPlaten;
        m_compression
        m_strainGauge; %[gauge1, gauge2, gauge3]
        m_strainPrincipalGauge; %[P1,P2, angle(rad)]
        m_strainDIC;
        
        % results from analysis
        m_stiffness; 
        m_indexAtImpactStart; 
        m_timeAtImpactStart; 
        % results at max force
        m_energyToForceMax; 
        m_forceMax; 
        m_strainDICAtForceMax; 
        m_strainPrincipalGaugeAtForceMax;   % given as [P1, P2, angle] in absolute and radians
        m_frameAtForceMax; 
        m_timeAtForceMax; 
        m_indexAtForceMax; 
        m_compressionAtForceMax;
        m_rateCompression;
        
        % results for max instron force
        m_energyToForceInstronMax; 
        m_forceInstronMax = 0;
        m_strainDICAtForceInstronMax; 
        m_strainGaugeAtForceInstronMax; 
        m_frameAtForceInstronMax; 
        m_timeAtForceInstronMax; 
        m_indexAtForceInstronMax; 
        m_compressionAtForceInstronMax; 
        
        % results for finish
        m_energyToImpactFinish; 
        m_timeAtImpactFinish; % time of the end of the impact. Will be used to calculate total energy
        m_indexAtImpactFinish; 
        
        % others
        m_timeCommonRate = 100000; %Hz
        
        %% To do list:
            % print self

    end % properties
    
    methods
        function DA = DropTowerAnalysis(specimen)
            % Constructor for the drop tower analysis class. Input a 
            % specimen see Specimen.m for details
            %
            % DA = DropTowerAnalysis(specimen)
            %
            DA.m_specimen = specimen;
            if DA.GetSpecimen().GetDataAvailable().DropTowerDAQ
                DA.m_daqData = DAQDropTower(specimen);
            end
            if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                DA.m_displacementData = DTDisplacementData(specimen);
            end
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                DA.m_dicData = DICData(specimen);
            end
        end
        
        function o = GetRateCompression(DA)
            % A function to get the loading rate of the specimen
            %
            % Rate = DA.GetLoadingRate()
            %
            o = DA.m_rateCompression;
        end
        
        function o = GetComplianceLoadingPlate(DA)
            % A function to get the compliance in m/N of the loading plate
            %
            % Compliance = DA.GetComplianceLoadingPlate()
            %
            o = DA.m_complianceLoadingPlate;
        end
        function SetComplianceLoadingPlate(DA,comp)
            % A function to set the compliance in m/N of the loading plate
            %
            % DA.SetComplianceLoadingPlate(compliance)
            %
            if DA.m_complianceLoadingPlate ~= comp
                DA.m_complianceLoadingPlate = comp;
            end
        end
        
        function o = GetCommonTimeRate(DA)
            % A function to get the common time sample rate in Hz.
            %
            % Rate = DA.GetCommonTimeRate()
            %
            o = DA.m_timeCommonRate;
        end
        function SetCommonTimeRate(DA,rate)
            % A function to set the sample rate of the common time vector
            % in Hz. The default is 100 kHz.
            %
            % DA.SetCommonTimeRate(rate)
            %
            if DA.GetCommonTimeRate() ~= rate
                DA.m_timeCommonRate = rate;
            end
        end
        
        function o = GetCompressionForceMax(DA)
            % A function to get the compression in m at the max force.
            %
            % Compression = DA.GetCompressionForceMax()
            %
            o = DA.m_compressionAtForceMax;
        end
        
        function o = GetCompressionForceInstronMax(DA)
            % A function to get the compression in m at the max instron
            % force.
            %
            % Compression = DA.GetCompressionForceInstronMax()
            %
            o = DA.m_compressionAtForceInstronMax;
        end
        
        function o = GetSpecimen(DA)
            % A function that returns the specimen object used to 
            % construct the analysis class.
            %
            % Specimen = DA.GetSpecimen()
            %
            o = DA.m_specimen;
            
        end
        
        function o = GetDAQData(DA)
            % A function that returns the DAQ data object.
            %
            % DAQData = DA.GetDAQData()
            %
            if isempty(DA.m_daqData)
                error('DropTowerAnalysis:DataAvailable','DAQ data for %s was requested when no valid specimen was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            o = DA.m_daqData;
        end
        
        function o = GetDisplacementData(DA)
            % A function that returns the displacement data object.
            %
            % DisplacementData = DA.GetDisplacementData()
            %
            if isempty(DA.m_displacementData)
                error('DropTowerAnalysis:DataAvailable','Displacement data for %s was requested when no valid specimen was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            o = DA.m_displacementData;
        end
        
        function o = GetDICData(DA)
            % A function that returns the DIC data object.
            %
            % DICData = DA.GetDICData()
            %
            if isempty(DA.m_dicData)
                error('DropTowerAnalysis:DataAvailable','DIC data for %s was requested when no valid specimen was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            o = DA.m_dicData;
        end
        
        function SetComplianceDropTower(DA,compliance)
            % A function to set the drop tower compliance in m/N.
            %
            % DA.SetComplianceDropTower(compliance)
            %
            if DA.m_complianceDropTower ~= compliance
                DA.m_complianceDropTower = compliance;
            end
        end
        
        function o = GetComplianceDropTower(DA)
            % A function to get the drop tower compliance in m/N.
            %
            % Complicance = DA.GetComplianceDropTower()
            %
            o = DA.m_complianceDropTower;
        end
        
        function SetMassDropTower(DA,mass)
            % A function to set the drop tower mass in kg.
            %
            % DA.SetMassDropTower(mass)
            %
            if DA.m_massDropTower ~= mass
                DA.m_massDropTower = mass;
            end
        end
        
        function o = GetMassDropTower(DA)
            % A function to get the drop tower mass in kg.
            %
            % Mass = DA.GetMassDropTower()
            %
            o = DA.m_massDropTower;
        end
        
        function o = GetTime(DA)
            % A function to get the time vector of the drop tower data
            % in seconds.
            %
            % Time = DA.GetTime()
            %
            o = DA.m_time;
        end
        
        function o = GetForceSix(DA)
            % A function to get the six axis load cell force matrix. The
            % matrix is provided as:
            % [F_x,F_y,F_z,M_x,M_y,M_z] with forces in N and moments in Nm.
            %
            % Force = DA.GetForceSix()
            %
            o = DA.m_forceSix;
        end
        
        function o = GetForce(DA)
            % A function to get the axial force trace from the six axis
            % load cell. This returns the third column of the matrix
            % returned by GetForceSix, ie the six axis load cell axial
            % measurement.
            % The force is in N.
            %
            % Force = DA.GetForce()
            %
            forceSix = DA.GetForceSix;
            
            o = forceSix(:,3);
        end            
        
        function o = GetForceOne(DA)
            % A function to get the single axisl load cell data vector.
            % The force is in N.
            %
            % Force = DA.GetForceOne()
            %
            o = DA.m_forceOne;
        end
        
        function o = GetDisplacementTroch(DA)
            % A function to get the displacement of the trochanter in m.
            %
            % Displacement = DA.GetDisplacementTroch()
            %
            o = DA.m_displacementTroch;
        end
        
        function o = GetDisplacementHammer(DA)
            % A function to get the displacement of the impact hammer in
            % m.
            %
            % Displacement = DA.GetDisplacementHammer()
            %
            o = DA.m_displacementHammer;
        end
        
        function o = GetDisplacementPlaten(DA)
            % A function to get the displacement of the lower (head)
            % platen in m.
            %
            % Displacement = DA.GetDisplacementPlaten()
            %
            o = DA.m_displacementPlaten;
        end
        
        function o = GetCompression(DA)
            % A function to get the compression of a specimen in m. This
            % is the difference between the trochanter displacement and 
            % the platen displacement.
            %
            % Compression = DA.GetCompression()
            %
            o = DA.m_compression;
        end
        
        function o = GetStrainGauge(DA)
            % A function to get the strain from the strain gauge in
            % absolute strain. The format is [gauge1, gauge2, gauge3].
            %
            % Strain = DA.GetStrainGauge1()
            %
            o = DA.m_strainGauge;
        end
        
        function o = GetPrincipalStrain(DA)
            % A function to get the principal strain from the gauge
            % in absolute strain. The format is:
            %   [Principal-1, Principal-2, Angle in radians]
            %
            % Strain = DA.GetPrincipalStrain()
            %
            o = DA.m_strainPrincipalGauge;
        end
        
        function o = GetStrainDIC(DA)
            % A function to get the minimum principal strain from the
            % DIC in absolute strain.
            % 
            % Strain = GetStrainDIC()
            %
            o = DA.m_strainDIC;
        end
        
        function o = GetStiffness(DA)
            % A function to get the stiffness of the specimen in N/m
            %
            % Stiffness = DA.GetStiffness()
            %
            o = DA.m_stiffness;
        end
        
        function o = GetEnergyToForceMax(DA)
            % A function to get the energy in J to the maximum force in
            % the drop tower.
            %
            % Energy = DA.GetEnergyToForceMax()
            %
            o = DA.m_energyToForceMax;
        end
        
        function o = GetEnergyToForceInstronMax(DA)
            % A function to get the energy in J to the maximum force in 
            % instron analysis.
            %
            % Energy = DA.GetEnergyToForceInstronMax()
            %
            o = DA.m_energyToForceInstronMax;
        end
        
        function o = GetEnergyToImpactFinish(DA)
            % A function to get the energy in J to the end of the impact.
            %
            % Energy = DA.GetEnergyToImpactFinish()
            %
            o = DA.m_energyToImpactFinish;
        end
        
        function o = GetForceMax(DA)
            % A function to get the max force in N. This force is taken
            % from the six axis load cell z-component.
            %
            % Force = DA.GetForceMax()
            %
            o = DA.m_forceMax;
        end
        
        function o = GetForceInstronMax(DA)
            % A function to get the value of the max instron force in N.
            %
            % Force = DA.GetForceInstronMax()
            %
            o = DA.m_forceInstronMax;
        end
        
        function SetForceInstronMax(DA,force)
            % A function to set the maximum force from the instron test
            % in N.
            %
            % DA.SetForceInstronMax(force)
            %
            if DA.m_forceInstronMax ~= force
                DA.m_forceInstronMax = force;
            end
        end
        
        function o = GetStrainDICAtForceMax(DA)
            % A function to get the DIC strain in absolute strain at
            % the max force, defined using the z-comp of the six axis
            % load cell. Returns the median strain with a window of 5.
            %
            % Strain = DA.GetStrainDICAtForceMax()
            %
            o = DA.m_strainDICAtForceMax;
        end
        
        function o = GetStrainDICAtForceInstronMax(DA)
            % A function to get the DIC strain in absolute strain at
            % the max instron force, defined in the drop tower using the
            % z-comp of the six axis load cell. Returns the median strain 
            % with a window of 5.
            %
            % Strain = DA.GetStrainDICAtForceInstronMax()
            %
            o = DA.m_strainDICAtForceInstronMax;
        end
        
        function o = GetPrincipalStrainGaugeAtForceMax(DA)
            % A function to get the gauge principal strain at the max force
            % defined by the z-comp of the six axis load cell. The strain
            % is given in a triplet of
            %   [Principal 1, Principal 2, Angle]
            % with the strains in absolute and the angle in radians.
            %
            % Strain = DA.GetPrincipalStrainGaugeAtForceMax()
            %
            o = DA.m_strainPrincipalGaugeAtForceMax;
        end
        
        function o = GetPrincipalStrainGaugeAtForceInstronMax(DA)
            % A function to get the gauge principal strain at the max
            % instron force force defined by the z-comp of the six axis 
            % load cell. The strain is given in a triplet of
            %   [Principal 1, Principal 2, Angle]
            % with the strains in absolute and the angle in radians.
            %
            % Strain = DA.GetPrincipalStrainGaugeAtForceInstronMax()
            %
            o = DA.m_strainGaugeAtForceInstronMax;
        end
        
        function o = GetFrameAtForceMax(DA)
            % A function to get the DIC frame number at max force defined
            % by the z-comp of the six axis load cell.
            %
            % Frame = DA.GetFrameAtForceMax()
            %
            o = DA.m_frameAtForceMax;
        end
        
        function o = GetFrameAtForceInstronMax(DA)
            % A function to get the DIC frame number at the max force in
            % the instron test.
            %
            % Frame = DA.GetFrameAtForceInstronMax()
            %
            o = DA.m_frameAtForceInstronMax;
        end
            
        function o = GetTimeForceInstronMax(DA)
            % A function to get the time in seconds to the max force
            % from the instron testing.
            %
            % Time = DA.GetTimeForceInstronMax()
            %
            o = DA.m_timeAtForceInstronMax;
        end
        
        function o = GetTimeForceMax(DA)
            % A function to get the time in seconds to the max force as
            % defined by the z-comp of the six axis load cell.
            %
            % Time = DA.GetTimeForceMax()
            %
            o = DA.m_timeAtForceMax;
        end
        
        function o = GetTimeImpactStart(DA)
            % A function to get the time in seconds at the start of the
            % impact.
            %
            % Time = DA.GetTimeImpactStart()
            %
            o = DA.m_timeAtImpactStart;
        end
        
        function o = GetTimeImpactFinish(DA)
            % A function to get the time in seconds at the finish of the
            % impact.
            %
            % Time = DA.GetTimeImpactFinish()
            %
            o = DA.m_timeAtImpactFinish;
        end
        
        function o = GetIndexForceInstronMax(DA)
            % A function to get the index at the max instron force.
            %
            % Index = DA.GetIndexForceInstronMax()
            %
            o = DA.m_indexAtForceInstronMax;
        end
        
        function o = GetIndexForceMax(DA)
            % A function to get the index at the max force, as determined
            % using the z-comp of the six axis load cell.
            %
            % Index = GetIndexForceMax()
            %
            o = DA.m_indexAtForceMax;
        end
        
        function o = GetIndexImpactStart(DA)
            % A function to get the index at the start of the impact.
            %
            % Index = GetIndexImpactStart()
            %
            o = DA.m_indexAtImpactStart;
        end
        
        function o = GetIndexImpactFinish(DA)
            % A function to get the index at the finish of the impact.
            %
            % Index = GetIndexImpactFinish()
            %
            o = DA.m_indexAtImpactFinish;
        end
        
        function o = GetForceSixCompressionAtTime(DA,t)
            % A function to get the compressive force from the six axis
            % load cell at an arbitrary time using interpolation. 
            % The force is given in N.
            %
            % Force = DA.GetSixCompressionForceAtTime(time)
            %
            forceSix = DA.GetForceSix();
            
            o = interp1(DA.GetTime(),forceSix(:,3),t);
        end
        
        function Update(DA,recalcMax)
            % A function to check the data availability and update the
            % status of all the class properties. Does not call ReadFile()
            % which must be done by the user. If recalculation of the
            % maximum force is not required, pass a "0" for recalcMax, 
            % which is an optional variable. 
            %
            % DA.Update(recalcMax(optional, default = 1))
            %
            if nargin < 1
                recalcMax = 1;
            end
            % check for what data we have and what is needed
            
            % if the DAQ is available, update and import
            if DA.GetSpecimen().GetDataAvailable().DropTowerDAQ
                % update the DAQ data
                DA.GetDAQData().Update();
                % interpolate the DAQ data
                DA.InterpolateDAQToCommonTime();
            end
            
            % if displacement is available, update and import
            if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                % update the displemcet data
                DA.GetDisplacementData().Update(); 
                % interpolate the data
                DA.InterpolateDisplacementDataToCommonTime()
            end
            
            % if DIC is available, import (DIC has no update method)
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                DA.InterpolateDICToCommonTime();
            end
            
            % calculations based on the DAQ data 
            if DA.GetSpecimen().GetDataAvailable().DropTowerDAQ
                % calc the displacement of the lower platen
                DA.CalcDisplacementPlaten();                  
                % if the displacement is also available calc compression
                if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                    DA.CalcCompression();
                end
                % if the instron is available get the instron max data
                if DA.GetSpecimen().GetDataAvailable().InstronDAQ
                    DA.CalcForceInstronMax();
                    % if dic as well, get the frame at max instron
                    if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                        DA.CalcFrameForceInstronMax();
                    end      
                end
                % find the max force
                if recalcMax
                    DA.CalcForceMax();
                end
                % find properties at the max force
                DA.CalcPropertiesForceMax();                
                % find the start and finish of the impact
                DA.CalcImpactStart();
                DA.CalcImpactFinish();
                % if displacement is available calc compression rate to max
                % force
                if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                    DA.CalcRateCompression();
                end               
                % if dic available find frame at the max force
                if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                    DA.CalcFrameForceMax();
                end                
              
            end
            
            % if the displacement and force are available
            if (DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement && DA.GetSpecimen().GetDataAvailable().DropTowerDAQ)
                if DA.GetSpecimen().GetDataAvailable().InstronDAQ
                    DA.CalcEnergyToForceInstronMax();
                end               
                % calculate the stiffness
                DA.CalcStiffness();
                % calculate the energy to max
                DA.CalcEnergyToForceMax();
                % calculate the energy to finish
                DA.CalcEnergyToImpactFinish();
                % if the instron force is available, calc energy

            end
        end
        
        function PrintSelf(DA)
            % A function to print out the current state of the drop tower
            % analysis object.
            %
            % DA.PrintSelf()
            %
            fprintf(1,'\n%%%%%%%%%% DropTowerAnalysis Class Parameters %%%%%%%%%%\n');
            DA.GetSpecimen().PrintSelf();
            fprintf(1,'\n %%%% Scalar Members and Properties %%%%\n');
            fprintf(1,'Machine compliance: %e m/N\n',DA.GetComplianceDropTower());
            fprintf(1,'Loading plate compliance: %e m/N\n',DA.GetComplianceLoadingPlate());
            fprintf(1,'Mass drop tower pleten: %f kg\n',DA.GetMassDropTower());
            fprintf(1,'Frequency of common time: %f Hz\n',DA.GetCommonTimeRate());
            fprintf(1,'Max Instron force: %f N\n',DA.GetForceInstronMax());
                        
            fprintf(1,'\n %%%% Scalar Results %%%% \n');
            fprintf(1,'Stiffness: %f N/m\n',DA.GetStiffness());
            fprintf(1,'Max force: %f N\n',DA.GetForceMax());
            fprintf(1,'Compression at max force: %f m\n',DA.GetCompressionForceMax());
            fprintf(1,'Compression at max instron force: %f m\n',DA.GetCompressionForceInstronMax());
            fprintf(1,'Compression rate of the specimen: %f m/s\n',DA.GetRateCompression());
            fprintf(1,'Energy to max force: %f J\n',DA.GetEnergyToForceMax());
            fprintf(1,'Energy to max instron force: %f J\n',DA.GetEnergyToForceInstronMax());
            fprintf(1,'Energy to impact finish: %f J\n',DA.GetEnergyToImpactFinish());
            fprintf(1,'Time of impact start: %f seconds\n',DA.GetTimeImpactStart());
            fprintf(1,'Time of max force: %f seconds\n',DA.GetTimeForceMax());
            fprintf(1,'Time of max instron force %f seconds\n',DA.GetTimeForceInstronMax());
            fprintf(1,'Time of impact finish: %f seconds\n',DA.GetTimeImpactFinish());
            fprintf(1,'Index of impact start: %d\n',DA.GetIndexImpactStart());
            fprintf(1,'Index of max force: %d\n',DA.GetIndexForceMax());
            fprintf(1,'Index of max instron force: %d\n',DA.GetIndexForceInstronMax());
            fprintf(1,'Index of impact finish: %d\n',DA.GetIndexImpactFinish());
            fprintf(1,'Principal strain at max force:\n\t[%15f strain,\n\t%15f strain,\n\t%15f radians]\n',DA.GetPrincipalStrainGaugeAtForceMax());
            fprintf(1,'Principal strain at max instron force:\n\t[%15f strain,\n\t%15f strain,\n\t%15f radians]\n',DA.GetPrincipalStrainGaugeAtForceInstronMax());
            fprintf(1,'DIC strain at max force: %f strain\n',DA.GetStrainDICAtForceMax());
            fprintf(1,'DIC strain at max instron force: %f strain\n',DA.GetStrainDICAtForceInstronMax());
            fprintf(1,'DIC frame at max force: %d\n',DA.GetFrameAtForceMax());
            fprintf(1,'DIC frame at max instron force: %d\n',DA.GetFrameAtForceInstronMax());

            
            fprintf(1,' %%%% Vector Results %%%%\n');
            fprintf(1,'Time: [%d,%d] seconds\n',size(DA.GetTime()));
            fprintf(1,'Six axis force: [%d,%d] N\n',size(DA.GetForceSix()));
            fprintf(1,'Single axis force: [%d,%d] N\n',size(DA.GetForceOne()));
            fprintf(1,'Trochanter displacement: [%d,%d] m\n',size(DA.GetDisplacementTroch()));
            fprintf(1,'Hammer displacement: [%d,%d] m\n',size(DA.GetDisplacementHammer()));
            fprintf(1,'Lower platen displacement: [%d,%d] m\n',size(DA.GetDisplacementPlaten()));
            fprintf(1,'Specimen compression: [%d,%d] m\n',size(DA.GetCompression()));
            fprintf(1,'Gauge strain: [%d,%d] strain\n',size(DA.GetStrainGauge()));
            fprintf(1,'Gauge principal strain: [%d,%d] strain\n',size(DA.GetPrincipalStrain()));
            fprintf(1,'DIC strain: [%d,%d] strain\n',size(DA.GetStrainDIC()));
            
            fprintf('\n %%%% Associated Objects %%%% \n');
            if ~isempty(DA.GetDAQData())
                DA.GetDAQData().PrintSelf();
            else
                fprintf(1,'No DAQ data class associated\n');
            end
            if ~isempty(DA.GetDICData())
                DA.GetDICData().PrintSelf();
            else
                fprintf(1,'No DIC data class associated\n');
            end
            if ~isempty(DA.GetDisplacementData())
                DA.GetDisplacementData().PrintSelf();
            else
                fprintf(1,'No Displacement data class associated\n');
            end
        end    
    end %  public methods
    
    methods (Access = private, Hidden = true)
        function CalcCommonTime(DA)
            % A function to calculate a common time vector  in seconds.
            %
            % DA.CalcCommonTime()
            %
            
            % define time as 200 ms before to 500 ms after trigger.
            DA.m_time = -0.200:1/DA.GetCommonTimeRate():0.5;
        end
        
        function InterpolateDAQToCommonTime(DA)
            % A function to interpolate the DAQ data to the common time.
            % If the common time has not been defined, it will be 
            % defined here.
            %
            % DA.InterpolateDAQToCommonTime()
            %
            
            % check for common time
            if isempty(DA.GetTime())
                DA.CalcCommonTime();
            end
            
            daqTime = DA.GetDAQData().GetTime();
            
            % interpolate the single axis load cell
            DA.m_forceOne = interp1(daqTime,DA.GetDAQData().GetForceOne(),DA.GetTime());
            
            % interpolate the six axis load cell
            forceSix = DA.GetDAQData().GetForceSix();
            DA.m_forceSix(:,1) = interp1(daqTime,forceSix(:,1),DA.GetTime());
            DA.m_forceSix(:,2) = interp1(daqTime,forceSix(:,2),DA.GetTime());
            DA.m_forceSix(:,3) = interp1(daqTime,forceSix(:,3),DA.GetTime());
            DA.m_forceSix(:,4) = interp1(daqTime,forceSix(:,4),DA.GetTime());
            DA.m_forceSix(:,5) = interp1(daqTime,forceSix(:,5),DA.GetTime());
            DA.m_forceSix(:,6) = interp1(daqTime,forceSix(:,6),DA.GetTime());
            
            % interpolate the strain data
            DA.m_strainGauge(:,1) = interp1(daqTime,DA.GetDAQData().GetStrainGauge1(),DA.GetTime());
            DA.m_strainGauge(:,2) = interp1(daqTime,DA.GetDAQData().GetStrainGauge2(),DA.GetTime());
            DA.m_strainGauge(:,3) = interp1(daqTime,DA.GetDAQData().GetStrainGauge3(),DA.GetTime());
            
            % interpolate the principal strain data
            
            DA.m_strainPrincipalGauge(:,1) = interp1(daqTime,DA.GetDAQData().GetPrincipalStrain1(),DA.GetTime());
            DA.m_strainPrincipalGauge(:,2) = interp1(daqTime,DA.GetDAQData().GetPrincipalStrain2(),DA.GetTime());
            DA.m_strainPrincipalGauge(:,3) = interp1(daqTime,DA.GetDAQData().GetPrincipalStrainAngle(),DA.GetTime());
        end
        
        function InterpolateDisplacementDataToCommonTime(DA)
            % A function to interpolate the displacment data to the
            % common time. If the common time has not been defined, it
            % will be defined here.
            %
            % DA.InterpolateDisplacementDataToCommonTime()
            %
            
            % check common time vector
            if isempty(DA.GetTime())
                DA.CalcCommonTime();
            end
            
            dispTime = DA.GetDisplacementData().GetTime();
            % interpolate the displacements
            DA.m_displacementTroch = interp1(dispTime,DA.GetDisplacementData().GetDisplacementTroch(),DA.GetTime());
            DA.m_displacementHammer = interp1(dispTime,DA.GetDisplacementData().GetDisplacementHammer(),DA.GetTime());
        end
        
        function InterpolateDICToCommonTime(DA)
            % A function to interpolate the DIC data to the common time
            % If the common time has not been defined, it will be
            % defined here.
            %
            % DA.InterpolateDICToCommonTime()
            %
            
            % check for common time vector
            if isempty(DA.GetTime() )
                DA.CalcCommonTime();
            end
            
            dicTime = DA.GetDICData().GetTime();
            % interpolate the DIC data
            DA.m_strainDIC = interp1(dicTime,DA.GetDICData().GetStrainData(),DA.GetTime());
        end
        
        function CalcDisplacementPlaten(DA)
            % A function to calculate the lower platen displacement using
            % partial derivatives. Only works once the daq data has been
            % interpolated to the common time.
            %
            % DA.CalcPlatenDisplacement()
            %
            
            % check for time
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','Lower platen displacement calculation was attempted for %s before daq data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            initialConditions = [0,0];
            
            % solve the equations numerically
            [~,x] = ode45(@(t,x) PlatenODE(DA,t,x),DA.GetTime(),initialConditions);
            
            % once the solution is finished the platen displacement is the first column of the vector
            forceSix = DA.GetForceSix();
            DA.m_displacementPlaten = x(:,1) + DA.GetComplianceLoadingPlate().*forceSix(:,3);
            
        end
        
        function dxdt = PlatenODE(DA,t,x)
            % A function for the calculation of the lower platen displacement
            % using the ode45 function.
            
            m = DA.m_massDropTower;
            k = 1/DA.m_complianceDropTower;
            
            % displacement of the platen is the first component
            xP = x(1);
            % velocity of the platen is the second component
            xPdot = x(2);
            
            % create the derivatives matrix
            dxdt = zeros(size(x));
            % derivative of the first component is the velocity of the platen
            dxdt(1) = xPdot;
            % derivative of the second component is the acceleration of the platen, which sums to F/m
            dxdt(2) = 1/m*(DA.GetForceSixCompressionAtTime(t) - k*xP);
        end
        
        function CalcCompressionAtForceMax(DA)
            % A function to calculate the compression of the specimen at
            % the max force as determined by CalcForceMax().
            %
            % DA.CalcCompressionAtForceMax()
            %
            
            % check if index at max force is available
            if isempty(DA.GetIndexForceMax())
                error('DropTowerAnalysis:DataAvailability','The compression at max force for %s was requested before the max force index was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetCompression())
                error('DropTowerAnalysis:DataAvailability','The compression at max force for %s was requested before compression was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            comp = DA.GetCompression();
            DA.m_compressionAtForceMax = comp(DA.GetIndexForceMax() );
        end
        
        function CalcCompressionAtForceInstronMax(DA)
            % A function to calculate the compression of the specimen at
            % the max instron force.
            %
            % DA.CalcCompressionAtForceMax()
            %
            
            % check if index at max force is available
            if isempty(DA.GetIndexForceMax())
                error('DropTowerAnalysis:DataAvailability','The compression at max instron force for %s was requested before the max force index was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetCompression())
                error('DropTowerAnalysis:DataAvailability','The compression at max instron force for %s was requested before compression was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            comp = DA.GetCompression();
            DA.m_compressionAtForceInstronMax = comp(DA.GetIndexForceInstronMax() );
        end
        
        function CalcImpactStart(DA)
            % A function to get the start of the impact. This will find
            % the start and set the properties m_timeAtImpactStart and
            % m_indexAtImpactStart. These can be accessed using:
            %   GetTimeImpactStart() and GetIndexImpactStart()
            %
            % This works by finding the first point where z-comp of the 
            % six axis load cell is >100 N. It then finds the last time
            % before that point when force was <20 N. This is taken as
            % the start of the impact.
            %
            % DA.CalcImpactStart()
            %
            
            % check that the six axis force is available
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','The start of the impact was requested for %s before the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            % find the first index where force is >100 N
            forceSix = DA.GetForceSix();
            index100 = find(forceSix(:,3) > 100,1,'first');
            
            % find the last time that the force was <20 N, using index100 as an upper limit of search
            index20 = find(forceSix(1:index100,3) < 20,1,'last');
            
            % save that index, and the time of that index
            DA.m_indexAtImpactStart = index20;
            expTime = DA.GetTime();
            DA.m_timeAtImpactStart = expTime(index20);
        end
        
        function CalcForceMax(DA)
            % A function to get the max force after the linear part of the 
            % impact. Uses the z-comp of the six axis load cell. This will 
            % set the properties m_ForceMax, m_indexForceMax, m_timeForceMax,
            % m_strainDICAtForceMax, m_strainPrincipalGaugeAtForceMax
            % which all have methods that will allow for access.
            %
            % Since the absolute max force in the trace may be different
            % than the max after the linear portion of the impact, the user
            % must help identify the max force. This function will open a
            % plot and the user should click near the true max force, the
            % fucntion will take a window .5 ms wide and find the max in
            % that window.
            % 
            % DA.CalcForceMax()
            %
            
            % check that the six axis data is available
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','The max force for %s was requested before the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            % find the max for the six axis load cell after the start of the impact
            forceSix = DA.GetForceSix();
            time = DA.GetTime();
            % plot a the force vs time
            maxForcePlotH = figure;
            plot(time,forceSix(:,3));
            msgBoxH = msgbox('Please zoom in and press OK to select the max force','Maximum Force Selection','help');
            uiwait(msgBoxH);
            % select the approx max
            [x,~] = ginput(1);
            % find the actual max within 2.5 ms of the approx        
            nIndexes = .0005*DA.GetCommonTimeRate();
            range = find(time > (x-.00025),nIndexes,'first');
            [rangeVM,rangeIM] = max(forceSix(range,3));
            close(maxForcePlotH)
            
            valueM = rangeVM;
            indexM = rangeIM-1+range(1);
 
            % set the max force properties
            DA.m_forceMax = valueM;
            DA.m_indexAtForceMax = indexM;
        end
        
        function CalcPropertiesForceMax(DA)
            % A function to calculate the properties that depend on the
            % maximum force, such as stiffness and strain at max force.
            % This should be called after CalcForceMax. If the max force is
            % not being selected, but reused from a previously set value,
            % then this can be called without calling CalcForceMax
            %
            % DA.CalcPropertiesAtForceMax()
            %
            
            indexM = DA.GetIndexForceMax();
            % Time at force max
            expTime = DA.GetTime();
            DA.m_timeAtForceMax = expTime(indexM);
            
            % gauge strain at force max
            strainG = DA.GetPrincipalStrain();
            DA.m_strainPrincipalGaugeAtForceMax = strainG(indexM,:);
            
            % If DIC data is available, get the dic strain at max force
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                dic = DA.GetStrainDIC();
                DA.m_strainDICAtForceMax = median(dic(indexM-2:indexM+2));
            end
            
            % If disp data is available, get the compression at max force
            if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                disp = DA.GetCompression();
                DA.m_compressionAtForceMax = disp(indexM);
            end
            
        end
            
            
      
        function CalcImpactFinish(DA)
            % A function to get the finish of the impact. This will find
            % the first time after max force that the force goes below
            % 200 N and will set the properties m_timeAtImpactFinish and
            % m_indexAtImpactFinish. These can be accessed using:
            %   GetTimeImpactFinish() and GetIndexImpactFinish()
            %
            % DA.CalcImpactFinish()
            %
            
            % check if the max force has been calculated
            if isempty(DA.GetIndexForceMax())
                error('DropTowerAnalysis:DataAvailability','The end of the impact was requested for %s before the maximum force was found. The calculation of the end relies on knowledge of the time of the max force.\n',DA.GetSpecimen().GetSpecimenName() );
            end
            
            % find the first time the force is below zero after the max force
            forceSix = DA.GetForceSix();
            index0Trunk = find(forceSix(DA.GetIndexForceMax:end,3) < 200,1,'first');
            % account for the limited scope of the find
            index0 = index0Trunk-1+DA.GetIndexForceMax();
            
            % set the impact finish properties.
            expTime = DA.GetTime();
            DA.m_indexAtImpactFinish = index0;
            DA.m_timeAtImpactFinish = expTime(index0);
        end
        
        function CalcForceInstronMax(DA)
            % A function to get the index and time when the z-comp of the
            % six axis load cell first exceeds the max force in the instron.
            % Requires that the max intron force and the six axis load
            % cell forces are defined. Will set the properties:
            %   m_indexAtForceInstronMax and m_timeAtForceInstronMax
            % both of which have Get methods.
            %
            % Returns the first time and index when the max force is '
            % greater than the instron force.
            %
            % DA.CalcForceInstronMax()
            %
            
            % check for instron force max
            if isempty(DA.GetForceInstronMax())
                error('DropTowerAnalysis:DataAvailability','The time and index at the max instron force for %s were requested before the max instron force was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','The time and index at the max instron force for %s were requested before the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            forceSix = DA.GetForceSix();
            indexIM = find(forceSix(:,3) > DA.GetForceInstronMax(),1,'first');
            
            expTime = DA.GetTime();
            
            DA.m_indexAtForceInstronMax = indexIM;
            DA.m_timeAtForceInstronMax = expTime(indexIM);
            
            % Gauge Strains
            strainG = DA.GetPrincipalStrain();
            DA.m_strainGaugeAtForceInstronMax = strainG(indexIM,:);
            
            % If DIC for the DT is available, get the DIC strain at max instron force
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                dic = DA.GetStrainDIC();
                DA.m_strainDICAtForceInstronMax = median(dic(indexIM-2:indexIM+2));
            end
            
            % If disp is available, get the compression at max instron force
            if DA.GetSpecimen().GetDataAvailable().DropTowerDisplacement
                comp = DA.GetCompression();
                DA.m_compressionAtForceInstronMax = comp(indexIM);
            end
        end
        
        function CalcStiffness(DA)
            % A function to calculate the stiffness from the beginning 
            % of the impact to the max force as defined in CalcForceMax()
            % Gets the stiffness in N/m.
            %
            % DA.CalcStiffness()
            %
            
            % verify that the needed data is available
            if isempty(DA.GetForceMax())
                error('DropTowerAnalysis:DataAvailability','Stiffness for %s was requested before max force was calaculated.\n',DA.GetSpecimen().GetSpecimenName());
            end           
            if isempty(DA.GetCompressionForceMax())
                error('DropTowerAnalysis:DataAvailability','Stiffness for %s was requested before the compression at max force was calaculated.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            force = DA.GetForce;
            compression = DA.GetCompression;
            indexMax = DA.GetIndexForceMax;
            
            % find the forces and compressions at 25% and 90% of force max
            index90 = find(force(1:indexMax)<DA.GetForceMax*0.9,1,'last');        
            force90 = force(index90);
            comp90 = compression(index90);
            
            index25 = find(force(1:indexMax)<DA.GetForceMax*0.25,1,'last');
            force25 = force(index25);
            comp25 = compression(index25);
            
            
            DA.m_stiffness = (force90-force25)/(comp90-comp25);
        end
        
        function CalcEnergyToForceMax(DA)
            % A function to calculate the energy in J to the max force as 
            % defined in CalcForceMax()
            %
            % DA.CalcEnergyToForceMax()
            %
            if isempty(DA.GetIndexImpactStart())
                error('DropTowerAnalysis:DataAvailability','Energy to the max force for %s was requested before the start of the impact was defined.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetIndexForceMax())
                error('DropTowerAnalysis:DataAvailability','Energy to the max force for %s was requested before the max force was found.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetCompression())
                error('DropTowerAnalysis:DataAvailability','Energy to the max force for %s was requested the compression was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','Energy to the max force for %s was requested the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            forceSix = DA.GetForceSix();
            compression = DA.GetCompression();
            range = DA.GetIndexImpactStart():DA.GetIndexForceMax();
            
            DA.m_energyToForceMax = trapz(compression(range), forceSix(range,3));
        end
        
        function CalcEnergyToForceInstronMax(DA)
            % A function to calculate the energy in J to the maximum force
            % in the instron.
            %
            % DA.CalcEnergyToForceInstronMax()
            %
            if isempty(DA.GetIndexImpactStart())
                error('DropTowerAnalysis:DataAvailability','Energy to the max instron force for %s was requested before the start of the impact was defined.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetIndexForceInstronMax())
                error('DropTowerAnalysis:DataAvailability','Energy to the max instron force for %s was requested before the max force was set.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetCompression())
                error('DropTowerAnalysis:DataAvailability','Energy to the max instron force for %s was requested the compression was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','Energy to the max instron force for %s was requested the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            forceSix = DA.GetForceSix();
            compression = DA.GetCompression();
            range = DA.GetIndexImpactStart():DA.GetIndexForceInstronMax();
            
            DA.m_energyToForceInstronMax = trapz(compression(range), forceSix(range,3));
        end
        
        function CalcEnergyToImpactFinish(DA)
            % A function to calculate the energy in J to the finish of 
            % the impact as defined in CalcImpactFinish().
            %
            % DA.CalcEnergyToImpactFinish()
            %
            if isempty(DA.GetIndexImpactStart())
                error('DropTowerAnalysis:DataAvailability','Energy to the impact finish for %s was requested before the start of the impact was defined.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetIndexImpactFinish())
                error('DropTowerAnalysis:DataAvailability','Energy to the impact finish for %s was requested before the end of the impact was defined.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetCompression())
                error('DropTowerAnalysis:DataAvailability','Energy to the impact finish for %s was requested the compression was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','Energy to the impact finish for %s was requested the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            forceSix = DA.GetForceSix();
            compression = DA.GetCompression();
            range = DA.GetIndexImpactStart():DA.GetIndexImpactFinish();
            
            DA.m_energyToImpactFinish = trapz(compression(range), forceSix(range,3));
        end
        
        function CalcFrameForceMax(DA)
            % A function to calculate the DIC frame number at the maximum
            % force, as determined by CalcForceMax().
            %
            % DA.CalcFrameForceMax()
            %
            
            % check for the six axis load cell
            if isempty(DA.GetTimeForceMax())
                error('DropTowerAnalysis:DataAvailability','DIC frame at max force for %s was requested before the time of the max force was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            % check for the DIC data
            if isempty(DA.GetDICData())
                error('DropTowerAnalysis:DataAvailability','DIC frame at max force for %s was requested when no DIC data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            timeDICForceMax = DA.GetTimeForceMax() - DA.GetDICData().GetTimeStart();
            DA.m_frameAtForceMax = floor(timeDICForceMax*DA.GetDICData().GetSampleRate());
        end
        
        function CalcFrameForceInstronMax(DA)
            % A function to calculate the DIC frame number at the maximum
            % force in the instron.
            %
            % DA.CalcFrameForceInstronMax()
            %
            
            % check for the max instron force
            if isempty(DA.GetTimeForceInstronMax())
                error('DropTowerAnalysis:DataAvailability','DIC frame at max instron force for %s was requested before the time of the max instron force was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            % check for the DIC data
            if isempty(DA.GetDICData())
                error('DropTowerAnalysis:DataAvailability','DIC frame at max instron force for %s was requested when no DIC data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            timeDICForceInstronMax = DA.GetTimeForceInstronMax() - DA.GetDICData().GetTimeStart();
            DA.m_frameAtForceInstronMax = floor(timeDICForceInstronMax*DA.GetDICData().GetSampleRate());
        end
        
        function CalcCompression(DA)
            % A function to calculate the compression of the specimen
            % based on the displacement of the trochanter and the 
            % motion of the lower platen
            %
            % DA.CalcCompression()
            %
            
            % check for displacement
            if isempty(DA.GetDisplacementTroch())
                error('DropTowerAnalysis:DataAvailability','The compression of %s was requested before the trochanter displacement was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetDisplacementPlaten())
                error('DropTowerAnalysis:DataAvailability','The compression of %s was requested before the platen displacement was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            dispTroch = DA.GetDisplacementTroch();
            
            DA.m_compression = dispTroch(:,1) - DA.GetDisplacementPlaten();
        end
        
        function CalcRateCompression(DA)
            % A function to calculate the rate of displacement of the specimen
            % in m/s. Finds the average loading rate betwen the start
            % of the impact and the max force.
            %
            % DA.CalcRateDisplacement()
            %
            if isempty(DA.GetIndexForceMax())
                error('DropTowerAnalysis:DataAvailability','Compression rate was requested for %s before max force was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            if isempty(DA.GetIndexImpactStart())
                error('DropTowerAnalysis:DataAvailability','Compression rate was requested for %s before the impact start was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            comp = DA.GetCompression();
            time = DA.GetTime();
            
            DA.m_rateCompression = (comp(DA.GetIndexForceMax()) - comp(DA.GetIndexImpactStart()))/(time(DA.GetIndexForceMax())-time(DA.GetIndexImpactStart()));
        end
            
    end % private methods
end % classdef
