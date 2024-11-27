function [allSub_GMData, flag, errorsub] = getTimeCourse(inputdir, prefix, grayMatterMask, app)
%getTimeCourse load functional images and convert them into a 3-D matrix (voxel x time x subject)
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
% app               - a optional argument, is a uiobject
%
% OUTPUT
% allSub_GMData     - a matrix(nVoxel * nTime * nSub)
% flag              - -1 means the (errorsub)subject's subdirectory has no nii file
%                     0 means a incorrect prefix
%                     1 means finishing successfully.
% errorsub          - a Number that represents the index of the subject's subdirectory
%                      which has no nii file, 0 represents null
% 
flag = 1;
errorsub = 0;


%% get the Nsub and Ntime
sublist = getSublistByPrefixed(inputdir, prefix);

if exist([inputdir filesep sublist(1).name]) == 7% 判断是否为文件夹
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



Nsub = size(sublist,1);
if Nsub == 0
    flag = 0;
    disp(['There is no subject with a prefix:' prefix]);
    return
end


cd([inputdir filesep sublist(1).name]);
subNiiFile = dir('*.nii');
if size(subNiiFile, 1) == 0
    subNiiFile = dir('*.nii.gz');
end

[~, subHead] = yjj_Read(subNiiFile(1).name);
Ntime = subHead.ImageSize(4);

cd(inputdir)
%%

[d_GM, dR_GM, ~] = readGM(grayMatterMask);

% load functional images and convert them into a 3-D matrix (voxel x time x subject)
allSub_GMData = zeros(length(find(dR_GM)),Ntime,Nsub);
fprintf('loading subject nii file...')
if nargin == 4
    app.ax.Visible = 'on';
    app.ax.Title.String = 'Loading Subjects';
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end
for subNum = 1:Nsub
    fprintf('..');

    %判断子文件是否包含nii文件
    cd([inputdir filesep sublist(subNum).name])
    dfile = dir('*.nii');
    if size(dfile, 1) == 0
        dfile = dir('*.nii.gz');
    end
    if size(dfile,1) == 0%there is no nii file in subject subnum
        flag = -1;
        errorsub = subNum;
        error(['there is no nii file in the ' subNum 'th subject Directory'])
    end
    %读取文件
    [volData, volInfo] = yjj_Read([inputdir filesep sublist(subNum).name filesep dfile(1).name]);
    
    d_reshape = reshape(volData, [size(volData,1)*size(volData,2)*size(volData,3), size(volData,4)]);
    if all(size(d_GM) ~= size(squeeze(volData(:,:,:,1))))
        error("masks's shape is not equal to data's shape");
    end
    allSub_GMData(:,:,subNum) = d_reshape(find(dR_GM),:);
    if nargin == 4
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'loading subject nii file ' jindu '%...'];
        drawnow
    end
end

end