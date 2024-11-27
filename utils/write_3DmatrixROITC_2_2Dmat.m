function write_3DmatrixROITC_2_2Dmat(ROI_TC, saveDir, sublist, postfix)
%write_3DmatrixROITC_2_2Dmat can save 3D ROI_TC(nT * nR * nSub) matrix as nSub 2D (nT * nR)
%.mat file
% 
%Input:
% ROI_TC      - Data of 3D matrix(nT * nR * nSub) to write
% saveDir     - path to save the 2D result
% sublist     - a struct(nSub * 1), whose 'name' field serves as the part of name
% of the 2D result file.
% postfix     - a string that will serve as a suffix to the file name
% e.g. if postfix ='raw', the 2D result will be sub001_raw.mat, sub002_raw.mat...

nSub = size(ROI_TC, 3);
if ~exist(saveDir)
    mkdir(saveDir)
end
for i = 1:nSub
    temp = squeeze(ROI_TC(:,:,i));
    [~, name, ~] = fileparts(sublist(i).name);

    saveName = fullfile(saveDir, [name '_' postfix '.mat']);
    save(saveName, "temp", "-V7.3")
end