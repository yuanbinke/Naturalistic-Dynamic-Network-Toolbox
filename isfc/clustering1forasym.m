clc
clear
% for ISxxx LOO
N_ROI = 50;
N_sub = 5;
TR = 2;
inputDir = 'E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw\ISDCC-Result';
clusterResDir=fullfile([inputDir filesep 'dFC_nozscore_1TR_simu' filesep 'kmeans_elbow_ISDCC_Z']);mkdir(clusterResDir)

% clustering argument
kmeans_max_iter = 150;
dmethod = 'city';
kmeans_num_replicates = 5;
num_tests_est_clusters = 10;

cd(inputDir)
res = importdata('ISDCC_LOO_all.mat');
SP = res.SP;
dFC_result = res.dFC_result;
SPflat = cell2mat(SP);
clear SP;

%% Cluster

cd(clusterResDir)
cluster_estimate_results = icatb_optimal_clusters(SPflat, min([max(size(SPflat)), 10]), 'method', 'elbow', 'cluster_opts', {'Replicates', kmeans_num_replicates, 'Distance', dmethod, ...
    'MaxIter', kmeans_max_iter}, 'num_tests', num_tests_est_clusters, 'display', 1);
close(gcf)
num_clusters = cluster_estimate_results{1}.K(1);

disp(['Number of estimated clusters used in dFNC standard analysis is mean of all tests: ', num2str(num_clusters)]);
fprintf('\n');

[IDXp, Cp, SUMDp, Dp] = kmeans(SPflat, num_clusters, 'distance', dmethod, 'Replicates', kmeans_num_replicates, 'MaxIter', kmeans_max_iter, 'Display', 'iter', 'empty', 'drop');%gift 4.0b

[IDXall, Call, SUMDall, Dall] = kmeans(dFC_result, num_clusters, 'distance', dmethod, 'Replicates', 1, 'Display', 'iter', 'MaxIter', kmeans_max_iter, ...
    'empty', 'drop', 'Start', Cp);

% get K state's min/max val
Tmpmin=zeros(size(Call,1),1);
Tmpmax=zeros(size(Call,1),1);
for i=1:size(Call,1)
    tmp_state=sf_vec2mat_Asy(50,Call(i,:));
    Tmpmin(i)=min(min(tmp_state));
    Tmpmax(i)=max(max(tmp_state));
end
% plot K state figure
for i=1:size(Call,1)
    tmp_state=sf_vec2mat_Asy(50,Call(i,:));
%     tmp_state(eye(50) == 1)=0;
    %             tmp_state=tmp_state+tmp_state';
    figure
    imagesc(tmp_state)
    colormap summer
    colorbar
    caxis([min(Tmpmin), max(Tmpmax)]);
    title(['state0' num2str(i)])
    figurename=fullfile(clusterResDir,['state0' num2str(i) '.jpg'] );
    saveas(gcf,figurename)
    close(gcf)
    figurename2=strcat('state_0', num2str(i), '.mat') ;
    cd(clusterResDir)
    save(figurename2,'tmp_state')
end
%
cd(clusterResDir)
save('IDXall.mat','IDXall') % (nt*nsub) * 1 每一个时间点所属的状态
save('Call.mat','Call'); % k * (nr * (nr-1) / 2)  4个状态的下三角
% save('SUMDall.mat','SUMDall'); % 4个状态的数值总和
% save('Dall.mat','Dall'); % (nt*nsub) * k 每一个时间点距离k个状态的距离
% save('cluster_estimate_results.mat','cluster_estimate_results');
% %% time parameters

labels=IDXall;
%% calulate time
% TR=2;
K=max(labels);
T=length(labels);
T2=T/N_sub;%number of sliding windows
transitionState = reshape(labels, [T2, N_sub])';
