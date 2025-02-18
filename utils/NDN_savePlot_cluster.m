function NDN_savePlot_cluster(app, resMatFile, savedDir)
%NDN_SAVEPLOT_CLUSTER

if ~exist(savedDir, "dir")
    mkdir(savedDir)
end
%% get info
[~, filename] = fileparts(resMatFile);
prefix = strrep(filename, '_all', '');
res = importdata(resMatFile);
TR = res.TR;
stateTransition = app.stateTransition;
nT = size(stateTransition, 2);
nSub = size(stateTransition, 1);
K = app.K;
allState = app.allState;
colors = [
    65, 3, 84; 
    34, 137, 139; 
    254, 255, 13; 
    ] / 255;

positions = [ 0, 1/2, 1];
gradientColors = interp1(positions, colors, linspace(0, 1, 1000));
%% save stateTransition
imagesc(stateTransition);
custom_cm = cbrewer('qual','Set1',K);
colormap((custom_cm));
set(gca, 'FontName','Arial','FontSize',25,'LineWidth', 1.5);
xlim([0 nT])
xlabel(gca,'Time [s]','FontSize',36);
ylabel(gca,'Subjects','FontSize',36);
caxis([1,K + 1]);
set(gcf,'Position',[100 100 1920*0.6 1080*0.4]);

span = floor((nT / 4));
xticks([0:span:(nT  - span), floor(nT)])
xticklabels(floor([0:span:(nT  - span), floor(nT)].*TR));


% if nSub < 4
%     yticks(0:1:nSub);
% end

set(gca,'tickdir','in');

filename=[savedDir filesep prefix '_stateTransition'];
print(1,'-dtiff','-r300',filename);
close(1)
cd(savedDir)
save([savedDir filesep  prefix '_stateTransition.mat'], "stateTransition");

%% save states
% plot K state figure
for i=1:K
    tmp_state = squeeze(allState(:,:,i));
    tmp_state_normalized = normalize(tmp_state, 'range', [-1, 1]);
    figure
    imagesc(tmp_state_normalized)
    colormap(gradientColors)
    colorbar
    caxis([min(tmp_state_normalized(:)), max(tmp_state_normalized(:))])
    title(['state0' num2str(i)])

    nROI = size(tmp_state_normalized, 1);
    span = floor(nROI / 4);

    xticks([1:span:(nROI  - span), floor(nROI)])
    xticklabels(floor([0:span:(nROI  - span), floor(nROI)]));
    yticks([0:span:(nROI  - span), floor(nROI)])
    yticklabels(floor([0:span:(nROI  - span), floor(nROI)]));

    % save as tif
    state_i_tif_name = fullfile(savedDir, [prefix '_state0' num2str(i) '.tif'] );
    print(gcf, '-dtiff', '-r300', state_i_tif_name);
    close(gcf)
    % save as mat
    state_i_mat_name = fullfile(savedDir, [prefix '_state0' num2str(i) '.mat'] ) ;
    save(state_i_mat_name, 'tmp_state')
end

%% stateFrequency
figure
stateFrequency = histcounts(stateTransition(:), 1:5) / numel(stateTransition);
bar(stateFrequency, 0.5);
ylim([0, max(stateFrequency) + 0.2]);
title('Overall State Frequency')
set(gca,'XTick',[1,2,3 4],'XTickLabel',{'S1','S2','S3','S4'})

% save as tif
stateFrequency_tif_name = fullfile(savedDir, [prefix '_stateFrequency.tif'] );
print(gcf, '-dtiff', '-r300', stateFrequency_tif_name);
close(gcf)
% save as mat
stateFrequency_mat_name = fullfile(savedDir, [prefix '_stateFrequency.mat'] );
save(stateFrequency_mat_name, 'stateFrequency')

%% Transition probability
states = unique(stateTransition); % 获取唯一的状态值
n = length(states);    % 状态数量

% 初始化转换矩阵
state_to_state = zeros(n, n);

% 遍历序列，统计状态转换
for s = 1:nSub
    for i = 1:nT-1
        current_state = stateTransition(s, i);      % 当前状态
        next_state = stateTransition(s, i+1);       % 下一个状态
        % 在转换矩阵中累加计数
        state_to_state(current_state, next_state) = state_to_state(current_state, next_state) + 1;
    end
end

figure
imagesc(state_to_state)
colormap(flipud(gray));
colorbar

textStrings = num2str(state_to_state(:), '%0.2f');       % Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  % Remove any space padding
[x, y] = meshgrid(1:size(state_to_state,1));  % Create x and y coordinates for the strings
hStrings = text(x(:), y(:), textStrings(:), ...  % Plot the strings
    'HorizontalAlignment', 'center','FontSize',18);

midValue = mean(get(gca, 'CLim'));
textColors = repmat(state_to_state(:) > midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));
for s = 1:K
    TickLabel{s} = sprintf('S%02d', s);
end
set(gca, 'XTick', 1:K,'XTickLabel', TickLabel, ...
    'YTick', 1:K, 'YTickLabel', TickLabel, ...
    'TickLength', [0 0]);
set(gca, 'FontName','Arial','FontSize', 14,'LineWidth', 2.5);
title('Transition Probability between States')

% save as tif
transitionProbability_tif_name = fullfile(savedDir, [prefix '_transitionProbability.tif'] );
print(gcf, '-dtiff', '-r300', transitionProbability_tif_name);
close(gcf)
% save as mat
transitionProbability_mat_name = fullfile(savedDir, [prefix '_transitionProbability.mat'] );
save(transitionProbability_mat_name, 'state_to_state')

%% state Series Correlation
correlation_matrix = corrcoef(stateTransition');
figure;
imagesc(correlation_matrix);
colormap(jet);
caxis([-1 1]); 
colorbar;
title('Subject State Series Correlation');
set(gca, 'FontName','Arial','FontSize', 12);

% save as tif
stateSeriesCorrelation_tif_name = fullfile(savedDir, [prefix '_stateSeriesCorrelation.tif'] );
print(gcf, '-dtiff', '-r300', stateSeriesCorrelation_tif_name);
close(gcf)
% save as mat
stateSeriesCorrelation_mat_name = fullfile(savedDir, [prefix 'stateSeriesCorrelation.mat'] );
save(stateSeriesCorrelation_mat_name, 'correlation_matrix')

end

