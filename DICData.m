classdef DICData < Specimen
    properties (SetAccess = private)
        m_dicData           % percent strain
        m_dicTime           % seconds
        m_dicStartTime      % seconds
        m_dicSampleRate     % Hz
        m_dicDataFile       % string
    end
    methods
        % Constructor function
        function DD = DICData(name,dxa,op,data)
            DD = DD@Specimen(name,dxa,op,data);
        end
        
        function SetFileName(DD,fileName)
            while (~exist(fileName,'file'))
                sprintf('The specified DIC data file does not exist\n');
                fileName = input('Please enter a valid file location: ');
            end                
            DD.m_dicDataFile = fileName;
        end
        function o = GetFileName(DD)
            o = DD.m_dicDataFile;
        end
        
        function SetStartTime(DD,startTime)
             DD.m_dicStartTime = startTime; % must be supplied by user
        end
        
        function SetSampleRate(DD,rate)
            DD.m_dicSampleRate = rate;
        end
        function o = GetSampleRate(DD)
            o = DD.m_dicSampleRate;
        end
        
        % functions to get the data vector
        function o = GetStrainData(DD)
            o =  DD.m_dicData;
        end
        
        % functions to get the time post m_dicStartTime
        function o = GetDICTime(DD)
            o = DD.m_dicTime;
        end
        
        % a function to get the DIC time in the experiment time
        function o = GetTime(DD)
            if isempty(DD.m_dicStartTime)
                userInput = input('Warning! There is no start time for the DIC.\nTime will not be referenced to the rest of the experiment.\nPress enter to continue or Ctrl+c to stop execution.\n');
            end
            o = DD.m_dicTime + DD.m_dicStartTime;
        end
            
        % functions to get the experiment time of the start of the DIC data.
        function o = GetStartTime(DD)
            o = DD.m_dicStartTime;
        end
        
        function ReadDataFile(DD)
            inFid = fopen(DD.m_dicDataFile,'r');
            cline = fgetl(inFid);           % skip headerline
            cline = fgetl(inFid);           % read in the y axis
            DD.m_dicData = str2num(cline);  % convert to number
            cline = fgetl(inFid);           % read in the x axis
            DD.m_dicTime = str2num(cline);  % convert to number
            fclose(inFid);
        end
        
        % function to get the strain at a certain experiment time
        function o = GetStrainAtTime(DD,time)
            dicTime = time - DD.m_dicStartTime;
            index = find(DD.m_dicTime > dicTime,1,'first');
            o = DD.m_dicData(index);
        end
    end
end
    
