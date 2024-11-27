function NDN_savePlot_cluster(app, resMatFile, savedDir)
%NDN_SAVEPLOT_CLUSTER 此处显示有关此函数的摘要
%   此处显示详细说明
if ~exist(savedDir, "dir")
    mkdir(savedDir)
end
%% get info
res = importdata(resMatFile);
TR = res.TR;
stateTransition = app.stateTransition;
nT = size(stateTransition, 2);
nSub = size(stateTransition, 1);
K = app.K;
allState = app.allState;
colors = [
    65, 3, 84; % 中间颜色3
    34, 137, 139; % 中间颜色2
    254, 255, 13; % 结束颜色
    ] / 255;
% 定义渐变的位�?
positions = [ 0, 1/2, 1];
% 生成渐变�?
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

filename=[savedDir filesep  'stateTransition'];
print(1,'-dtiff','-r300',filename);
close(1)
cd(savedDir)
save([savedDir filesep  'stateTransition.mat'], "stateTransition");

%% save states
% plot K state figure
for i=1:K
    tmp_state = squeeze(allState(:,:,i));
    figure
    imagesc(tmp_state)
    colormap(gradientColors)
    colorbar
    caxis([min(tmp_state(:)), max(tmp_state(:))])
    title(['state0' num2str(i)])

    nROI = size(tmp_state, 1);
    span = floor(nROI / 4);

    xticks([1:span:(nROI  - span), floor(nROI)])
    xticklabels(floor([0:span:(nROI  - span), floor(nROI)]));
    yticks([0:span:(nROI  - span), floor(nROI)])
    yticklabels(floor([0:span:(nROI  - span), floor(nROI)]));

    % 保存为tif
    state_i_tif_name = fullfile(savedDir,['state0' num2str(i) '.tif'] );
    print(gcf, '-dtiff', '-r300', state_i_tif_name);
    close(gcf)
    % 保存为mat
    state_i_mat_name = fullfile(savedDir,['state0' num2str(i) '.mat'] ) ;
    save(state_i_mat_name, 'tmp_state')
end
end

