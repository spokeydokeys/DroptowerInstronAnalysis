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
        m_dropTowerMass = 95.9; % kg. The mass of the drop tower load platen, load cell and experimenatl apparatus
        
        % result vecotrs members
        m_time;
        m_forceSix;
        m_forceOne;
        m_displacementTroch;
        m_displacementHammer;
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
        m_stiffness; %
        m_indexAtImpactStart; %
        m_timeAtImpactStart; %
        % results at max force
        m_energyToForceMax; %
        m_forceMax; %
        m_strainDICAtForceMax; %
        m_strainGaugeAtForceMax;   % given as [P1, P2, angle] in absolute and radians
        m_frameAtForceMax;  %%% TO DO %%%
        m_timeAtForceMax; %
        m_indexAtForceMax; %
        m_compressionAtForceMax; %
        
        % results for max instron force
        m_energyToForceInstronMax;
        m_forceInstronMax; %
        m_strainDICAtForceInstronMax; %
        m_strainGaugeAtForceInstronMax; %
        m_frameAtForceInstronMax;  %%% To Do %%%
        m_timeAtForceInstronMax; %
        m_indexAtForceInstronMax; %
        m_compressionAtForceInstronMax; %
        
        % results for finish
        m_energyToImpactFinish; %
        m_timeAtImpactFinish; % time of the end of the impact. Will be used to calculate total energy
        m_indexAtImpactFinish; %
        
        %% To do list:
            % frame at max force
            % frame at max instron force
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
                DA.m_displacementData = DTDisplacement(specimen);
            end
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                DA.m_dicData = DICData(specimen);
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
        
        function SetDropTowerCompliance(DA,compliance)
            % A function to set the drop tower compliance in m/N.
            %
            % DA.SetDropTowerCompliance(compliance)
            %
            if DA.m_dropTowerCompliance ~= compliance
                DA.m_dropTowerCompliance = compliance;
            end
        end
        
        function o = GetDropTowerCompliance(DA)
            % A function to get the drop tower compliance in m/N.
            %
            % Complicance = DA.GetDropTowerCompliance()
            %
            o = DA.m_dropTowerCompliance;
        end
        
        function SetDropTowerMass(DA,mass)
            % A function to set the drop tower mass in kg.
            %
            % DA.SetDropTowerMass(mass)
            %
            if DA.m_dropTowerMass ~= mass
                DA.m_dropTowerMass = mass;
            end
        end
        
        function o = GetDropTowerMass(DA)
            % A function to get the drop tower mass in kg.
            %
            % Mass = DA.GetDropTowerMass()
            %
            o = DA.m_dropTowerMass;
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
        
        function o = GetStrainGauge1(DA)
            % A function to get the strain from strain gauge one in
            % absolute strain.
            %
            % Strain = DA.GetStrainGauge1()
            %
            o = DA.m_strainGauge1;
        end
        
        function o = GetStrainGauge2(DA)
            % A function to get the strain from strain gauge two in
            % absolute strain.
            %
            % Strain = DA.GetStrainGauge2()
            %
            o = DA.m_strainGauge2;
        end
        
        function o = GetStrainGauge3(DA)
            % A function to get the strain from strain gauge three in
            % absolute strain.
            %
            % Strain = DA.GetStrainGauge3()
            %
            o = DA.m_strainGauge3;
        end
        
        function o = GetPrincipalStrain1(DA)
            % A function to get the first principal strain from the gauge
            % in absolute strain.
            %
            % Strain = DA.GetPrincipalStrain1()
            %
            o = DA.m_strainGaugeP1;
        end
        
        function o = GetPrincipalStrain2(DA)
            % A function to get the second principal strain from the
            % gauge in absolute strain.
            %
            % Strain = DA.GetPrincipalStrain2()
            %
            o = DA.m_strainGaugeP2;
        end
        
        function o = GetPrincipalStrainAngle(DA)
            % A function to ge the angle of the principal strain from
            % the gauge in radians. The angle is referenced to gauge A
            % as defined in Appendix G of 
            % Budynas R.G. Advanced Strength and Applied Stress 
            % Analysis, Second ed. McGraw Hill. ISBN 0-07-008985-X
            %
            % Angle = DA.GetPrincipalStrainAngle()
            %
            o = DA.m_strainGaugePhi;
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
            % load cell
            %
            % Strain = DA.GetStrainDICAtForceMax()
            %
            o = DA.m_strainDICAtForceMax;
        end
        
        function o = GetStrainDICAtForceInstronMax(DA)
            % A function to get the DIC strain in absolute strain at
            % the max instron force, defined in the drop tower using the
            % z-comp of the six axis load cell.
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
            o = DA.m_strainGaugeAtForceMax;
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
            % A function to get the force from the six axis load cell,
            % z-comp at an arbitrary time using interpolation. The force
            % is given in N.
            %
            % Force = DA.GetSixCompressionForceAtTime(time)
            %
            
            forceSix = DA.GetForceSix();
            
            o = interp1(DA.GetTime(),forceSix(:,3),time);
        end
    end %  public methods
    
    methods (Access = private, Hidden = true)
        function CalcCommonTime(DA)
            % A function to calculate a common time vector  in seconds.
            %
            % DA.CalcCommonTime()
            %
            
            % define time as 200 ms before to 500 ms after trigger.
            DA.m_time = -0.200:0.0001:0.5;
        end
        
        function InterpolateDAQToCommonTime(DA)
            % A function to interpolate the DAQ data to the common time.
            % If the common time has not been defined, it will be 
            % defined here.
            %
            % DA.InterpolateDAQToCommonTime()
            %
            
            % check for common time
            if isempty(DT.GetTime())
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
            DA.m_strainGauge1 = interp1(daqTime,DA.GetDAQData().GetStrainGauge1(),DA.GetTime());
            DA.m_strainGauge2 = interp1(daqTime,DA.GetDAQData().GetStrainGauge2(),DA.GetTime());
            DA.m_strainGauge3 = interp1(daqTime,DA.GetDAQData().GetStrainGauge3(),DA.GetTime());
            
            % interpolate the principal strain data
            DA.m_strainGaugeP1 = interp1(daqTime,DA.GetDAQData().GetPrincipalStrain1(),DA.GetTime());
            DA.m_strainGaugeP2 = interp1(daqTime,DA.GetDAQData().GetPrincipalStrain2(),DA.GetTime());
            DA.m_strainGaugePhi = interp1(daqTime,DA.GetDAQData().GetPrincipalStrainAngle(),DA.GetTime());
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
            % DA.InterpolateDICToCommonTim()
            %
            
            % check for common time vector
            if isempty(DA.GetTime() )
                DA.CalcCommonTime();
            end
            
            dicTime = DA.GetDICData().GetTime();
            % interpolate the DIC data
            DA.m_strainDIC = interp1(dicTime,DA.GetDICData().GetStrainData(),DA.GetTime());
        end
        
        function CalcPlatenDisplacement(DA)
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
            [t,x] = ode45(DA@PlatenODE,DA.GetTime(),initialConditions);
            
            % once the solution is finished the platen displacement is the first column of the vector
            DA.m_displacementPlaten = x(:,1);
            
        end
        
        function dxdt = PlatenODE(DA,t,x)
            % A function for the calculation of the lower platen displacement
            % using the ode45 function.
            
            m = DA.m_dropTowerMass;
            k = 1/DA.m_dropTowerCompliance;
            
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
            % A function to get the max force in the impact. Uses the 
            % z-comp of the six axis load cell. This will set the 
            % properties m_ForceMax, m_indexForceMax, m_timeForceMax,
            % m_strainDICAtForceMax, m_strainGaugeAtForceMax
            % which all have methods that will allow for access.  
            % 
            % DA.CalcForceMax()
            %
            
            % check that the six axis data is available
            if isempty(DA.GetForceSix())
                error('DropTowerAnalysis:DataAvailability','The max force for %s was requested before the six axis load cell data was available.\n',DA.GetSpecimen().GetSpecimenName());
            end
            
            % find the max for the six axis load cell after the start of the impact
            forceSix = DA.GetForceSix();
            [valM,indexM] = max(forceSix(:,3));
            
            % set the max force properties
            DA.m_forceMax = valM;
            DA.m_indexAtForceMax = indexM;
            expTime = DA.GetTime();
            DA.m_timeAtForceMax = expTime(indexM);
            strainG1 = DA.GetPrincipalStrain1()
            strainG2 = DA.GetPrincipalStrain2();
            strainGA = DA.GetPrincipalStrainAngle();
            DA.m_strainGaugeAtForceMax = [strainG1(indexM) strainG2(indexM) strainGA(indexM)];
            
            % If DIC data is available, get the dic strain at max force
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                dic = DA.GetStrainDIC();
                DA.m_strainDICAtForceMax = dic(indexM);
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
            % zero and will set the properties m_timeAtImpactFinish and
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
            forceSix = DA.GetForceSix()
            index0Trunk = find(forceSix(DA.GetIndexForceMax:end) < 0,1,'first');
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
            
            forceSix = DA.GetForceSix()
            indexIM = find(forceSix(:,3) > DA.GetForceInstronMax(),1,'first');
            
            expTime = DA.GetTime();
            
            DA.m_indexAtForceInstronMax = indexIM;
            DA.m_timeAtForceInstronMax = expTime(indexIM);
            
            % Gauge Strains
            strainG1 = DA.GetPrincipalStrain1()
            strainG2 = DA.GetPrincipalStrain2();
            strainGA = DA.GetPrincipalStrainAngle();
            DA.m_strainGaugeAtForceInstronMax = [strainG1(indexIM) strainG2(indexIM) strainGA(indexIM)];
            
            % If DIC for the DT is available, get the DIC strain at max instron force
            if DA.GetSpecimen().GetDataAvailable().DropTowerDIC
                dic = DT.GetStrainDIC();
                DA.m_strainDICAtForceInstronMax = dic(indexIM);
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
            
            DA.m_stiffness = DA.GetForceMax()/DA.GetCompressionAtForceMax();
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
            
            DA.m_energyToForceMax = trapz(compression(range), forceSix(range,3));
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
            
            DA.m_energyToForceMax = trapz(compression(range), forceSix(range,3));
        end
        
    end % private methods
end % classdef
