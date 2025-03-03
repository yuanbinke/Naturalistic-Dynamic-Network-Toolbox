function [ROI_TC, flag, errorsub] = getROITimeCourse(inputdir, prefix, ROIMask, app)
%FORMAT [ROI_TC, flag, errorsub] = getROITimeCourse(inputdir, prefix, ROIMask, app)
% getROITimeCourse loads functional images for all subjects and extracts 
% the time course data for regions of interest (ROIs), returning a 3-D 
% matrix of size (nTime x NROI x Nsub).
%
% INPUT:
%   inputdir        - A directory containing all subject data. Each subject's 
%                     4D nii file is stored in a separate subdirectory. The 
%                     expected structure is:
%                     - sub001/func/data_sub001.nii(.gz),recommended or
%                     - sub001/data_sub001.nii(.gz).
%
%   prefix          - A string used to identify the target subdirectories 
%                     or files within the inputdir. For example, if the 
%                     subject directories are named 'sub001', 'sub002', etc., 
%                     the prefix could be 'sub'.
%
%   ROIMask         - The file path to a mask file defining the regions of 
%                     interest (ROIs). This mask is used to extract time 
%                     course data from the specified ROIs.
%
%   app             - (Optional) A UI object (e.g., a progress bar or 
%                     message display) for providing feedback during the 
%                     execution of the function.
%
% OUTPUT:
%   ROI_TC          - A 3-D matrix of size (nTime x NROI x Nsub), where:
%                     - nTime is the number of time points in the functional 
%                       images,
%                     - NROI is the number of regions of interest (ROIs),
%                     - Nsub is the number of subjects.
%                     This matrix contains the time course data for all ROIs 
%                     and subjects.
%
%   flag            - A status flag indicating the outcome of the function:
%                     - -2: Indicates that the provided ROIMask is incorrect 
%                           or invalid.
%                     - -1: Indicates that the subject's subdirectory 
%                           (specified by errorsub) contains no .nii or 
%                           .nii.gz file.
%                     -  0: Indicates that the provided prefix is incorrect 
%                           (no matching subdirectories or files were found).
%                     -  1: Indicates that the function completed successfully.
%
%   errorsub        - The index of the subject's subdirectory that contains 
%                     no .nii or .nii.gz file. If no errors are found, this 
%                     value is set to 0.
flag = 1;
errorsub = 0;

sublist = getSublistByPrefixed(inputdir, prefix);

% Initialize counters for directories and files
dirCount = 0;
fileCount = 0;

% Loop through all items in sublist
for i = 1:length(sublist)
    itemPath = fullfile(inputdir, sublist(i).name);
    
    if exist(itemPath, 'dir') == 7
        dirCount = dirCount + 1; % Increment directory count
    elseif exist(itemPath, 'file') == 2
        fileCount = fileCount + 1; % Increment file count
    else
        error('Invalid item detected: %s is neither a directory nor a file.', itemPath);
    end
end

% Determine inputType based on counts
if dirCount > 0 && fileCount > 0
    error('Mixed items detected: inputdir contains both directories and files.');
elseif dirCount == length(sublist)
    inputType = 0; % All items are directories
elseif fileCount == length(sublist)
    inputType = 1; % All items are files
else
    error('Unexpected error: unable to determine inputType.');
end

% move each nii file into a seperate subdirectory
if inputType == 1 

    for index = 1 : size(sublist, 1)

        [pathstr, name, ext] = fileparts([inputdir filesep sublist(index).name]);
        if strcmpi(ext,'.gz')
            newSubDir = [pathstr filesep name(1:end-4) filesep 'func'];
        else
            newSubDir = [pathstr filesep name filesep 'func'];
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
    app.ax.Title.String = 'Loading Subjects...';
    ph = patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.9375, 0.9375, 0.3375]);
    drawnow
end

% get ROI time course
ROI_TC = [];
fprintf('loading subject ...')

for subNum = 1:length(sublist)
    fprintf('..');
    if ~exist([inputdir filesep sublist(subNum).name filesep 'func'])
        mkdir([inputdir filesep sublist(subNum).name filesep 'func'])
    end 
    cd([inputdir filesep sublist(subNum).name filesep 'func'])

    % In the /func directory, find the first .nii file. If no .nii file exists,
    % it will retrieve the first .nii.gz file. If neither .nii nor .nii.gz files
    % are found in the /func directory, it will move to the upper directory
    % and perform the search in the same way.
    dfile = dir('*.nii');
    if size(dfile, 1) == 0
        dfile = dir('*.nii.gz');
    end
    if size(dfile, 1) == 0
        cd('..')
        dfile = dir('*.nii');
        if size(dfile, 1) == 0
            dfile = dir('*.nii.gz');
        end
    end
    if size(dfile,1) == 0 % there is no nii file in subject subnum
        flag = -1;
        errorsub = subNum;
        error(['there is no .nii or .nii.gz file in' sublist(subNum).name])
    end

    volInfo = spm_vol(dfile(1).name);

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