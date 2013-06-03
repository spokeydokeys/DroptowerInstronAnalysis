classdef DICData < handle
    properties (SetAccess = private, Hidden = false)
        m_specimen      % the specimen data class    
    end
    
    properties (SetAccess = private, Hidden = true)
        m_dicData           % strain
        m_dicTime           % seconds
        m_dicStartTime      % seconds
        m_dicSampleRate     % Hz
        m_dicDataFile = ''; % string
    end
    methods
        % Constructor function
        function DD = DICData(specimen)
            % Constructor requires a reference specimen. See Specimen.m
            % for details on creating a specimen.
            %
            % DD = DICData(specimen)
            %
            DD.m_specimen = specimen;
        end
        
        function SetFileName(DD,fileName)
            % A function to set the name of the DIC data file.
            %
            % DD.SetFileName(file)
            %
            while (~exist(fileName,'file'))
                fprintf(1,'The specified DIC data file does not exist for specimen %s\n',DD.GetSpecimen.GetSpecimenName);
                fileName = input('Please enter a valid file location: ');
            end                
            DD.m_dicDataFile = fileName;
        end
        function o = GetFileName(DD)
            % A function to get the name of the DIC data file
            %
            % File = DD.GetFileName()
            %
            o = DD.m_dicDataFile;
        end
        
        function SetStartTime(DD,startTime)
            % A function to set the time of the first data point in the
            % DIC data in seconds. Time in the input file starts from
            % zero, in some cases this my not be coincident with the
            % trigger. This value is used to align the data with the
            % experiment time.
            %
            % DD.SetStartTime(time)
            %
             DD.m_dicStartTime = startTime; % must be supplied by user
        end
        
        function SetSampleRate(DD,rate)
            % A function to set the data frequency of the DIC in Hz.
            %
            % DD.SetSampleRate(rate)
            %
            DD.m_dicSampleRate = rate;
        end
        function o = GetSampleRate(DD)
            % A function to get the sample rate of the DIC data in Hz.
            %
            % Rate = DD.GetSampleRate()
            %
            o = DD.m_dicSampleRate;
        end
        
        function o = GetSpecimen(DD)
            % A function to return the specimen object associated with 
            % the DIC data.
            %
            % Specimen = DD.GetSpecimen()
            %
            o = DD.m_specimen;
        end

        function o = GetStrainData(DD)
            % A function to get the DIC strain data vector read in from
            % the input file. In the same units provided in the input
            % file. Should be percent minimum principal strain.
            %
            % Strain = DD.GetStrainData()
            %
            o =  DD.m_dicData;
        end
        
        function o = GetDICTime(DD)
            % A function to get the DIC time in seconds. This time may
            % not be aligned with the experiment time. The offset is
            % set/get using DD.SetStartTime(time) and DD.GetTimeStart()
            %
            % Time = DD.GetDICTime()
            %
            o = DD.m_dicTime;
        end
        
        function o = GetTime(DD)
            % A function to get the DIC time in seconds, aligned with the
            % experimental time. If the DIC start time has not been set
            % using SetStartTime(time) a warning will be issued.
            %
            % Time = DD.GetTime()
            %
            if isempty(DD.m_dicStartTime)
                warning('DICData:DataAvailable','Warning! There is no start time for the DIC.\nTime will not be referenced to the rest of the experiment.\n');
            end
            o = DD.m_dicTime + DD.m_dicStartTime;
        end
            
        function o = GetTimeStart(DD)
            % A function to get the time of the first DIC data point in
            % seconds.
            %
            % Time = DD.GetTimeStart()
            %
            o = DD.m_dicStartTime;
        end
        
        function ReadFile(DD)
            % A function to read the DaVis strain output file. 
            % Strain must be percent minimum principal strain for this 
            % class to integrate properly with the rest of the analysis
            %
            % DD.ReadDataFile()
            %
            if strcmp(DD.GetFileName(),'')
                error('DICData:DataAvailable','The DIC ReadDataFile() method was called for % before a file name was set.\n',DD.GetSpecimen().GetSpcimenName());
            end
            inFid = fopen(DD.m_dicDataFile,'r');
            if inFid == -1
                fclose(inFid);
                error('DICData:ReadError','The DIC data file specified for %s does not exist. Please check the file name and try again.\n',DD.GetSpecimen().GetSpcimenName());
            end
            fgetl(inFid);           % skip headerline
            cline = fgetl(inFid);           % read in the y axis
            %#ok<*ST2NM>  - Suppress the strin to num warning
            DD.m_dicData = str2num(cline)/100;  % convert to number and make % into strain
            cline = fgetl(inFid);           % read in the x axis
            DD.m_dicTime = str2num(cline);  % convert to number
            fclose(inFid);
        end
        
        function o = GetStrainAtTime(DD,time)
            % A function to get the strain at a experimental time in seconds.
            %
            % Strain = DD.GetStrainAtTime(time)
            %
            dicTime = time - DD.m_dicStartTime;
            index = find(DD.m_dicTime > dicTime,1,'first');
            o = DD.m_dicData(index);
        end
        
        function PrintSelf(DD)
            % A function to print out the state of the DIC data object.
            %
            % DD.PrintSelf()
            %
            fprintf(1,'\n%%%%%%%%%% DICData Class Parameters %%%%%%%%%%\n');
            DD.GetSpecimen().PrintSelf();
            fprintf(1,'DIC file name: %sf\n',DD.m_dicDataFile);
            fprintf(1,'DIC sample rate: %f Hz\n',DD.m_dicSampleRate);
            fprintf(1,'DIC start time: %f seconds\n',DD.m_dicStartTime);
            
            fprintf(1,'\n  %%%% DIC Data %%%%  \n');
            fprintf(1,'DIC strain: [%d,%d] in percent strain (or as defined in input file)\n',size(DD.m_dicData));
            fprintf(1,'DIC time: [%d,%d] in seconds\n\n',size(DD.m_dicTime));
        end
            
    end
end
    
