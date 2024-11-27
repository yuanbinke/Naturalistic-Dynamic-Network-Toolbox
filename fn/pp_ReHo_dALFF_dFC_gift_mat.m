function [dFC_result]=pp_ReHo_dALFF_dFC_gift_mat(timecourses,method,TR,wsize)
% calculation of dynamic ALFF for single subject

%input
%time course is the T*C matrix, where T is the number of time poinst and C is the
%number of components or ROIs


%output:
%result_matrix is the W*C matrix, where W is the number of windows and C is the
%number of components


V=size(timecourses,2);
nT=size(timecourses,1);
window_alpha=3;
%wsize=20;
doDespike='yes';
tc_filter=0.15;
num_repetitions = 10;
%TR=2;
detrendNumber=3;
initial_lambdas = (0.1:.03:.40);



%%
%window generation

c = compute_sliding_window(nT, window_alpha, wsize);
A = repmat(c, 1, V);

Nwin = nT - wsize;



%%
%preprocessing 
if (strcmpi(doDespike, 'yes'))&&(tc_filter > 0)
    timecourses = icatb_detrend(timecourses, 1, [], detrendNumber);
    for i=1:V
        current_tc=timecourses(:,i);
        if any(current_tc)
        current_tc = icatb_despike_tc(current_tc, TR);
        current_tc = icatb_filt_data(current_tc, TR, tc_filter);
        tc(:,i)=current_tc;
        end
    end
   
end
tc(isnan(tc))=0;


%%
%window the data and calculate SD
tcwin = zeros(Nwin, nT, V);
for ii = 1:Nwin
    Ashift = circshift(A, round(-nT/2) + round(wsize/2) + ii);
    tmp= tc.*Ashift;    
    tcwin(ii, :, :)=tmp;
end
tcwin(isnan(tcwin))=0;
tcwintmp=tcwin(:,:,1:8:end);
if strcmpi(method, 'L1')
    useMEX = 0;
    try
        GraphicalLassoPath([1, 0; 0, 1], 0.1);
        useMEX = 1;
    catch
    end
    disp('Using L1 regularisation ...');
    %% L1 regularisation
    Pdyn = zeros(Nwin, V*(V - 1)/2);
    fprintf('\t rep ')
    %% Loop over no of repetitions
    for r = 1:num_repetitions
        fprintf('%d, ', r)
        [trainTC, testTC] = split_timewindows(tcwintmp, 1);
        trainTC = icatb_zscore(trainTC);
        testTC = icatb_zscore(testTC);
        trainTC(isnan(trainTC))=0;
        testTC(isnan(testTC))=0;
        [wList, thetaList] = computeGlasso(trainTC, initial_lambdas, useMEX);
        obs_cov = icatb_cov(testTC);
        L = cov_likelihood(obs_cov, thetaList);
        Lambdas(r, :) = L;
    end
    
    fprintf('\n')
    [mv, minIND] =min(Lambdas, [], 2);
    blambda = mean(initial_lambdas(minIND));
    fprintf('\tBest Lambda: %0.3f\n', blambda)
    
    
    % now actually compute the covariance matrix
    fprintf('\tWorking on estimating covariance matrix for each time window...\n')
    for ii = 1:Nwin
        %fprintf('\tWorking on window %d of %d\n', ii, Nwin)
        tmpp=icatb_zscore(squeeze(tcwin(ii, :, :)));
        tmpp(isnan(tmpp))=0;
        [wList, thetaList] = computeGlasso(tmpp, blambda, useMEX);
        a = icatb_corrcov(wList);
        a(isnan(a))=0;
        a = a - eye(V);
%         FNCdyn(ii, :) = mat2vec(a);
        FNCdyn(:,:,ii) = a;
        InvC = -thetaList;
        r = (InvC ./ repmat(sqrt(abs(diag(InvC))), 1, V)) ./ repmat(sqrt(abs(diag(InvC)))', V, 1);
        r = r + eye(V);
        r(isnan(r))=0;
        Pdyn(ii, :) = mat2vec(r);
%         dALFF_result(:,ii)=ALFF_onetimeseries(squeeze(tcwin(ii, :, :)),TR,0.15,0.025)';
    end
    FNCdyn = atanh(FNCdyn);
    
% elseif strcmpi(method, 'none')
%     %% No L1
%     for ii = 1:Nwin
%         a = icatb_corr(squeeze(tcwin(ii, :, :)));
%         FNCdyn(ii, :) = mat2vec(a);
%         dALFF_result(:,ii)=ALFF_onetimeseries(squeeze(tcwin(ii, :, :)),TR,0.15,0.025)';
%         FNCdyn(isnan(FNCdyn))=0;
%     end
%     FNCdyn = atanh(FNCdyn);
end
dFC_result=FNCdyn;
% dALFF_result=dALFF_result';



%%
%subfunctions
function c = compute_sliding_window(nT, win_alpha, wsize)
%% Compute sliding window
%

nT1 = nT;
if mod(nT, 2) ~= 0
    nT = nT + 1;
end

m = nT/2;
w = round(wsize/2);
%if (strcmpi(win_type, 'tukey'))
%    gw = icatb_tukeywin(nT, win_alpha);
%else
gw = gaussianwindow(nT, m, win_alpha);
%end
b = zeros(nT, 1);  b((m -w + 1):(m+w)) = 1;
c = conv(gw, b); c = c/max(c); c = c(m+1:end-m+1);
c = c(1:nT1);


function [vec, IND] = mat2vec(mat)
% vec = mat2vec(mat)
% returns the lower triangle of mat
% mat should be square

[n,m] = size(mat);

if n ~=m
    error('mat must be square!')
end


temp = ones(n);
%% find the indices of the lower triangle of the matrix
IND = find((temp-triu(temp))>0);

vec = mat(IND);


% function w = gaussianwindow(N,x0,sigma)
%
% x = 0:N-1;
% w = exp(- ((x-x0).^2)/ (2 * sigma * sigma))';


function L = cov_likelihood(obs_cov, theta)
% L = cov_likelihood(obs_cov, sigma)
% INPUT:
% obs_cov is the observed covariance matrix
% theta is the model precision matrix (inverse covariance matrix)
% theta can be [N x N x p], where p lambdas were used
% OUTPUT:
% L is the negative log-likelihood of observing the data under the model
% which we would like to minimize

nmodels = size(theta,3);

L = zeros(1,nmodels);
for ii = 1:nmodels
    % log likelihood
    theta_ii = squeeze(theta(:,:,ii));
    L(ii) = -log(det(theta_ii)) + trace(theta_ii*obs_cov);
end

function [trainTC, testTC] = split_timewindows(TCwin, ntrain)
%[Nwin, nT, nC] = size(TCwin);


[Nwin, nT, nC] = size(TCwin);

r = randperm(Nwin);
trainTC = TCwin(r(1:ntrain),:,:);
testTC = TCwin(r(ntrain+1:end),:,:);

trainTC = reshape(trainTC, ntrain*nT, nC);
testTC = reshape(testTC, (Nwin-ntrain)*nT, nC);


function w = gaussianwindow(N,x0,sigma)

x = 0:N-1;
w = exp(- ((x-x0).^2)/ (2 * sigma * sigma))';


function [wList, thetaList] = computeGlasso(tc, initial_lambdas, useMEX)
%% Compute graphical lasso


if (useMEX == 1)
    [wList, thetaList] = GraphicalLassoPath(tc, initial_lambdas);
else
    tol = 1e-4;
    maxIter = 1e4;
    S = icatb_cov(tc);
    thetaList = zeros(size(S, 1), size(S, 2), length(initial_lambdas));
    wList = thetaList;
    
    for nL = 1:size(wList, 3)
        [thetaList(:, :, nL), wList(:, :, nL)] = icatb_graphicalLasso(S, initial_lambdas(nL), maxIter, tol);
    end
    
end


function tc = getTruncatedTcs(tcs, nT)


numOfSub = size(tcs, 1);
numOfSess = size(tcs, 2);
numComp = size(tcs{1,1}, 2);
tc = zeros(numOfSub, numOfSess, nT, numComp);

%% Loop over subjects
for nSub = 1:numOfSub
    %% Loop over sessions
    for nSess = 1:numOfSess
        tmp = tcs{nSub, nSess};
        tmp = squeeze(tmp);
        tp = size(tmp, 1);
        if (tp ~= nT)
            interpFactor = nT/tp;
            [num, denom] = rat(interpFactor);
            tmp = resample(tmp, num, denom);
        end
        tc(nSub, nSess, :, :) = tmp;
    end
end