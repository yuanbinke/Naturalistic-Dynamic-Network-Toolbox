clear 
clc
rootdir='E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw';

methodType = 'SWISFC';% Valid values are "SWFC" or "SWISFC".
% ISA_type (str): The type of intersubject analysis. Valid values are "regressLOO" or "LOO".
ISA_type = 'regressLOO';
%         load data （nt *  nr * nsub）
data=read_2Dmat_2_3DmatrixROITC(rootdir);
N_sub = size(data, 3);
N_time = size(data, 1);
N_roi = size(data, 2);

wsize=22;
Nwin = N_time - wsize;
method='L1';
TR=1;
%% dynamic FC
savedDir=[];
dFC_result=[];

for s=1:N_sub
    subtc=squeeze(data(:,:,s));%time * ROI

    if isequal(methodType, 'SWISFC')
        %% isxxx
        % leave one out
        LOO = data;
        LOO(:,:,s)=[];
        fprintf('SWISFC for sub %s\n', num2str(s));
        if ~exist("ISA_type","var")
            error("Argument ISA_type should not be empty, it must be assgind ")
        end
        if isequal(ISA_type, "LOO") % LOO
            subtc2=[subtc,squeeze(mean(LOO,3))];
            subtc2Z=zscore(subtc2);

            [Ct2]=pp_ReHo_dALFF_dFC_gift(subtc2Z, method, TR, wsize);%trme * ROI paris, 2D. r*(r-1)/2

            n = size(subtc2Z, 2);
            tmp_CT2 = zeros(n, n, Nwin);
            for i = 1: Nwin
                tmp_CT2(:, :, i) = NDN_vec2mat(Ct2(i, :), n);
            end
            % extract the upper right ISDCC values
            ISCt2=tmp_CT2(1:N_roi, N_roi + 1 : N_roi * 2, :);
            % moving average DCC with window length
            tmp_dFC_DCCX=zeros(Nwin, N_roi * N_roi);
            for iw=1:Nwin
                tmpr=ISCt2(:,:,iw);
                tmp_dFC_DCCX(iw,:)=mat2vec_Asym(tmpr);
            end

        else % LOO_regress
            LOO_mean = mean(LOO,3);
            subDataAfterRemoveCov = NDN_regressLOO(subtc, LOO_mean);
            subtcZ=zscore(subDataAfterRemoveCov);
            [tmp_dFC_DCCX]=pp_ReHo_dALFF_dFC_gift(subtcZ,method,TR,wsize);%trme * ROI paris, 2D. r*(r-1)/2
        end


    else% xxx
        fprintf('SWFC for sub %s\n', num2str(s));
        subtcZ=zscore(subtc);
        [tmp_dFC_DCCX]=pp_ReHo_dALFF_dFC_gift(subtcZ,method,TR,wsize);%trme * ROI paris, 2D. r*(r-1)/2
    end

    %%
    tmp_CT2=tmp_dFC_DCCX;
    DEV = std(tmp_CT2, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);%?
    SP{s,1} = tmp_CT2(pIND, :);%Subsampling
    dFC_result=[dFC_result;tmp_CT2];

end%s

cd(savedDirdir)
save('SP.mat','SP','-v7.3')
save('dFC_result.mat','dFC_result','-v7.3')
