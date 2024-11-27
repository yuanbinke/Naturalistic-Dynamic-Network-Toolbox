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
sublist(LOsub)=[];
%% get the number of TRs
subaddr=[inputdir filesep sublist(1).name ];
cd(subaddr)

niifile = dir('*.nii');
if size(niifile, 1) == 0
    niifile = dir('*.nii.gz');
end

if size(niifile,1) == 0
    error([sublist(1).name 'does not contain nii file'])
    return
end

[d, h] = yjj_Read(niifile(1).name);
Ntime=size(d, 4);

VData_image_masked = zeros(length(find(dR_GM)),Ntime,length(sublist));
%%  Loading all subjects nii data
for subji = 1:length(sublist)
    fprintf('subject %d ... ',subji);
    
    nii4daddr=[inputdir filesep sublist(subji).name];
    cd(nii4daddr);
    
    niifile = dir('*.nii');
    if size(niifile, 1) == 0
        niifile = dir('*.nii.gz');
    end

    if size(niifile,1) == 0
        error([sublist(1).name 'does not contain nii file'])
        return
    end

    [d, h] = yjj_Read(niifile(1).name);
    
    a_image = reshape(d, [size(d,1) * size(d,2) * size(d,3), size(d,4)]);
    VData_image_masked(:,:,subji) = a_image(find(dR_GM),:);
end
%% leave one subject out, and return the mean data
a_image_hold = mean(VData_image_masked(:,:,:),3);
y_map_r=zeros(image_dim(1)*image_dim(2)*image_dim(3),Ntime);
y_map_r(find(dR_GM),:)=a_image_hold;
y_map = reshape(y_map_r,image_dim(1),image_dim(2),image_dim(3),Ntime);
cd(inputdir)
mkdir([inputdir filesep subName filesep 'LOO']);
fname=[inputdir filesep subName filesep 'LOO' filesep 'LOO_' subName '_Mean4D.nii'];

yjj_Write(y_map, fname, h);
fprintf(' done! \n')