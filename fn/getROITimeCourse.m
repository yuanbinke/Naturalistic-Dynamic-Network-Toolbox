function [ROI_TC, flag, errorsub] = getROITimeCourse(inputdir, prefix, ROIMask, app)
%load functional images and convert them into a 3-D matrix (voxel x time x subject)

%   inputdir is the directory which  contains all the subject data，every
%       subject 4D—nii file is put in a subdirectory like
%       sub001/data_sub001.nii or or directly put in inputdir like inputdir/data_sub001.nii
%   prefix is decided by the target subdirectorys in inputdir
%   ROIMask is the address of the ROIMask file
%   app, a optional argument, is a uiobject


% ROI_TC: return a ROI time course matrix(nTime * NROI * Nsub)
% flag: -2 means a incorrect ROIMask
%        -1 means the subject(errorsub) has no nii file
%        0 means a incorrect prefix
%        1 means finishing successfully.
% errorsub: in the case that every subject 4D—nii file is put in a subdirectory, errorsub represent
%            the index of the subdir which has no nii file,0 represents null   
%            
flag = 1;
errorsub = 0;

sublist = getSublistByPrefixed(inputdir, prefix);

if exist([inputdir filesep sublist(1).name]) == 7 % 判断是否为文件夹或者直接是nii文件
    inputType = 0; % 0代表 inputdir里面是许多子文件夹
else
    inputType = 1; % 1代表 inputdir里面是许多nii文件
end

% move each nii file into a seperate subdirectory
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


Nsub = size(sublist, 1);
if Nsub == 0
    flag = 0;
    disp(['There is no subject with a prefix:' prefix]);
    return
end

[d_GM, ~] = readGM(ROIMask);
d_GM(isnan(d_GM)) = 0;

RoiIndex = 1:max(d_GM(:));

% record all voxels'coordinations of each ROI into the corresponding cell
MNI_coord = cell(length(RoiIndex),1);

% get the corresponding coordinations 
for j = 1:length(RoiIndex)
    RegionJ = j;
    ind = find(RegionJ == d_GM(:));

    if ~isempty(ind)
        [I,J,K] = ind2sub(size(d_GM),ind);
        XYZ = [I J K]';
        XYZ(4,:) = 1;
        MNI_coord{j,1} = XYZ;
    else
        disp(['There are no voxels in ROI ' num2str(RoiIndex(j)) ', please specify ROIs again']);
        flag = -2;
        return
    end
end


if nargin == 4
    app.ax.Visible = 'on';

    app.ax.Title.String = 'Loading Subjects';
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.9375, 0.9375, 0.3375]);
end

% get ROI time course
ROI_TC = [];
fprintf('loading subject ...')

for subNum = 1:length(sublist)
    fprintf('..');
    cd ([inputdir filesep sublist(subNum).name])
    dfile = dir();
    if size(dfile,1) == 2%there is no nii file in subject subnum
        flag = -1;
        errorsub = subnum;
        return
    end
    volInfo = spm_vol(dfile(3).name);

    MTC = zeros(size(volInfo,1),length(RoiIndex));

    for j = 1:length(RoiIndex)
        % vy行为对应的时间数，列为脑区
        VY = spm_get_data(volInfo, MNI_coord{j, 1});
        MTC(:, j) = mean(VY, 2);
    end
    MTC(isnan(MTC))=0;
    ROI_TC(:, :, subNum) = MTC;
    if nargin == 4
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'loading subject nii file' jindu '%...'];
        drawnow
    end

end

end