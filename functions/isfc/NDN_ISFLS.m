function dFC_result = NDN_ISFLS(inputdir, savedDir, params, app)
%FORMAT NDN_ISFLS(inputdir, savedDir, params, app)
%NDN_ISFLS treated dFC estimation as a dynamic regression coefficients
% estimation in a time-series linear regression model
%
%INPUT:
% inputdir          - Path of nSubjects' 2D ROI timecourse mat/txt file(nT * nR)
% savedDir          - Path for saved
% params            - A structure containing relevant parameters of ISSWFC
%   methodType      - Valid values are 'FLS' or 'ISFLS'. ISFLS is an
%                     improved approach which can accomplish a higher
%                     spatiotemporal consistency.When selecting the
%                     original version, the ISA-type value does not need to
%                     be specified
%                     
%   ISA_type        -Valid values are 'regressLOO' or 'LOO'. The type of
%                     intersubject analysis. 
%   mu              - A number Type, default is 100
%                  
% app               - A optional argument, is a uiobject 
if ~isfield(params, "methodType")
    error("params.methodType should not be empty, it must be assgind ")
else
    methodType = params.methodType;
end

if isequal(methodType, 'ISFLS') && ~isfield(params, "ISA_type")
    error("params.methodType should not be empty, it must be assgind ")
end

if isequal(methodType, 'ISFLS') && isfield(params, "ISA_type")
    ISA_type = params.ISA_type;
end

if ~isfield(params, "mu")
    error("params.mu should not be empty, it must be assgind ")
else
    mu = params.mu;
end

if ~exist("savedDir", "dir")
    mkdir(savedDir)
end
if ~isfield(params, "TR")
    error("params.TR should not be empty, it must be assgind ")
end
cd(inputdir)
fileList = dir('*.mat');

data=read_2Dmat_2_3DmatrixROITC(inputdir);
N_sub = size(data, 3);
N_time = size(data, 1);
N_roi = size(data, 2);
Nwin = N_time;


%% dynamic FC

if nargin == 4
    app.ax.Title.String = ['Calculating ' methodType ' ...'];
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end
dFC_result=[];
for s=1:N_sub
    subtc=squeeze(data(:,:,s));%time * ROI

    if isequal(methodType, 'ISFLS')
        %% isxxx
        LOO=data;
        LOO(:,:,s)=[];
        fprintf('ISFLS for sub %s\n', num2str(s));

        if isequal(ISA_type, 'LOO')
            subtc2=[subtc,squeeze(mean(LOO,3))];
            subtc2Z=zscore(subtc2);
            Ct2 = yuan_DynamicBC_fls_FC(subtc2Z,mu);
            % extract the upper right ISDCC values
            ISCt2=Ct2(1:N_roi, N_roi + 1 : N_roi * 2, :);
            % moving average DCC with window length
            tmp_dFC_DCCX=zeros(Nwin,N_roi*N_roi);
            for iw=1:Nwin
                tmpr=ISCt2(:,:,iw);
                tmp_dFC_DCCX(iw,:)=mat2vec_Asym(tmpr);
            end

        end
        if isequal(ISA_type, 'regressLOO')
            LOO_mean = mean(LOO,3);
            subDataAfterRemoveCov = NDN_regressLOO(subtc, LOO_mean);
            subtcZ=zscore(subDataAfterRemoveCov);
            Ct2 = yuan_DynamicBC_fls_FC(subtcZ, mu);
            % extract the upper right ISDCC values
            % moving average DCC with window length
            atmp=zeros(size(Ct2,1),size(Ct2,1));
            tmp_dFC_DCCX=zeros(Nwin,length(mat2vec(atmp)));
            for iw = 1:Nwin
                tmpr = Ct2(:,:,iw);
                tmp_dFC_DCCX(iw,:) = mat2vec(squeeze(tmpr));
            end
        end

    end
    if isequal(methodType, 'FLS')% xxx
        subtcZ=zscore(subtc);%time * ROI

        fprintf('FLS for sub %s\n', num2str(s));
        Ct2 = yuan_DynamicBC_fls_FC(subtcZ,mu);
        % extract the upper right ISDCC values
        % moving average DCC with window length
        atmp=zeros(size(Ct2,1),size(Ct2,1));
        tmp_dFC_DCCX=zeros(Nwin,length(mat2vec(atmp)));
        for iw=1:Nwin
            tmpr=Ct2(:,:,iw);
            tmp_dFC_DCCX(iw,:)=mat2vec(squeeze(tmpr));
        end
    end

    %%
    tmp_dFC = tmp_dFC_DCCX;
    DEV = std(tmp_dFC, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);%?
    SP{s,1} = tmp_dFC(pIND, :);%Subsampling
    dFC_result=[dFC_result;tmp_dFC];

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
res.method = methodType;
res.TR = params.TR;
res.N_sub = N_sub;
res.N_roi = N_roi;
if exist("ISA_type", "var")
    res.ISA_type = ISA_type;
end
if exist("ISA_type","var")
    write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, [methodType '_' ISA_type])
    save([methodType '_' ISA_type '_all.mat'], 'res', '-v7.3')


else
    write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, methodType)
    save([methodType '_all.mat'], 'res', '-v7.3')

end

end

