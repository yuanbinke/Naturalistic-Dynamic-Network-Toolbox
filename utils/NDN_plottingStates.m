function NDN_plottingStates(app, resMatFile)
%NDN_PLOTTINGSTATES 生成每一页的状态
%   此处显示详细说明
%% get infos
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
% 定义渐变的位置
positions = [ 0, 1/2, 1];
% 生成渐变色
gradientColors = interp1(positions, colors, linspace(0, 1, 1000));
%% plotting
minIndex = (app.curPage - 1) * 4 + 1;
maxIndex = min(K, app.curPage * 4);
count = 1;
for i=minIndex : maxIndex
    % 关闭4个状态的UIAxes对象的坐标轴
    app.(['UIAxes2_' num2str(count)]).XColor = 'none';
    app.(['UIAxes2_' num2str(count)]).YColor = 'none';

    ii = sprintf('%02d', i);
    app.(['UIAxes2_' num2str(count)]).Visible = "on";
    tmp_state = squeeze(allState(:, :, i));
    
    app.(['UIAxes2_' num2str(count)]).XLim = [0 size(tmp_state, 1)];
    app.(['UIAxes2_' num2str(count)]).YLim = [0 size(tmp_state, 1)];
    imagesc(app.(['UIAxes2_' num2str(count)]), tmp_state);
    app.(['UIAxes2_' num2str(count)]).Colormap = gradientColors;
    app.(['UIAxes2_' num2str(count)]).Title.String = ['state ' num2str(ii)];
    axis(app.(['UIAxes2_' num2str(count)]), 'off');
    count = count + 1;
end
end

