function dFC_result = NDN_ISDCC(inputdir, savedDir, params, app)
%FORMAT NDN_ISDCC(inputdir, savedDir, params, app)
%NDN_ISDCC adopts generalized autoregressive conditional heteroscedastic
% (GARCH) to express the conditional variance of a single time series at
% time t as a linear combination of the conditional variance plus the
% squared values of the previous time point. To compute the time-varying
% conditional correlation between two univariate time series, an
% exponentially weighted moving average (EWMA) window is applied to the
% standardized residuals obtained by the GARCH model.
%
%INPUT:
% inputdir          - Path of nSubjects' 2D ROI timecourse mat/txt file(nT * nR)
% savedDir          - Path for saved
% params            - A structure containing relevant parameters of ISSWFC
%   methodType      - Valid values are 'DCC' or 'ISDCC'. ISDCC is an
%                     improved approach which can accomplish a higher
%                     spatiotemporal consistency.When selecting the
%                     original version, the ISA-type value does not need to
%                     be specified
%
%   ISA_type        - Valid values are 'regressLOO' or 'LOO'. The type of
%                     intersubject analysis.
%   nullMdl         - An Optional Attribute, using an empty model to
%                     generate data, its values can be either 'ar' or 'pr'.
%                     It will call the Phase Randomized or Multivariate ARR
%                     model to generate additional data, and optionally
%                     return the DFC result of the data.
% app               - A optional argument, is a uiobject


if ~isfield(params, "methodType")
    error("params.methodType should not be empty, it must be assgind ")
else
    methodType = params.methodType;
end

if isequal(methodType, 'ISDCC') && ~isfield(params, "ISA_type")
    error("params.methodType should not be empty, it must be assgind ")
end

if isequal(methodType, 'ISDCC') && isfield(params, "ISA_type")
    ISA_type = params.ISA_type;
end

if ~exist("savedDir", "dir")
    mkdir(savedDir)
end

if ~isfield(params, "TR")
    error("params.TR should not be empty, it must be assgind ")
end
cd(inputdir)
fileList = dir('*.mat');
%         load data （nt *  nr * nsub�?
data=read_2Dmat_2_3DmatrixROITC(inputdir);
N_sub = size(data, 3);
N_time = size(data, 1);
N_roi = size(data, 2);
Nwin = N_time;
allpair = 0; parallel = 0;

%% dynamic FC
dFC_result=[];
nullMdlData_dFC_result=[];

if nargin == 4
    app.ax.Title.String = ['Calculating ' methodType ' ...'];
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end

for s=1:N_sub
    subtc=squeeze(data(:,:,s));%time * ROI
    
    if isequal(methodType, 'ISDCC') % isxxx
        LOO=data;
        LOO(:,:,s)=[];
        fprintf('ISDCC for sub %s\n', num2str(s));
        
        
        if isequal(ISA_type, 'LOO')
            subtc2=[subtc,squeeze(mean(LOO,3))];
            subtc2Z=zscore(subtc2);
            
            %  NullMdl
            if isfield(params, "nullMdl") && ~isequal(char(params.nullMdl), '')
                nullMdlData = squeeze(NDN_generateNullMldData(subtc2Z, params));
                nullMdlData = zscore(nullMdlData);
                N_time_2 = size(nullMdlData, 1);
                Nwin_2 = N_time_2;
                
                [~,Ct2,~,~] = DCC_X(nullMdlData,allpair, parallel);
                ISCt2=Ct2(1:N_roi, N_roi + 1 : N_roi * 2, :);

                nullMdlData_tmp_dFC_DCCX=zeros(Nwin_2,N_roi*N_roi);
                for iw=1:Nwin_2
                    tmpr=ISCt2(:,:,iw);
                    nullMdlData_tmp_dFC_DCCX(iw,:)=mat2vec_Asym(tmpr);
                end
            end
            
            %
            [~,Ct2,~,~] = DCC_X(subtc2Z,allpair, parallel);
            ISCt2=Ct2(1:N_roi, N_roi + 1 : N_roi * 2, :);
            
            tmp_dFC_DCCX=zeros(Nwin,N_roi*N_roi);
            for iw=1:Nwin
                tmpr=ISCt2(:,:,iw);
                tmp_dFC_DCCX(iw,:)=mat2vec_Asym(tmpr);
            end
        end
        if isequal(ISA_type, 'regressLOO')
            LOO_mean = mean(LOO, 3);
            subDataAfterRemoveCov = NDN_regressLOO(subtc, LOO_mean);
            subtcZ = zscore(subDataAfterRemoveCov);

            %  NullMdl
            if isfield(params, "nullMdl") && ~isequal(char(params.nullMdl), '')
                nullMdlData = squeeze(NDN_generateNullMldData(subtcZ, params));
                nullMdlData = zscore(nullMdlData);
                N_time_2 = size(nullMdlData, 1);
                Nwin_2 = N_time_2;
                [~,Ct2,~,~] = DCC_X(subtcZ,allpair, parallel);

                atmp = zeros(size(Ct2,1),size(Ct2,1));
                nullMdlData_tmp_dFC_DCCX = zeros(Nwin_2,length(mat2vec(atmp)));
                for iw = 1:Nwin_2
                    tmpr = Ct2(:,:,iw);
                    nullMdlData_tmp_dFC_DCCX(iw,:) = mat2vec(squeeze(tmpr));
                end
            end

            %
            [~,Ct2,~,~] = DCC_X(subtcZ,allpair, parallel);

            atmp=zeros(size(Ct2,1),size(Ct2,1));
            tmp_dFC_DCCX=zeros(Nwin,length(mat2vec(atmp)));
            for iw=1:Nwin
                tmpr=Ct2(:,:,iw);
                tmp_dFC_DCCX(iw,:)=mat2vec(squeeze(tmpr));
            end
        end
    end
    if isequal(methodType, 'DCC')% xxx
        subtcZ=zscore(subtc);%time * ROI
        fprintf('DCC for sub %s\n', num2str(s));
        %  NullMdl
        if isfield(params, "nullMdl") && ~isequal(char(params.nullMdl), '')
            nullMdlData = squeeze(NDN_generateNullMldData(subtcZ, params));
            nullMdlData = zscore(nullMdlData);
            N_time_2 = size(nullMdlData, 1);
            Nwin_2 = N_time_2;
            [~,Ct2,~,~] = DCC_X(subtcZ,allpair, parallel);

            atmp = zeros(size(Ct2,1),size(Ct2,1));
            nullMdlData_tmp_dFC_DCCX = zeros(Nwin_2,length(mat2vec(atmp)));
            for iw = 1:Nwin_2
                tmpr = Ct2(:,:,iw);
                nullMdlData_tmp_dFC_DCCX(iw,:) = mat2vec(squeeze(tmpr));
            end
        end

        %
        [~,Ct2,~,~] = DCC_X(subtcZ,allpair, parallel);

        atmp=zeros(size(Ct2,1),size(Ct2,1));
        tmp_dFC_DCCX=zeros(Nwin, length(mat2vec(atmp)));
        for iw=1:Nwin
            tmpr=Ct2(:,:,iw);
            tmp_dFC_DCCX(iw,:)=mat2vec(squeeze(tmpr));
        end
        
    end
    
    % nullMdl
    if isfield(params, "nullMdl") && ~isequal(char(params.nullMdl), '')
        tmp_dFC=nullMdlData_tmp_dFC_DCCX;
        DEV = std(tmp_dFC, [], 2);%STD OF NODE
        [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
        pIND = sort(imax);%?
        nullMdlData_k1_peaks(s) = length(pIND);%?
        nullMdlData_SP{s,1} = tmp_dFC(pIND, :);%Subsampling
        nullMdlData_dFC_result=[nullMdlData_dFC_result; tmp_dFC];

    end

    %
    tmp_dFC=tmp_dFC_DCCX;
    DEV = std(tmp_dFC, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);%?
    SP{s,1} = tmp_dFC(pIND, :);%Subsampling
    dFC_result=[dFC_result; tmp_dFC];
    
    if nargin == 4
        ph.XData = [0, s / N_sub, s / N_sub, 0];
        jindu = sprintf('%.2f',s / N_sub * 100);
        app.ax.Title.String =[ 'Calculating ' methodType ' ' jindu '%...'];
        drawnow
    end
end%s

cd(savedDir)

% transform dFC_result's shape
% from [N_time*N_sub, size(dFC_result, 2)] ===> [N_time, size(dFC_result, 2), N_sub]
dFC_result1 = reshape(dFC_result, [size(dFC_result, 1) / N_sub, N_sub, size(dFC_result, 2)]);
dFC_result2 = zeros(size(dFC_result, 1)/ N_sub, size(dFC_result, 2), N_sub);
for i = 1:size(dFC_result, 1)/ N_sub
    dFC_result2(i, :, :) = squeeze(dFC_result1(i, :, :))';
end

res.SP = SP;
res.dFC_result = dFC_result;
res.dFC_result_3D = dFC_result2;
res.method = methodType;
res.TR = params.TR;
res.N_sub = N_sub;
res.N_roi = N_roi;
if exist("ISA_type", "var")
    res.ISA_type = ISA_type;
end
if exist("ISA_type","var")
%     write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, [methodType '_' ISA_type])
    save([methodType '_' ISA_type '_all.mat'], 'res', '-v7.3')
else
%     write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, methodType)
    save([methodType '_all.mat'], 'res', '-v7.3')
end

if isfield(params, "nullMdl") && ~isequal(char(params.nullMdl), '')
    % transform dFC_result's shape
    % from [N_time*N_sub, size(dFC_result, 2)] ===> [N_time, size(dFC_result, 2), N_sub]
    dFC_result1 = reshape(nullMdlData_dFC_result, [size(nullMdlData_dFC_result, 1) / N_sub, N_sub, size(nullMdlData_dFC_result, 2)]);
    dFC_result2 = zeros(size(nullMdlData_dFC_result, 1) / N_sub, size(nullMdlData_dFC_result, 2), N_sub);
    for i = 1:size(nullMdlData_dFC_result, 1)/ N_sub
        dFC_result2(i, :, :) = squeeze(dFC_result1(i, :, :))';
    end

    nullMdlData_res.SP = nullMdlData_SP;
    nullMdlData_res.dFC_result = nullMdlData_dFC_result;
    nullMdlData_res.dFC_result_3D = dFC_result2;
    nullMdlData_res.method = methodType;
    nullMdlData_res.TR = params.TR;
    nullMdlData_res.N_sub = N_sub;
    nullMdlData_res.N_roi = N_roi;
    if exist("ISA_type", "var")
        nullMdlData_res.ISA_type = ISA_type;
    end
    if exist("ISA_type","var")
        %     write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, [methodType '_' ISA_type])
        save([methodType '_' ISA_type '_' char(params.nullMdl)  '_all.mat'], 'nullMdlData_res', '-v7.3')

    else
        %     write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, methodType)
        save([methodType '_' char(params.nullMdl)  '_all.mat'], 'nullMdlData_res', '-v7.3')
    end
end

end

