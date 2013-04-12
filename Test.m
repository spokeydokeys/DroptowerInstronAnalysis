% A script to test functionality
clc
clear all
close all

% read the specimen data table
specimenFileName = 'Specimen.csv';
specimenFID = fopen(specimenFileName,'r');
specimenData = textscan(specimenFID,'%s %s %f %f %f %f %f %f %f %f %s %d %d %d %d %d','headerlines',1,'delimiter',',');
fclose(specimenFID);

wantedName= 'H1167L';
wantedIndex = find(strcmp(specimenData{1},wantedName));

name = specimenData{1}{wantedIndex};
gender = specimenData{2}{wantedIndex};
age = specimenData{3}(wantedIndex);
height = specimenData{4}(wantedIndex);
weight = specimenData{5}(wantedIndex);
dxa = struct('neck',specimenData{6}(wantedIndex),'troch',specimenData{7}(wantedIndex),'inter',specimenData{8}(wantedIndex),'total',specimenData{9}(wantedIndex),'wards',specimenData{10}(wantedIndex));
op = specimenData{11}{wantedIndex};
data = struct('InstronDAQ',specimenData{12}(wantedIndex),'InstronDIC',0,'DropTowerDAQ',specimenData{14}(wantedIndex),'DropTowerDisplacement',specimenData{15}(wantedIndex),'DropTowerDIC',specimenData{16}(wantedIndex));

specimen = Specimen(name,gender,age,height,weight,dxa,op,data);

% Create the data class
instronAnalysis = InstronAnalysis(specimen);

%%  DAQ - these are the parameters which must be set for the DAQ analysis


% read in the instronDAQ data table
instronDAQFileName = 'InstronDAQ.csv';
instronDAQFID = fopen(instronDAQFileName,'r');
instronDAQData = textscan(instronDAQFID,'%s %f %f %f %f %s','headerlines',1,'delimiter',',');
fclose(instronDAQFID);

if data.InstronDAQ
    % read in the DAQ data file
    instronAnalysis.GetDAQData.SetFileName(instronDAQData{6}{wantedIndex});
    instronAnalysis.GetDAQData.ReadFile();

    % setup the DAQ parameters
    instronAnalysis.GetDAQData.SetSampleRate(instronDAQData{2}(wantedIndex));
    instronAnalysis.GetDAQData.SetFilterCutoff(instronDAQData{3}(wantedIndex));
    instronAnalysis.GetDAQData.SetGainDisplacement(instronDAQData{4}(wantedIndex));
    instronAnalysis.GetDAQData.SetGainLoad(instronDAQData{5}(wantedIndex));
end

%%  DIC - these are the parameters which must be set for the DIC analysis

% read in the instronDIC data file
instronDICFileName = 'InstronDIC.csv';
instronDICFID = fopen(instronDICFileName,'r');
instronDICData = textscan(instronDICFID,'%s %f %f %s','headerlines',1,'delimiter',',');
fclose(instronDICFID);

if data.InstronDIC
    % read in the DIC data file
    instronAnalysis.GetDICData.SetFileName('/media/BigToaster/Seth Project Data/12-018 Testing!/H1376L/InsDIC/MinPStrain_accurate/B00001.txt')
    instronAnalysis.GetDICData.ReadDataFile();

    % setup the DIC paramters
    instronAnalysis.GetDICData.SetSampleRate(100)
    instronAnalysis.GetDICData.SetStartTime(0.2)
end

%% Analyze the data

instronAnalysis.AnalyzeInstronData();

%% print the class
instronAnalysis.PrintSelf();

