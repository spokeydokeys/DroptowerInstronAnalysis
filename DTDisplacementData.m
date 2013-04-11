classdef DTDisplacementData < Specimen
    properties (SetAccess = private)
        m_displacementTroch;    % displacement of the trochanter
        m_displacementHammer;   % displacement of the impact hammer
        m_displacementTrochFilt;    % displacement of the trochanter, filtered
        m_displacementHammerFilt;   % displacement of the hammer, filtered
        m_timeDisplacement;     % time of the values in displacement camera time
        m_timeStart;            % time of the first data point, experiment time
        m_sampleRate;           % camera sample rate in Hz
        m_filterCutoff;         % filter cutoff frequency in Hz
        m_filterOrder;          % butterworth filter order. Must be even, odd orders will be increased by 1
        m_fileName;             % the raw TEMA data file
    end % properties
    
    methods
        % Constructor
        function DTDD = DTDisplacementData(name,dxa,op,data)
            DTDD@Specimen(name,dxa,op,data);
            DTDD.m_filterOrder = 2;   % default to second order filter
        end
        
        % a function to set the file name
        function SetFileName(DTDD,file)
            if file ~= DTDD.m_fileName
                if ~exists(file,'file')
                    error('DropTowerDisplacement:DataAvailability','The specified displacement file for %s does not exist.\n',DTDD.m_specimenName);
                end
                DTDD.m_fileName = file;
            end
        end
        function o = GetFileName(DTDD)
            o = DTDD.m_fileName;
        end
        
        % functions to set and get the start time
        function SetTimeStart(DTDD,time)
            if DTDD.m_timeStart ~= time
                DTDD.m_timeStart = time;
            end
        end
        function o = GetTimeStart(DTDD)
            o = DTDD.m_timeStart;
        end
        
        % functions to set and get the sample rate
        function SetSampleRate(DTDD,rate)
            if DTDD.m_sampleRate ~= rate
                DTDD.m_sampleRate = rate;
            end
        end
        function o = GetSampleRate(DTDD)
            o = DTDD.m_sampleRate;
        end
        
        function ReadFile(DTDD)
            if isempty(DTDD.m_fileName)
                error('DropTowerDisplacement:DataAvailability','File read was called for %s when no file name has been set.\n',DTDD.m_specimenName);
            end
            % read the file
            data = importdata(DTDD.m_fileName,'\t');
            % find the shortest data filed
            validData = ~isnan(data.data);
            startIndex = max(find(validData(:,1),1,'first'),find(validData(:,2),1,'first'),find(validData(:,3),1,'first'),find(validData(:,4),1,'first'),find(validData(:,5),1,'first'));
            endIndex = min(  find(validData(:,1),1,'last'), find(validData(:,2),1,'last'), find(validData(:,3),1,'last'), find(validData(:,4),1,'last'), find(validData(:,6),1,'last') );                
            
            % import the time data
            DTDD.m_timeDisplacement = data.data(startIndex:endIndex,1);
            % import the impact hammer data
            DTDD.m_displacementHammer = [data.data(startIndex:endIndex,2), data.data(startIndex:endIndex,3) ];
            DTDD.m_displacementTroch = [data.data(startIndex:endIndex,4), data.data(startIndex:endIndex,5) ];
        end
        
        % functions to get the unfiltered data
        function o = GetDisplacementTrochUnfilterd(DTDD)
            o = DTDD.m_displacementTroch;
        end
        function o = GetDisplacementHammerUnfiltered(DTDD)
            o = DTDD.m_displacementHammer;
        end
        
        % functions to set get filter cutoff frequency
        function SetFilterCutoff(DTDD,rate)
            if DTDD.m_filterCutoff ~= rate
                DTDD.m_filterCutoff = rate;
            end
        end
        function o = GEtFilterCutoff(DTDD)
            o = DTDD.m_filterCutoff;
        end
        
        % functions to set get the filter order
        function SetFilterOrder(DTDD,order)
             if mod(order, 2)
                warning('DropTowerDisplacement:DataValues','The filter order for %s was set to an odd number. Only even orders are accepted. The order is being increased by one.\n',DTDD.m_specimenName);
                order = order +1;
            end
            DTDD.m_filterOrder = order;
        end
        function o = GetFilterOrder(DTDD)
            o = DTDD.m_filterOrder;
        end
                
        function CalcFilteredData(DTDD)
            if (isempty(DTDD.m_sampleRate) || isempty(DTDD.m_filterCutoff) || isempty(DTDD.m_filterOrder) )
                error('DropTowerDisplacement:DataAvailability','Filtering was requested for %s when either sample rate, filter cutoff or filter order had not been set.\n',DTDD.m_specimenName);
            end
            cutoffNormal = DTDD.m_filterCutoff / DTDD.m_sampleRate;
            [b,a] = butter(DTDD.m_filterOrder/2,cutoffNormal); % divide filter order by two since filtfilt doubles the order
            
            DTDD.m_displacementTrochFilt = filtfilt(b,a,DTDD.m_displacementTroch);
            DTDD.m_displacementHammerFilt = filtfilt(b,a,DTDD.m_displacementHammer);
        end
        
        % functions to get the (filtered) data
        function o = GetDisplacementTroch(DTDD)
            if isempty(DTDD.m_displacementTrochFilt)
                if isempty(DTDD.m_displacementTroch)
                    error('DropTowerDisplacement:DataAvailability','Trochanter displacement was requested for %s before displacement data was available.\n',DTDD.m_specimenName);
                end
                DTDD.CalcFilteredData();
            end
            o = DTDD.m_displacementTrochFilt;
        end
        function o = GetDisplacementHammer(DTDD)
            if isempty(DTDD.m_displacementTrochFilt)
                if isempty(DTDD.m_displacementTroch)
                    error('DropTowerDisplacement:DataAvailability','Hammer displacement was requested for %s before displacement data was available.\n',DTDD.m_specimenName);
                end
                DTDD.CalcFilteredData();
            end            
            o = DTDD.m_displacementHammerFilt;
        end
        
        % function to get the time in displacement camera time
        function o = GetTimeDisplacement(DTDD)
            o = DTDD.m_timeDisplacement;
        end
        
        % function to get the time in experiment time
        function o = GetTime(DTDD)
            if isempty(DTDD.m_startTime)
                warning('DropTowerDisplacement:DataAvailability','Time was requested for %s before start time was supplied. The time will not be referenced to the experiment.\n',DTDD.m_specimenName);
            end
            o = DTDD.m_timeDisplacement - DTDD.m_startTime;
        end
    end % methods
end % classdef
    
