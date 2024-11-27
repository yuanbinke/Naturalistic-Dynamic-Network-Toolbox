function yjj_batch_generate_3dnii_2_tif(inputDir)
%YJJ_BATCH_GENERATE_3DNII_2_TIF convert all NII files under a specified
%path into TIFF format images and save them in the original path.
%
%   


if ~which("brainnet")
    warning("BrainNet has not been added to the MATLAB path. Please add it and run again.")
    return 
end

cd(inputDir)
niiList=dir('*.nii');

[pathstr1, ~]=fileparts(which('BrainNet.m'));
surfile=[pathstr1 filesep 'Data\SurfTemplate\BrainMesh_ICBM152_smoothed.nv'];
[pathstr2, ~]=fileparts(which('NDN'));
cfgfile=[pathstr2 filesep 'data\cfg_brainnet_subisc_noDirection.mat'];

for f=1:length(niiList)
    niifile=[inputDir filesep niiList(f).name];
    picname=[inputDir filesep niiList(f).name(1:end-4) '.tif'];
    Yuan_BrainNet_MapCfg(surfile, cfgfile, niifile, picname);
%     close(gcf)
end

end

