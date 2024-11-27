function [ROI_TC] = read_2Dmat_2_3DmatrixROITC(inputdir)
%read_2Dmat_2_3DmatrixROITC can read nSub 2D (nT * nR) .mat or .txt file
% and convert them as a 3D ROI_TC(nT * nR * nSub) matrix  
%
% 
%Input:
% inputdir      - Path of nSubjects' 2D mat/txt file(nT * nR)
% 
%Output:
% ROI_TC        - Data of 3D matrix(nT * nR * nSub)

ROI_TC = [];
cd(inputdir)
fileList = dir('*.mat');

if size(fileList, 1) == 0
    fileList = dir('*.txt');
    if size(fileList, 1) == 0
        error("There is no .mat or .txt file in inputdir")
    end
end

for i = 1:size(fileList, 1)
    data = importdata(fileList(i).name);
    ROI_TC(:, :, i) = data;
end