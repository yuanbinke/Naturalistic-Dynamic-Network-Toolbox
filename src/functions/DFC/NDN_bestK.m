function K = NDN_bestK(resMatFile, dmethod)
%NDN_BESTK calculates the best K of DFC result
% resMatFile        - The mat file generated by NaDyNet with a filename
%                     ending with _all.mat
% dmethod 
%          'sqeuclidean'  - Squared Euclidean distance.
%          'cityblock'    - Sum of absolute differences, a.k.a. L1 distance
%          'cosine'       - One minus the cosine of the included angle
%                           between points (treated as vectors).
%          'correlation'  - One minus the sample correlation between points
%                           (treated as sequences of values).
%          'hamming'      - Percentage of bits that differ (only suitable
%                           for binary data).

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

