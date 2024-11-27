clear
clc

rootdir='E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw';

method='L1';
TR=1;
wsize=22;


%% dynamic FC

%         load data （nt *  nr * nsub）
data = read_2Dmat_2_3DmatrixROITC(rootdir);
N_roi=size(data, 2);

dFC_result=[];
for s=1:size(data, 3)

    subtc=squeeze(data(:,:,s));%time * ROI
    subtcZ=zscore(subtc);
    [tmp_dFC]=pp_ReHo_dALFF_dFC_gift(subtcZ,method,TR,wsize);%trme * ROI paris, 2D. r*(r-1)/2

    DEV = std(tmp_dFC, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);%?
    SP{s,1} = tmp_dFC(pIND, :);%Subsampling
    dFC_result=[dFC_result;tmp_dFC];
end%s
cd(resultdir)
% save('SP.mat','SP','-v7.3')
% 
% save('dFC_result.mat','dFC_result','-v7.3')



