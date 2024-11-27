function Yuan_RestingState_4d(DataDir,Mean4Dfile,Postfix,MaskFilename)
% FORMAT y_RegressOutImgCovariates(DataDir,CovariablesDef,Postfix,MaskFilename, ImgCovModel)
% Input:
%   DataDir        - where the 3d+time dataset stay, and there should be 3d EPI functional image files. It must not contain / or \ at the end.
%   Mean4Dfile     - the 4d LOO_TC mean data.
%   Postfix        - Post fix of the resulting data directory. e.g. '_Covremoved'
%   MaskFilename   - The mask file for regression. Empty means perform regression on all the brain voxels.
%   ImgCovModel    - The model for the image covariates defined in CovariablesDef.CovImgDir. E.g., used for the voxel-specific 12 head motion regression model
%                     1 (default): Use the current time point. e.g., Txi, Tyi, Tzi
%                     2: Use the current time point and the previous time point. e.g., Txi, Tyi, Tzi, Txi-1, Tyi-1, Tzi-1
%                     3: Use the current time point and their squares. e.g., Txi, Tyi, Tzi, Txi^2, Tyi^2, Tzi^2
%                     4: Use the current time point, the previous time point and their squares. e.g., Txi, Tyi, Tzi, Txi-1, Tyi-1, Tzi-1 and their squares (total 12 items). Like the Friston autoregressive model (Friston, K.J., Williams, S., Howard, R., Frackowiak, R.S., Turner, R., 1996. Movement-related effects in fMRI time-series. Magn Reson Med 35, 346-355.)
% Output:
%   theCovariables - The covariables used in the regression model.
%   *.nii - data removed the effect of covariables.
%___________________________________________________________________________
% Written by YAN Chao-Gan 111209.
% The Nathan Kline Institute for Psychiatric Research, 140 Old Orangeburg Road, Orangeburg, NY 10962, USA
% Child Mind Institute, 445 Park Avenue, New York, NY 10022, USA
% The Phyllis Green and Randolph Cowen Institute for Pediatric Neuroscience, New York University Child Study Center, New York, NY 10016, USA
% ycg.yan@gmail.com
%   Revised by YAN Chao-Gan 160415: Add the option of "Add Mean Back".

% [AllVolume,VoxelSize,theImgFileList, Header] =y_ReadAll(DataDir);
cd(DataDir)
nii4dfile=dir('*.nii');
[AllVolume,Header]=y_Read(nii4dfile.name);
[nDim1,nDim2,nDim3,nDim4]=size(AllVolume);


[CovTempVolume] =y_Read(Mean4Dfile);
Cov5DVolume(:,:,:,:,1) = CovTempVolume;

if ~isempty(MaskFilename)
    [MaskData,MaskVox,MaskHead]=y_ReadRPI(MaskFilename);
else
    MaskData=ones(nDim1,nDim2,nDim3);
end


MaskData = any(AllVolume, 4) .* MaskData; % skip the voxels with all zeros

% VolumeAfterRemoveCov=zeros(nDim1,nDim2,nDim3,nDim4);
restingState=zeros(nDim1,nDim2,nDim3,nDim4);
MeanBrain=zeros(nDim1,nDim2,nDim3);

fprintf('\n\tRegressing Out Covariates...\n');
for i=1:nDim1
    fprintf('.');
    for j=1:nDim2
        for k=1:nDim3
            if MaskData(i,j,k) && sum(squeeze(Cov5DVolume(i,j,k,:)))
                DependentVariable=squeeze(AllVolume(i,j,k,:));
                ImgCovTemp = squeeze(Cov5DVolume(i,j,k,:));
                ImgCovTemp = (ImgCovTemp-repmat(mean(ImgCovTemp), size(ImgCovTemp,1), 1));%%Demean.
                ImgCovTemp=[ones(size(ImgCovTemp,1),1), ImgCovTemp];
                [b,r] = y_regress_ss(DependentVariable, ImgCovTemp);
%                 VolumeAfterRemoveCov(i,j,k,:)=DependentVariable-r;
                restingState(i,j,k,:) = r;
                MeanBrain(i,j,k)=b(1);
            end
        end
    end
end

% VolumeAfterRemoveCov(isnan(VolumeAfterRemoveCov))=0;

restingState(isnan(restingState))=0;

% VolumeAfterRemoveCov = VolumeAfterRemoveCov + repmat(MeanBrain,[1,1,1,nDim4]); %%Add the mean back.
restingState = restingState + repmat(MeanBrain,[1,1,1,nDim4]); %%Add the mean back.

% OutputDir =sprintf('%s%s',DataDir,Postfix);
% ans=rmdir(OutputDir, 's');
% [theParentDir,theOutputDirName]=fileparts(OutputDir);

mkdir([DataDir filesep 'LOO_ResReg' filesep Postfix]);

Header_Out = Header;
Header_Out.pinfo = [1;0;0];
Header_Out.dt    =[16,0];
y_Write(restingState,Header_Out, [DataDir filesep 'LOO_ResReg' filesep Postfix filesep 'restingState_4DVolume.nii']);
% y_Write(VolumeAfterRemoveCov,Header_Out,[DataDir filesep 'LOO_ResReg' filesep Postfix filesep 'restingState_4DVolume.nii']);

fprintf('\n\tRegressing Out Covariates finished.\n');

