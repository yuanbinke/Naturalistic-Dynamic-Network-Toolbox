function [flag,errorsub] = computeISC(inputdir, prefix, grayMatterMask, savedDir, app)
% FORMAT: [flag, errorsub] = computeISC(inputdir, prefix, grayMatterMask, savedDir, app)
% computeISC computes the Intersubject Correlation (ISC) for n (n >= 2) subjects.
%
% INPUT:
%   inputdir        - A directory containing all subject data. Each subject's 
%                     data is stored in a separate subdirectory. The expected 
%                     structure is:
%                     - sub001/func/data_sub001.nii(.gz), recommended or
%                     - sub001/data_sub001.nii(.gz).
%
%   prefix          - A string used to identify the target subdirectories 
%                     or files within the inputdir. For example, if the 
%                     subject directories are named 'sub001', 'sub002', etc., 
%                     the prefix could be 'sub'.
%
%   grayMatterMask  - The file path to a gray matter mask file. This mask is 
%                     used to extract time course data from the gray matter 
%                     region of the functional images.
%
%   savedDir        - (Optional) The directory path where the ISC results 
%                     will be saved. If not provided, the default path is 
%                     [inputdir filesep 'ISC-Result'].
%
%   app             - (Optional) A UI object (e.g., a progress bar or 
%                     message display) for providing feedback during the 
%                     execution of the function.
%
% OUTPUT:
%   The results of the ISC computation are saved in the specified savedDir.
%
%   flag            - A status flag indicating the outcome of the function:
%                     - -1: Indicates that the subject (specified by errorsub) 
%                           has no .nii or .nii.gz file.
%                     -  0: Indicates that the provided prefix is incorrect 
%                           (no matching subdirectories or files were found).
%                     -  1: Indicates that the function completed successfully.
%
%   errorsub        - The index of the subject that has no .nii or .nii.gz 
%                     file. If no errors are found, this value is set to 0.

if nargin == 3
    savedDir = fullfile(inputdir, 'ISC-Result');
end
if ~exist(savedDir,"dir")
    mkdir(savedDir)
end

sublist = getSublistByPrefixed(inputdir, prefix);

% load masks
head_GM = spm_vol(grayMatterMask);
image_dim = head_GM.dim;
d_GM = spm_read_vols(head_GM);
GM_reshape = reshape(d_GM,image_dim(1)*image_dim(2)*image_dim(3),1);

% load functional images and convert them into a 3-D matrix (voxel x time x subject)
if nargin == 5
    [allSub_GMData,flag,errorsub] = getTimeCourse(inputdir, prefix, grayMatterMask, app);
else
    [allSub_GMData,flag,errorsub] = getTimeCourse(inputdir, prefix, grayMatterMask);
end

disp('loading done!!! ')
%% Calculating ISC
fprintf('Calculating ISC...')

if nargin == 5
    app.ax.Title.String = 'Calculating ISC...';
    ph = patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
    drawnow
end
Nsub = length(sublist);
for subNum = 1:length(sublist)
    fprintf('...');
    % Leave one out
    allSub_GMData_LOO = allSub_GMData(:,:,:);
    allSub_GMData_LOO(:,:,subNum) = [];
    mean_allSub_GMData_LOO = mean(allSub_GMData_LOO, 3);

    % % Fisher's z
    for voxi = 1:length(find(GM_reshape))
        result(voxi,1) = atanh(corr2(mean_allSub_GMData_LOO(voxi,:),squeeze(allSub_GMData(voxi,:,subNum))));  % Fisher's z
    end
    result_map = zeros(image_dim(1)*image_dim(2)*image_dim(3),1);
    result_map(find(GM_reshape)) = result;
    resultData = reshape(result_map,image_dim(1),image_dim(2),image_dim(3));
    V.dim   = head_GM.dim;
    V.dt    = [16 0];
    V.mat   = head_GM.mat;
    V.fname = [savedDir filesep 'ISC_FZ_LOO_' sublist(subNum).name '.nii'];
    spm_write_vol(V,resultData);

    % % No Fisher's z
    for voxi = 1:length(find(GM_reshape))
        result(voxi,1) = corr2(mean_allSub_GMData_LOO(voxi,:),squeeze(allSub_GMData(voxi,:,subNum)));
    end
    result_map = zeros(image_dim(1)*image_dim(2)*image_dim(3),1);
    result_map(find(GM_reshape)) = result;
    resultData = reshape(result_map,image_dim(1),image_dim(2),image_dim(3));
    V.dim   = head_GM.dim;
    V.dt    = [16 0];
    V.mat   = head_GM.mat;
    if exist([inputdir filesep sublist(1).name]) == 7 % 判断是否为文件夹
        V.fname = [savedDir filesep 'ISC_R_LOO_' sublist(subNum).name '.nii'];
    else
        V.fname = [savedDir filesep 'ISC_R_LOO_' sublist(subNum).name];
    end
    spm_write_vol(V,resultData);
    flag = 1;

    if nargin == 5
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'Calculating ISC ' jindu '%...'];
        drawnow
    end

end
NDN_batch_generate_3dnii_2_tif(savedDir)
disp('Done !')
end