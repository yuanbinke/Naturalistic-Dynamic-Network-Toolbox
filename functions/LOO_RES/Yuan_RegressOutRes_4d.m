function Yuan_RegressOutRes_4d(DataDir, Mean4Dfile, dataType, MaskFilename)
% FORMAT Yuan_RegressOutRes_4d(DataDir,Mean4Dfile,Postfix,MaskFilename)
% Input:
%   DataDir        - inputdir is the directory which  contains all the subject data
%   Mean4Dfile - the 3d+time mean data.
%   dataType       - dataType indicate which type of signal you want to acquire
%                     it have three options('resting', 'task','all')
%   MaskFilename   - The mask file for regression. Empty means perform regression on all the brain voxels.
%
% Output: 
%   The result will finally be saved in 'DataDir \ LOO_ResReg'


cd(DataDir)
nii4dfile = dir('*.nii');
[AllVolume, Header] = yjj_Read(nii4dfile.name);
[nDim1, nDim2, nDim3, nDim4]=size(AllVolume);


[CovTempVolume, ~] = yjj_Read(Mean4Dfile);
Cov5DVolume(:,:,:,:,1) = CovTempVolume;

if ~isempty(MaskFilename)
%     [MaskData, ~] = y_ReadRPI(MaskFilename);
    [MaskData, ~] = yjj_Read(MaskFilename);
else
    MaskData=ones(nDim1,nDim2,nDim3);
end


MaskData = any(AllVolume,4) .* MaskData; % skip the voxels with all zeros

VolumeAfterRemoveCov = zeros(nDim1, nDim2, nDim3, nDim4);
VolumeResting = zeros(nDim1, nDim2, nDim3, nDim4);

MeanBrain = zeros(nDim1, nDim2, nDim3);

fprintf('\n\tRegressing Out Covariates...\n');
for i=1:nDim1
    fprintf('.');
    for j=1:nDim2
        for k=1:nDim3
            if MaskData(i,j,k) && sum(squeeze(Cov5DVolume(i,j,k,:)))
                DependentVariable=squeeze(AllVolume(i,j,k,:));
                ImgCovTemp = squeeze(Cov5DVolume(i,j,k,:));
                ImgCovTemp = (ImgCovTemp - repmat(mean(ImgCovTemp),size(ImgCovTemp,1),1));%%Demean.
                ImgCovTemp=[ones(size(ImgCovTemp,1),1),ImgCovTemp];
                [b,r] = y_regress_ss(DependentVariable,ImgCovTemp);
                VolumeAfterRemoveCov(i,j,k,:)=DependentVariable-r;
                VolumeResting(i,j,k,:) = r;
                MeanBrain(i,j,k)=b(1);
            end
        end
    end
end

VolumeAfterRemoveCov(isnan(VolumeAfterRemoveCov))=0;
VolumeResting(isnan(VolumeResting))=0;


% VolumeAfterRemoveCov = VolumeAfterRemoveCov + repmat(MeanBrain,[1,1,1,nDim4]); %%Add the mean back.
% VolumeResting = VolumeResting + repmat(MeanBrain,[1,1,1,nDim4]); %%Add the mean back.

taskSaveDir = [DataDir filesep 'LOO_ResReg' filesep 'Task'];
restingSaveDir = [DataDir filesep 'LOO_ResReg' filesep 'Resting'];

mkdir(taskSaveDir);
mkdir(restingSaveDir);



if strcmp(dataType, 'resting') || strcmp(dataType, 'all')
    yjj_Write(VolumeResting, [restingSaveDir filesep 'ResRegressed_Resting_4DVolume.nii'], Header);
end
if strcmp(dataType, 'task') || strcmp(dataType, 'all')
    yjj_Write(VolumeAfterRemoveCov, [taskSaveDir filesep 'ResRegressed_Task_4DVolume.nii'], Header);
end

fprintf('\n\tRegressing Out Covariates finished.\n');

