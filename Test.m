% A script to test functionality
clc
clear all
close all


name = 'H1376L';
dxa = struct('neck',0.552,'troch',.550,'inter',.812,'total',.683,'wards',.333);
op = 'osteopenia';
data = [1 1 1 1 1];

% Create the data class
testInstronClass = InstronAnalysis(name,dxa,op,data);
% read in the DAQ data file
testInstronClass.SetFileNameDAQ('/media/BigToaster/Seth Project Data/12-018 Testing!/H1376L/SignalAsciiData/Ins_H1376L_Processed_filtfilt.mat')
testInstronClass.ReadDAQFile
% read in the DIC data file
testInstronClass.GetDICDataClass.SetFileName('/media/BigToaster/Seth Project Data/12-018 Testing!/H1376L/InsDIC/MinPStrain_accurate/B00001.txt')
testInstronClass.GetDICDataClass.ReadDataFile

% setup the machine parameters
testInstronClass.SetInstronCompliance(1/30000);

% setup the DIC paramters
testInstronClass.GetDICDataClass.SetSampleRate(100)
testInstronClass.GetDICDataClass.SetStartTime(0.2)

testInstronClass.AnalyzeInstronData

% 
% % correct the time to zero when the trigger is detected
% testInstronClass.ZeroDAQTimeAtTrigger
% 
% % interpolate the data to a common time
% testInstronClass.InterpolateDAQToCommonTime
% 
% % compute the stiffness
% testInstronClass.CalcStiffness
% % compute the energy
% testInstronClass.CalcEnergy
% % compute the
% 
% % compute the strains
% testInstronClass.CalcStrainAtMaxGauge

