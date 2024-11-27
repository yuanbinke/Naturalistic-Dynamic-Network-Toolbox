function  NDN_plotting(app, resMatFile)
%NDN_PLOTTING 此处显示有关此函数的摘要
%   此处显示详细说明
% resMatFile = 'E:\yjj\scnu_work\matlab_APP\data\sfc\data\ROI_mat\raw\ISDCC-Result\ISDCC_LOO_all.mat';
% app = Cluster_Plotting_app;
%% get infos
res = importdata(resMatFile);
TR = res.TR;
stateTransition = app.stateTransition;
nT = size(stateTransition, 2);
nSub = size(stateTransition, 1);
K = app.K;

%% plotting state transition 
imagesc(app.UIAxes, stateTransition);
app.UIAxes.Visible = 'on';
custom_cm = cbrewer('qual','Set1',K);
app.UIAxes.Colormap = custom_cm;
app.UIAxes.XLim = [0 nT];
app.UIAxes.YLim = [0.5 nSub + 0.5];
app.UIAxes.XLabel.String = 'Time [s]';
app.UIAxes.YLabel.String = 'Subjects';
app.UIAxes.CLim = ([1,K + 1]);
span = floor(nT / 4);
app.UIAxes.XTick = [0:span:(nT  - span), floor(nT)];
app.UIAxes.XTickLabel = floor([0:span:(nT  - span), floor(nT)].*TR);
app.UIAxes.Title.String = "State Transition";



for i = 1:K
    app.(['State' num2str(i) 'Label']).FontColor = custom_cm(i, :);
    app.(['State' num2str(i) 'Label']).Visible = 'on';
end

%% plotting states

NDN_plottingStates(app, resMatFile)


end

