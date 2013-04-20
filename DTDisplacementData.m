classdef DTDisplacementData < handle
    properties (SetAccess = private, Hidden = false)
        m_specimen;
    end
    
    properties (SetAccess = private, Hidden = true)
        m_displacementTroch;    % displacement of the trochanter
        m_displacementHammer;   % displacement of the impact hammer
        m_displacementTrochFilt;    % displacement of the trochanter, filtered
        m_displacementHammerFilt;   % displacement of the hammer, filtered
        m_timeDisplacement;     % time of the values in displacement camera time
        m_time;
        m_timeStart = 0;            % time of the first data point, experiment time
        m_sampleRate = 0;           % camera sample rate in Hz
        m_filterCutoff = 500;   % filter cutoff frequency in Hz
        m_filterOrder = 2;      % butterworth filter order. Must be even, odd orders will be increased by 1
        m_fileName = '';             % the raw TEMA data file
    end % properties
    
    methods
        % Constructor
        function DTDD = DTDisplacementData(specimen)
            % The constructor to create a drop tower displacement data
            % object. The only input is a specimen object. See Specimen.m
            % for details on the creation of a specimen object.
            %
            % DTDD = DTDisplacementData(specimen)
            %
            DTDD.m_specimen = specimen;
        end
        
        function o = GetSpecimen(DTDD)
            % A function to get the specimen object associated with the
            % DT Displacment Data object at creation time.
            %
            % Specimen = DTDD.GetSpecimen()
            %
            o = DTDD.m_specimen;
        end
        
        function SetFileName(DTDD,file)
            % A function to set the name of the displacement data file.
            %
            % DTDD.SetFileName(file)
            %
            if ~strcmp(DTDD.m_fileName,file)
                if ~exist(file,'file')
                    error('DropTowerDisplacement:DataAvailability','The specified displacement file for %s does not exist.\n',DTDD.GetSpecimen().GetSpecimenName());
                end
                DTDD.m_fileName = file;
            end
        end
        function o = GetFileName(DTDD)
            % A funtion to get the name of the file containing the drop
            % tower displacement data.
            %
            % Name = DTDD.GetFileName()
            %
            o = DTDD.m_fileName;
        end
        
        function SetTimeStart(DTDD,time)
            % A function to set the displacement data in seconds. In some
            % cases the first data point of the displacement data will
            % not line up with the trigger (ie experiment time) and this
            % value is used to correct for that offset.
            %
            % DTDD.SetTimeStart(time)
            %
            if DTDD.m_timeStart ~= time
                DTDD.m_timeStart = time;
            end
        end
        function o = GetTimeStart(DTDD)
            % A function to get the time of the first data point in the
            % displacement data in terms of time post trigger. The value is
            % in seconds
            %
            % Time = DTDD.GetTimeStart()
            %
            o = DTDD.m_timeStart;
        end
        
        function SetSampleRate(DTDD,rate)
            % A function to set the sampling rate of the displacement
            % data in Hz.
            %
            % DTDD.SetSampleRate(rate)
            %
            if DTDD.m_sampleRate ~= rate
                DTDD.m_sampleRate = rate;
            end
        end
        function o = GetSampleRate(DTDD)
            % A function to get the sample rate of the displacement data in
            % Hz.
            %
            % Rate = DTDD.GetSampleRate()
            %
            o = DTDD.m_sampleRate;
        end
        
        function ReadFile(DTDD)
            % A function to read the specifed file containing the
            % displcement data. Time should be in ms and the displacement
            % in mm.
            %
            % DTDD.ReadFile()
            %
            if isempty(DTDD.m_fileName)
                error('DropTowerDisplacement:DataAvailability','File read was called for %s when no file name has been set.\n',DTDD.GetSpecimen().GetSpecimenName());
            end
            % read the file
            data = importdata(DTDD.m_fileName,'\t');
            % find the shortest data filed
            validData = ~isnan(data.data);
            startIndex = max([find(validData(:,1),1,'first'),find(validData(:,2),1,'first'),find(validData(:,3),1,'first'),find(validData(:,4),1,'first'),find(validData(:,5),1,'first')]);
            endIndex = min(  [find(validData(:,1),1,'last'), find(validData(:,2),1,'last'), find(validData(:,3),1,'last'), find(validData(:,4),1,'last'), find(validData(:,5),1,'last')] );                
            
            % import the time data
            DTDD.m_timeDisplacement = data.data(startIndex:endIndex,1)./1000;
            % import the impact hammer data and convert to m
            DTDD.m_displacementHammer = [data.data(startIndex:endIndex,2), data.data(startIndex:endIndex,3) ]./1000;
            DTDD.m_displacementTroch = [data.data(startIndex:endIndex,4), data.data(startIndex:endIndex,5) ]./1000;
        end
        
        function o = GetDisplacementTrochUnfiltered(DTDD)
            % A function to get the unfiltered displacement of the
            % trochanter in m.
            %
            % Displacement = DTDD.GetDisplacementTrochUnfiltered()
            %
            o = DTDD.m_displacementTroch;
        end
        function o = GetDisplacementHammerUnfiltered(DTDD)
            % A function to get the unfiltered displacement of the impact
            % hammer in m.
            %
            % Displacement = DTDD.GetDisplacementHammerUnfiltered()
            %
            o = DTDD.m_displacementHammer;
        end
        
        function SetFilterCutoff(DTDD,rate)
            % A function to set the filter cutoff frequency in Hz. The
            % default value is 500 Hz.
            %
            % DTDD.SetFilterCutoff(cutoff)
            %
            if DTDD.m_filterCutoff ~= rate
                DTDD.m_filterCutoff = rate;
            end
        end
        function o = GetFilterCutoff(DTDD)
            % A function to get the filter cutoff frequency in Hz.
            %
            % Cutoff = DTDD.GetFilterCutoff()
            %
            o = DTDD.m_filterCutoff;
        end
        
        % functions to set get the filter order
        function SetFilterOrder(DTDD,order)
            % A funtion to set the order of the butterworth filter. Since
            % the algorithm uses the filtfilt function only even filter
            % orders will be accepted. If an odd filter order is proveded,
            % it will be incremented by one. The filtfilt function is
            % passed the order suppled/2. The forward reverse nature of
            % filtfilt effectively doubles the filter order.
            %
            % DTDD.SetFilterOrder(order)
            %
            if mod(order, 2)
                warning('DropTowerDisplacement:DataValues','The filter order for %s was set to an odd number. Only even orders are accepted. The order is being increased by one.\n',DTDD.GetSpecimen().GetSpecimenName());
                order = order +1;
            end
            DTDD.m_filterOrder = order;
        end
        function o = GetFilterOrder(DTDD)
            % A function to get the filter order.
            %
            % Order = DTDD.GetFilterOrder()
            %
            o = DTDD.m_filterOrder;
        end

        function o = GetDisplacementTroch(DTDD)
            % A function to get the filtered trochanter displacement data
            % in m.
            %
            % Displacement = DTDD.GetDisplacementTroch()
            %
            if isempty(DTDD.m_displacementTrochFilt)
                if isempty(DTDD.m_displacementTroch)
                    error('DropTowerDisplacement:DataAvailability','Trochanter displacement was requested for %s before displacement data was available.\n',DTDD.GetSpecimen().GetSpecimenName());
                end
                DTDD.CalcFilteredData();
            end
            o = DTDD.m_displacementTrochFilt;
        end
        
        function o = GetDisplacementHammer(DTDD)
            % A function to get the filtered impact hammer displecent data
            % in m.
            %
            % Displacement = DTDD.GetDisplacementHammer()
            %
            if isempty(DTDD.m_displacementTrochFilt)
                if isempty(DTDD.m_displacementTroch)
                    error('DropTowerDisplacement:DataAvailability','Hammer displacement was requested for %s before displacement data was available.\n',DTDD.GetSpecimen().GetSpecimenName());
                end
                DTDD.CalcFilteredData();
            end
            o = DTDD.m_displacementHammerFilt;
        end
        
        function o = GetTimeDisplacement(DTDD)
            % A funtion to get the time in seconds in the displacement data
            % time frame. If there is an offest between the first data
            % point in the displacement this data will not line up with the
            % experimental data. Use DTDD.GetTime() to get time in the
            % experimental time frame.
            %
            % Time = DTDD.GetTimeDisplacement()
            %
            o = DTDD.m_timeDisplacement;
        end
        
        function o = GetTime(DTDD)
            % A function to get the time in seconds in the experimental
            % time frame. If no start time has been set, a warning will be
            % issued.
            %
            % Time = DTDD.GetTime()
            %
            if isempty(DTDD.GetTimeStart())
                warning('DropTowerDisplacement:DataAvailability','Time was requested for %s before start time was supplied. The time will not be referenced to the experiment.\n',DTDD.GetSpecimen().GetSpecimenName());
            end
            if isempty(DTDD.m_time)
                DTDD.m_time = DTDD.GetTimeDisplacement() + DTDD.GetTimeStart();
            end
            o = DTDD.m_time;
        end
        
        function Update(DTDD)
            % A function to update the state of the drop tower 
            % displacement data object. This method does not call 
            % ReadFile(), which must be done by the user.
            %
            % DTDD.Update()
            %
            
            % check if sample rate and start time have been set
            if isempty(DTDD.GetSampleRate())
                error('DropTowerDisplacement:DataAvailable','Update was called for %s when no sample rate has been set.\n',DTDD.GetSpecimen().GetSpecimenName());
            end
            if isempty(DTDD.GetTimeStart())
                error('DropTowerDisplacement:DataAvailable','Update was called for %s when no start time has been set.\n',DTDD.GetSpecimen().GetSpecimenName());
            end
            
            % check for raw data
            if ( isempty(DTDD.GetDisplacementHammerUnfiltered) || isempty(DTDD.GetDisplacementTrochUnfiltered) )
                error('DropTowerDisplacement:DataAvailable','Update was called for %s when no raw data is available.\nPerhapse call DTDD.ReadFile().\n',DTDD.GetSpecimen().GetSpecimenName());
            end
            
            % filter the data
            DTDD.CalcFilteredData();
        end
        
        function PrintSelf(DTDD)
            % A function to print the current state of the displacement
            % data object
            %
            % DTDD.PrintSelf()
            %
            fprintf(1,'\n%%%%%%%%%% DTDisplacementData Class Parameters %%%%%%%%%%\n');
            DTDD.GetSpecimen().PrintSelf();
            fprintf(1,'\n %%%% Scalar Inputs %%%%\n');
            fprintf(1,'File name: %s\n',DTDD.GetFileName());
            fprintf(1,'Time of first data point in experiment time: %f seconds\n',DTDD.GetTimeStart());
            fprintf(1,'Sample rate: %f Hz\n',DTDD.GetSampleRate());
            fprintf(1,'Filterind cutoff: %f Hz\n',DTDD.GetFilterCutoff());
            fprintf(1,'Filter order: %d\n',DTDD.GetFilterOrder());
            
            fprintf(1,'\n %%%% Vector Outputs %%%%\n');
            fprintf(1,'Time in displacement time frame: [%d,%d] seconds\n',size(DTDD.GetTimeDisplacement()));
            fprintf(1,'Time in experimental time frame: [%d,%d] seconds\n',size(DTDD.GetTime()));
            fprintf(1,'Filtered displacement of the trochanter: [%d,%d] m\n',size(DTDD.GetDisplacementTroch()));
            fprintf(1,'Raw displacement of the trochanter: [%d,%d] m\n',size(DTDD.GetDisplacementTrochUnfiltered()));
            fprintf(1,'Filtered displacement of the hammer: [%d,%d] m\n',size(DTDD.GetDisplacementHammer()));
            fprintf(1,'Raw displacement of the hammer: [%d,%d] m\n',size(DTDD.GetDisplacementHammerUnfiltered()));
        end
            
            
        
    end % public methods
    
    methods (Access = private, Hidden = true)
        
        function CalcFilteredData(DTDD)
            % A function to calculate the filtered data.
            %
            % DTDD.CalcFilteredData()
            %
            if (isempty(DTDD.m_sampleRate) || isempty(DTDD.m_filterCutoff) || isempty(DTDD.m_filterOrder) )
                error('DropTowerDisplacement:DataAvailability','Filtering was requested for %s when either sample rate, filter cutoff or filter order had not been set.\n',DTDD.GetSpecimen().GetSpecimenName());
            end
            cutoffNormal = DTDD.m_filterCutoff / DTDD.m_sampleRate;
            [b,a] = butter(DTDD.m_filterOrder/2,cutoffNormal); % divide filter order by two since filtfilt doubles the order
            
            troch = filtfilt(b,a,DTDD.GetDisplacementTrochUnfiltered());
            hammer = filtfilt(b,a,DTDD.GetDisplacementHammerUnfiltered());
            
            % zero the data at the start
            troch(:,1) = troch(:,1) - troch(1,1);
            troch(:,2) = troch(:,2) - troch(1,2);
            hammer(:,1) = hammer(:,1) - hammer(1,1);
            hammer(:,2) = hammer(:,2) - hammer(1,2);
            DTDD.m_displacementTrochFilt = troch;
            DTDD.m_displacementHammerFilt = hammer;
            
        end

    end % private methods
end % classdef
    
