clc
clear

inputdir = 'O:\GXL\test\FunImgARWSDglobalCF';
prefix = '2';
ROIMask = 'O:\GXL\test\mask\BNSL_68_3mm.nii';

computeSFC(inputdir, prefix, ROIMask);