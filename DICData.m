classdef DICData < handle
    properties (SetAccess = private)
        m_dicData           % strain
        m_dicTime           % seconds
        m_dicStartTime      % seconds
        m_dicSampleRate     % Hz
        m_dicDataFile       % string
        m_specimenData      % the specimen data class
    end
    methods
        % Constructor function
        function DD = DICData(specimen)
            DD.m_specimenData = specimen;
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
        
        function o = GetSpecimen(DD)
            o = DD.m_specimenData;
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
                warning('DICData:DataAvailable','Warning! There is no start time for the DIC.\nTime will not be referenced to the rest of the experiment.\n');
            end
            o = DD.m_dicTime + DD.m_dicStartTime;
        end
            
        % functions to get the experiment time of the start of the DIC data.
        function o = GetStartTime(DD)
            o = DD.m_dicStartTime;
        end
        
        function ReadDataFile(DD)
            % A function to read the DaVis strain output file. 
            % Strain must be percent minimum principal strain for this 
            % class to integrate properly with the rest of the analysis
            %
            % set the file name using DICData.SetFileName(file)
            %
            %
            inFid = fopen(DD.m_dicDataFile,'r');
            cline = fgetl(inFid);           % skip headerline
            cline = fgetl(inFid);           % read in the y axis
            DD.m_dicData = str2num(cline)/100;  % convert to number and make % into strain
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
        
        % function to print out the state of the class
        function PrintSelf(DD)
            fprintf(1,'\n%%%%%%%%%% DICData Class Parameters %%%%%%%%%%\n');
            DD.GetSpecimen().PrintSelf();
            fprintf(1,'DIC file name: sf\n',DD.m_dicDataFile);
            fprintf(1,'DIC sample rate: %f Hz\n',DD.m_dicSampleRate);
            fprintf(1,'DIC start time: %f seconds\n',DD.m_dicStartTime);
            
            fprintf(1,'\n  %%%% DIC Data %%%%  \n');
            fprintf(1,'DIC strain: [%d,%d] in percent strain (or as defined in input file)\n',size(DD.m_dicData));
            fprintf(1,'DIC time: [%d,%d] in seconds\n\n',size(DD.m_dicTime));
        end
            
    end
end
    
