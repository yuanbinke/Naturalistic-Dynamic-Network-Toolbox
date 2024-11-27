function generateTaskResting(inputdir, prefix, dataType, Maskfile, app)
% Input:
%   inputdir       - where the 4d+time dataset stay. Every subject's  4D—nii 
%                    file should be put in a subdirectory like sub001/data_sub001.nii
%                    or directly put in inputdir like inputdir/data_sub001.nii
%   prefix         - prefix is decided by the target subdirectorys in inputdir
%   dataType       - dataType indicate which type of signal you want to acquire
%                     it have three options('resting', 'task','all')
%   MaskFilename   - The mask file for regression. Empty means perform regression on all the brain voxels.
%   app            - app, a optional argument, is a uiobject
%
% Output: 
%   The result will finally be saved in 'inputdir \ LOO_ResReg'
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


%%
sublist = getSublistByPrefixed(inputdir, prefix);
Nsub = size(sublist, 1);
if nargin == 5
    patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    app.ax.Title.String = 'Regressing Subjects';
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.9375, 0.9375, 0.3375]);
end

for subNum = 1:length(sublist)
    fprintf('subject %d ... ',subNum);
    Yuan_getLOOMeanVolume(inputdir, prefix, subNum, Maskfile);
    Mean4Dfile=[inputdir filesep sublist(subNum).name filesep 'LOO' filesep 'LOO_' sublist(subNum).name '_Mean4D.nii'];
    subDir =[inputdir filesep sublist(subNum).name];
    Yuan_RegressOutRes_4d(subDir, Mean4Dfile, dataType, Maskfile);

    if nargin == 5
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'Regressing Subjects' jindu '%...'];
        drawnow
    end
end

%% 将LOO后的数据转移到'LOO_ResReg文件夹下面

tempAdd1='\LOO_ResReg\Resting';
tempAdd2='\LOO_ResReg\Task';
cd(inputdir);
sublist = getSublistByPrefixed(inputdir, prefix);
if strcmp(dataType, 'resting') || strcmp(dataType, 'all')
    desAdd1=[inputdir filesep 'LOO_ResReg' filesep 'Resting'];mkdir(desAdd1)

    for i = 1:length(sublist)
        newaddr=[desAdd1 filesep sublist(i).name];
        mkdir(newaddr)
        movefile([inputdir filesep sublist(i).name tempAdd1 '\*.nii'], newaddr);
    end
end

if strcmp(dataType, 'task') || strcmp(dataType, 'all')
    desAdd2=[inputdir filesep 'LOO_ResReg' filesep 'Task'];mkdir(desAdd2)
     for i = 1:length(sublist)
        newaddr=[desAdd2 filesep sublist(i).name];
        mkdir(newaddr)
        movefile([inputdir filesep sublist(i).name tempAdd2 '\*.nii'], newaddr);

        cd([inputdir filesep sublist(i).name])
        txtFile = dir('*txt');
        if size(txtFile, 1) == 1
            copyfile(txtFile(1).name, newaddr);
        end
    end
end



end

