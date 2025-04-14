function subDataAfterRemoveCov = NDN_regressLOO(subData, LOO_mean)
%NDN_REGRESSLOO Perform regression analysis between the time series of all 
% voxels of a subData and the time series of the LOO_mean.
%NDN_REGRESSLOO 让一个被试的所有体素的时间序列和LOO_mean的时间序列进行回归
%   此处显示详细说明
nTime = size(subData, 1);
nROI = size(subData, 2);

for i=1:nROI
    fprintf('.');

    if sum(subData(:, i)) && sum(LOO_mean(:, i))

        DependentVariable = squeeze(subData(:, i));
        ImgCovTemp = squeeze(LOO_mean(:, i));
        ImgCovTemp = ImgCovTemp - repmat(mean(ImgCovTemp), size(ImgCovTemp,1), 1);% Demean.
        ImgCovTemp = [ones(size(ImgCovTemp,1),1), ImgCovTemp];
        % regress
        [b,r] = NDN_regress_ss(DependentVariable, ImgCovTemp);

        subDataAfterRemoveCov(:, i) = DependentVariable-r;
        MeanBrain(i)=b(1);

    end
end

subDataAfterRemoveCov(isnan(subDataAfterRemoveCov))=0;

% subDataAfterRemoveCov = subDataAfterRemoveCov + repmat(MeanBrain,[nTime, 1]); %%Add the mean back.


end

