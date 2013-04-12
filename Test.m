% A script to test functionality
clc
clear all
close all

name = 'H1376L';
dxa = struct('neck',0.552,'troch',.550,'inter',.812,'total',.683,'wards',.333);
op = 'osteopenia';
data = struct('InstronDAQ',1,'InstronDIC',1,'DropTowerDAQ',1,'DropTowerDisplacement',1,'DropTowerDIC',1);

% Create the data class
testInstronClass = InstronAnalysis(name,dxa,op,data);

%%  DAQ

% read in the DAQ data file
testInstronClass.GetDAQDataClass.SetFileName('/media/BigToaster/Seth Project Data/12-018 Testing!/H1376L/SignalAsciiData/Ins_H1376L.csv')
testInstronClass.GetDAQDataClass.ReadFile();

% setup the DAQ parameters
testInstronClass.GetDAQDataClass.SetSampleRate(20000);
testInstronClass.GetDAQDataClass.SetFilterCutoff(500);
testInstronClass.GetDAQDataClass.SetGainDisplacement(.3);
testInstronClass.GetDAQDataClass.SetGainLoad(1000);

% apply gains to the load and displacement data
testInstronClass.GetDAQDataClass.ApplyGainDisplacement();
testInstronClass.GetDAQDataClass.ApplyGainLoad();

% filter the data and set time to start at trigger
testInstronClass.GetDAQDataClass.CalcFilteredData();
testInstronClass.GetDAQDataClass.CalcPrincipalStrains();
testInstronClass.GetDAQDataClass.ZeroTimeAtTrigger();

% print the class
testInstronClass.GetDAQDataClass.PrintSelf();


%%  DIC 

% read in the DIC data file
testInstronClass.GetDICDataClass.SetFileName('/media/BigToaster/Seth Project Data/12-018 Testing!/H1376L/InsDIC/MinPStrain_accurate/B00001.txt')
testInstronClass.GetDICDataClass.ReadDataFile();

% setup the DIC paramters
testInstronClass.GetDICDataClass.SetSampleRate(100)
testInstronClass.GetDICDataClass.SetStartTime(0.2)

testInstronClass.AnalyzeInstronData();



