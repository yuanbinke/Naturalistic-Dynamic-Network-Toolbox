function [allState, stateTransition] = NDN_kmeans(resMatFile, dmethod, K)
%NDN_KMEANS 可以对dfc的结果进行聚类分析，最终生成K状态和状态转移矩阵
%   此处显示详细说明
% resMatFile = 'E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw\ISDCC-Result\ISDCC_LOO_all.mat';
% dmethod = 'city';
% K = 4;




% clustering argument
kmeans_max_iter = 150;
kmeans_num_replicates = 5;

res = importdata(resMatFile);
SP = res.SP;
dFC_result = res.dFC_result;
SPflat = cell2mat(SP);

N_roi = res.N_roi;
N_sub = res.N_sub;
TR = res.TR;
%% Cluster


[IDXp, Cp, SUMDp, Dp] = kmeans(SPflat, K, 'distance', dmethod, 'Replicates', kmeans_num_replicates, 'MaxIter', kmeans_max_iter, 'Display', 'iter', 'empty', 'drop');%gift 4.0b

[IDXall, Call, SUMDall, Dall] = kmeans(dFC_result, K, 'distance', dmethod, 'Replicates', 1, 'Display', 'iter', 'MaxIter', kmeans_max_iter, ...
    'empty', 'drop', 'Start', Cp);

% get K state's min/max val
statesMin=zeros(size(Call,1),1);
statesMax=zeros(size(Call,1),1);
allState = zeros(N_roi, N_roi, K);
for i=1:K
    if isfield(res, "ISA_type") && isequal(res.ISA_type, 'LOO')
        tmp_state=sf_vec2mat_Asy(N_roi,Call(i,:));
    else
        tmp_state=sf_vec2mat(N_roi,Call(i,:));
        tmp_state=tmp_state+tmp_state';
    end
    allState(:, :, i) = tmp_state;
    statesMin(i)=min(min(tmp_state));
    statesMax(i)=max(max(tmp_state));
end

% for i=1:K
%     tmp_state = squeeze(allState(:, :, i));
%     
%     figure
%     imagesc(tmp_state)
%     colormap summer
%     colorbar
%     caxis([min(statesMin), max(statesMax)]);
%     title(['state0' num2str(i)])
%     figurename=fullfile(clusterResDir,['state0' num2str(i) '.jpg'] );
%     saveas(gcf,figurename)
%     close(gcf)
%     figurename2=strcat('state_0', num2str(i), '.mat') ;
%     cd(clusterResDir)
%     save(figurename2,'tmp_state')
% end

labels=IDXall;

T=length(labels);
T2=T/N_sub;%number of sliding windows
stateTransition = reshape(labels, [T2, N_sub])';
end

