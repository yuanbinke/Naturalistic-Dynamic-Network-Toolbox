clear all;clc;
rootdir='E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw';

methodType = 'ISGLKF';% Valid values are "GLKF" or "ISGLKF".
% ISA_type (str): The type of intersubject analysis. Valid values are "regressLOO" or "LOO".
ISA_type = 'regressLOO';

%（nt *  nr * nsub）
data=read_2Dmat_2_3DmatrixROITC(rootdir);
N_sub = size(data, 3);
N_time = size(data, 1);
N_roi = size(data, 2);

Nwin = N_time-6;
TR=1;
pKF=6;
ucKF=0.03;

%% dynamic FC
dFC_result=[];
savedDir = [];
for s=1:N_sub
    subtc=squeeze(data(:,:,s));%time * ROI

    if isequal(methodType, 'ISGLKF') % isxxx
        LOO=data;
        LOO(:,:,s)=[];
        fprintf('ISGLKF for sub %s\n', num2str(s));
        if ~exist("ISA_type","var")
            error("Argument ISA_type should not be empty, it must be assgind ")
        end
        if isequal(ISA_type, "LOO")

            subtc2=[subtc,squeeze(mean(LOO,3))];

            subtc2Z=zscore(subtc2);
            YKF(1,:,:)=subtc2Z';

            FKF = dynet_SSM_KF(YKF,pKF,ucKF);
            for i=1:N_time
                FKFR(:,:,i)=icatb_corrcov(squeeze(FKF.R(:,:,i)));
            end
            % extract the upper right ISDCC values
            ISCt2=FKFR(1:N_roi,N_roi+1:N_roi*2,:);
            % moving average DCC with window length
            tmp_dFC_DCCX=zeros(Nwin,N_roi*N_roi);
            for iw=1:Nwin
                tmpr=ISCt2(:,:,iw+6);
                tmp_dFC_DCCX(iw,:)=mat2vec_Asym(tmpr);
            end
        end
        if isequal(ISA_type, "regressLOO")
            LOO_mean = mean(LOO,3);
            subDataAfterRemoveCov = NDN_regressLOO(subtc, LOO_mean);
            subtcZ=zscore(subDataAfterRemoveCov);
            YKF(1,:,:)=subtcZ';
            FKF = dynet_SSM_KF(YKF,pKF,ucKF);
            for i=1:N_time
                FKFR(:,:,i)=icatb_corrcov(squeeze(FKF.R(:,:,i)));
            end
            % moving average DCC with window length extract the upper right ISDCC values
            atmp=zeros(size(FKFR,1),size(FKFR,1));
            tmp_dFC_DCCX=zeros(Nwin,length(mat2vec(atmp)));
            for iw=1:Nwin
                tmpr=FKFR(:,:,iw+6);
                tmp_dFC_DCCX(iw,:)=mat2vec(squeeze(tmpr));
            end
        end
    end
    if isequal(methodType, 'GLKF')% xxx
        subtcZ=zscore(subtc);%time * ROI
        fprintf('GLKF for sub %s\n', num2str(s));
        YKF(1,:,:)=subtcZ';
        FKF = dynet_SSM_KF(YKF,pKF,ucKF);
        for i=1:N_time
            FKFR(:,:,i)=icatb_corrcov(squeeze(FKF.R(:,:,i)));
        end
        % moving average DCC with window length extract the upper right ISDCC values
        atmp=zeros(size(FKFR,1),size(FKFR,1));
        tmp_dFC_DCCX=zeros(Nwin,length(mat2vec(atmp)));
        for iw=1:Nwin
            tmpr=FKFR(:,:,iw+6);
            tmp_dFC_DCCX(iw,:)=mat2vec(squeeze(tmpr));
        end

    end

    tmp_dFC=tmp_dFC_DCCX;
    DEV = std(tmp_dFC, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);%?
    SP{s,1} = tmp_dFC(pIND, :);%Subsampling
    dFC_result=[dFC_result;tmp_dFC];
end%s
cd(savedDir)
save('SP.mat','SP','-v7.3')

save('dFC_result.mat','dFC_result','-v7.3')

