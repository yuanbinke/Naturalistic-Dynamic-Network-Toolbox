function K = NDN_bestK(resMatFile, dmethod)
%NDN_BESTK 可以得到DFC结果的best k，并且返回出去resMatFile, clusterResDir
% resMatFile 是 NDN_TB step 2 跑出来的mat文件, 其文件名字以_all.mat结尾
% clusterResDir
%% arguments
% resMatFile = 'E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw\ISDCC-Result\ISDCC_LOO_all.mat';
% dmethod = 'city';
% clusterResDir = [fileparts(resMatFile) filesep 'clusterResDir'];
% if ~exist(clusterResDir)
%     mkdir(clusterResDir)
% end

%% clustering arguments
kmeans_max_iter = 150;

kmeans_num_replicates = 5;
num_tests_est_clusters = 10;

res = importdata(resMatFile);
SP = res.SP;
dFC_result = res.dFC_result;
SPflat = cell2mat(SP);
cluster_estimate_results = icatb_optimal_clusters(SPflat, min([max(size(SPflat)), 10]), 'method', 'elbow', 'cluster_opts', {'Replicates', kmeans_num_replicates, 'Distance', dmethod, ...
    'MaxIter', kmeans_max_iter}, 'num_tests', num_tests_est_clusters, 'display', 1);
close(gcf)
K = cluster_estimate_results{1}.K(1);
end

