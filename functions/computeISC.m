function [flag,errorsub] = computeISC(inputdir, prefix, grayMatterMask, savedDir, app)
%computeISC  can compute n(n>=2) subject's Intersubject Correlation.
% INPUT:
% inputdir          - a directory which  contains all the subject data，every
%                       subject 4D—nii file is put in a subdirectory like
%                       sub001/data_sub001.nii or or directly put in inputdir
%                       like inputdir/data_sub001.nii
%
% prefix            - a String whose contents are decided by the target 
%                     subdirectorys or files in inputdir
%
% grayMatterMask    - the address of the grayMatter file
%
% savedDir          - Path for saved, optional argument, default content is
%                     [inputdir filesep 'ISC-Result']
% app               - a optional argument, is a uiobject
% 
% the output is the results of ISC which will be saved in savedDir
% flag : -1 means the subject(errorsub) has no nii file
%        0 means a incorrect prefix
%        1 means finishing successfully
% errorsub:represent the num of the subject(errorsub) which has no nii file
% ,0 represents null

if nargin == 3
    savedDir = fullfile(inputdir, 'ISC-Result');
end
if ~exist(savedDir,"dir")
    mkdir(savedDir)
end


sublist = getSublistByPrefixed(inputdir, prefix);

if exist([inputdir filesep sublist(1).name]) == 7% 判断是否为文件夹或者直接是nii文件
    inputType = 0; % 0代表 inputdir里面是许多子文件夹
else
    inputType = 1; % 1代表 inputdir里面是许多nii文件
end
if inputType == 1
    for index = 1 : size(sublist, 1)
        [pathstr, name, ext] = fileparts([inputdir filesep sublist(index).name]);
        if strcmpi(ext,'.gz')
            newSubDir = [pathstr filesep name(1:end-4)];
        else
            newSubDir = [pathstr filesep name];
        end
        mkdir(newSubDir)
        movefile([inputdir filesep sublist(index).name], newSubDir)
    end
    inputType = 0;
    sublist = getSublistByPrefixed(inputdir, prefix);
end

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
patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
app.ax.Title.String = 'Calculating ISC...';
disp('loading done!!! ')
%%
fprintf('Calculating ISC...')

if nargin == 5
    app.ax.Title.String = 'Calculating ISC...';
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
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
yjj_batch_generate_3dnii_2_tif(savedDir)
disp('Done !')
end