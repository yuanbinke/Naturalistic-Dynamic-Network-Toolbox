clc
clear
addpath('.\')
rootaddr = 'G:\小王子数据\derivation\EN\Runs';
cd(rootaddr)
storyList = dir('*run*');
Maskfile = 'E:\Little Prince\mask\Reslice_Reslice_GreyMask_02_61x73x61.img';

stotyIndex = 1;
runname = storyList(stotyIndex).name;
datadir = [rootaddr filesep runname];
cd(datadir)
subjlist = [];
subjlist = dir('sub*');


%% 获得当前故事的nt
subaddr=[datadir filesep subjlist(1).name ];
cd(subaddr)
niiname = dir('*nii');
fourDnii_head=spm_vol(niiname.name);
Ntime=size(fourDnii_head,1);

%% 对4d图像进行LOO生成4d

%进如到niftipari进行LOO

cd(datadir)
subjlist = [];
subjlist = dir('sub*');

Postfix = '_ResReg';
for subji = 1:length(subjlist)
    fprintf('subject %d ... ',subji);
    Yuan_batch_Voxelregress_meanVolume_LOO_4d(datadir,subji,Maskfile,Ntime);
    Mean4Dfile=[datadir filesep subjlist(subji).name filesep 'LOO' filesep 'LOO_' subjlist(subji).name '_Mean4D.nii'];
    subDir =[datadir filesep subjlist(subji).name];
    Yuan_RegressOutRes_4d(subDir,Mean4Dfile,Postfix,Maskfile);
end

%% 将LOO后的数据转移到'LOO_ResReg文件夹下面

tempAdd='\LOO_ResReg\_ResReg';
desAdd=[datadir filesep 'LOO_ResReg'];mkdir(desAdd)
cd(datadir);
sublist = [];
sublist=dir('sub*');
%         将每个人的LOO后的数据转移到'LOO_ResReg文件夹
for i = 1:length(sublist)
    newaddr=[desAdd filesep sublist(i).name];
    mkdir(newaddr)

    cd([datadir filesep sublist(i).name filesep tempAdd]);
    niiFile = [];
    niiFile = dir('*.nii');
    movefile(niiFile(1).name, newaddr);

%     cd([datadir filesep sublist(i).name])
%     txtFile = [];
%     txtFile = dir('*txt');
%     copyfile(txtFile(1).name, newaddr);
end


