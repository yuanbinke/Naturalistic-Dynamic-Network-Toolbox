function Yuan_getLOOMeanVolume(inputdir, prefix, LOsub,Maskfile)
% Loading all subjects nii data, leave one subject out, and return the mean of the 
% remaining subjects
% Every mean volume will be saved at the path: 'inputdir/sublist(LOsub).name/LOO' 

cd(inputdir)
sublist = getSublistByPrefixed(inputdir, prefix);


[~, dR_GM, h_GM] = readGM(Maskfile);
image_dim = h_GM.ImageSize;

% % load functional images and convert them into a 3-D matrix (voxel x time x subject)
fprintf('Loading image...')
subName=sublist(LOsub).name;
%% get h
if ~exist([inputdir filesep sublist(1).name filesep 'func'])
    mkdir([inputdir filesep sublist(1).name filesep 'func'])
end 
cd([inputdir filesep sublist(1).name filesep 'func'])

niifile = dir('*.nii');
if size(niifile, 1) == 0
    niifile = dir('*.nii.gz');
end
if size(niifile, 1) == 0
    cd('..')
    niifile = dir('*.nii');
    if size(niifile, 1) == 0
        niifile = dir('*.nii.gz');
    end
end

if size(niifile, 1) == 0
    error([sublist(1).name 'does not contain nii file'])
end

[~, h] = NDN_Read(niifile(1).name);
nT = h.ImageSize(4);
%%  Loading all subjects nii data
VData_image_masked = getTimeCourse(inputdir, prefix, Maskfile);
%% leave one subject out, and return the mean data
VData_image_masked(:, :, LOsub) = [];
a_image_hold = mean(VData_image_masked(:,:,:),3);
y_map_r=zeros(image_dim(1)*image_dim(2)*image_dim(3), nT);
y_map_r(find(dR_GM),:)=a_image_hold;
y_map = reshape(y_map_r,image_dim(1),image_dim(2),image_dim(3), nT);
cd(inputdir)
mkdir([inputdir filesep subName filesep 'LOO']);
fname=[inputdir filesep subName filesep 'LOO' filesep 'LOO_' subName '_Mean4D.nii'];

NDN_Write(y_map, fname, h);
fprintf(' done! \n')