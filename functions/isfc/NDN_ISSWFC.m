function dFC_result = NDN_ISSWFC(inputdir, savedDir, params, app)
%FORMAT NDN_ISSWFC(inputdir, savedDir, params, app)
%NDN_ISSWFC calculates the sliding-window-based dynamic functional
% connectivity for a group of subjects. This study used a Gaussian tapered
% window by convolving a rectangle with a Gaussian kernel (σ=3).To increase
% the estimation accuracy, L1 regularization was adopted. The free
% parameter λ, which enables a trade-off between the sparsity of the
% inverse covariance matrix and goodness of fit, was estimated within each
% data point.
%
%
%INPUT:
% inputdir          - Path of nSubjects' 2D ROI timecourse mat/txt file(nT * nR)
% savedDir          - Path for saved
% params            - A structure containing relevant parameters of ISSWFC
%   methodType      - Valid values are 'SWFC' or 'ISSWFC'. ISSWFC is an
%                     improved approach which can accomplish a higher
%                     spatiotemporal consistency.When selecting the
%                     original version, the ISA-type value does not need to
%                     be specified
%                     
%   ISA_type        - Valid values are 'regressLOO' or 'LOO'. The type of
%                     intersubject analysis. 
%   wsize           - The size of the sliding-window
%   TR              - represent the time repitition of the current group. 
%                   
% app               - A optional argument, is a uiobject              


if ~isfield(params, "methodType")
    error("params.methodType should not be empty, it must be assgind ")
else
    methodType = params.methodType;
end

if isequal(methodType, 'ISSWFC') && ~isfield(params, "ISA_type")
    error("params.methodType should not be empty, it must be assgind ")
end

if isequal(methodType, 'ISSWFC') && isfield(params, "ISA_type")
    ISA_type = params.ISA_type;
end

if ~isfield(params, "wsize")
    error("params.wsize should not be empty, it must be assgind ")
else
    wsize = params.wsize;
end

if ~isfield(params, "TR")
    error("params.TR should not be empty, it must be assgind ")
else
    TR = params.TR;
end

if ~exist("savedDir", "dir")
    mkdir(savedDir)
end
cd(inputdir)
fileList = dir('*.mat');

% load data （nt *  nr * nsub�?
data=read_2Dmat_2_3DmatrixROITC(inputdir);
N_sub = size(data, 3);
N_time = size(data, 1);
N_roi = size(data, 2);
Nwin = N_time - wsize;
method='L1';

%% dynamic FC
dFC_result=[];

if nargin == 4
    app.ax.Title.String = ['Calculating ' methodType ' ...'];
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end

for s=1:N_sub
    subtc=squeeze(data(:,:,s));%time * ROI

    if isequal(methodType, 'ISSWFC')
        %% isxxx
        % leave one out
        LOO = data;
        LOO(:,:,s)=[];
        fprintf('ISSWFC for sub %s\n', num2str(s));

        if isequal(ISA_type, 'LOO') % LOO
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
        end
        if isequal(ISA_type, 'regressLOO') % LOO_regress
            LOO_mean = mean(LOO,3);
            subDataAfterRemoveCov = NDN_regressLOO(subtc, LOO_mean);
            subtcZ = zscore(subDataAfterRemoveCov);
            [tmp_dFC_DCCX]=pp_ReHo_dALFF_dFC_gift(subtcZ,method,TR,wsize);%trme * ROI paris, 2D. r*(r-1)/2
        end


    end
    if isequal(methodType, 'SWFC')% xxx
        fprintf('SWFC for sub %s\n', num2str(s));
        subtcZ=zscore(subtc);
        [tmp_dFC_DCCX]=pp_ReHo_dALFF_dFC_gift(subtcZ,method,TR,wsize);%trme * ROI paris, 2D. r*(r-1)/2
    end

    %%
    tmp_dFC = tmp_dFC_DCCX;
    tmp_dFC_DCCX = normalize_to_minus_one_plus_one(tmp_dFC_DCCX);
    for edge_i = 1:size(tmp_dFC_DCCX, 2)
        tmp_dFC(:, edge_i) = atanh(tmp_dFC_DCCX(:, edge_i));
    end
    DEV = std(tmp_dFC, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);% ?
    SP{s,1} = tmp_dFC(pIND, :);% Subsampling
    dFC_result = [dFC_result; tmp_dFC];

    if nargin == 4
        ph.XData = [0, s / N_sub, s / N_sub, 0];
        jindu = sprintf('%.2f',s / N_sub * 100);
        app.ax.Title.String =[ 'Calculating ' methodType ' ' jindu '%...'];
        drawnow
    end
end%s

cd(savedDir)
% transform dFC_result's shape 
% from [N_win*N_sub, size(dFC_result, 2)] ===> [N_win, size(dFC_result, 2), N_sub]
dFC_result1 = reshape(dFC_result, [size(dFC_result, 1) / N_sub, N_sub, size(dFC_result, 2)]);
dFC_result2 = zeros(size(dFC_result, 1) / N_sub, size(dFC_result, 2), N_sub);
for i = 1:size(dFC_result, 1) / N_sub
    dFC_result2(i, :, :) = squeeze(dFC_result1(i, :, :))';
end

%%
% dFC_result3 = zeros(size(dFC_result, 1)/ N_sub, N_roi * N_roi, N_sub);
% for x = 1:N_sub
%     for y = 1:size(dFC_result, 1)/ N_sub % 1:N_win
%         tmp = squeeze(dFC_result2(y, :, x));

%         if isfield(res, "ISA_type") && isequal(res.ISA_type, 'LOO')
%             tmp_state=sf_vec2mat_Asy(N_roi, tmp);
%         else
%             tmp_state=sf_vec2mat(N_roi, tmp);
%             tmp_state=tmp_state+tmp_state';
%         end

%         dFC_result3(y, :, x)
%     end
% end



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
    %write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, [methodType '_' ISA_type])
    save([methodType '_' ISA_type '_all.mat'], 'res', '-v7.3')


else
    %write_3DmatrixROITC_2_2Dmat(dFC_result2, savedDir, fileList, methodType)
    save([methodType '_all.mat'], 'res', '-v7.3')

end


end

