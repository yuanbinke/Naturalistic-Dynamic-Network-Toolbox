function  NDN_plotting(app, resMatFile)
%NDN_PLOTTING 此处显示有关此函数的摘要app, resMatFile
%   此处显示详细说明
% NDN_plotting(Cluster_Plotting_app
% resMatFile = 'H:\paranoia\allRun\data\ROITC\default\old\test\DCC_all.mat';
%% get infos
res = importdata(resMatFile);
TR = res.TR;
stateTransition = app.stateTransition;
nT = size(stateTransition, 2);
nSub = size(stateTransition, 1);
K = app.K;
for s = 1:K
    TickLabel{s} = sprintf('S%d', s);
end

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
app.UIAxes.Title.String = "State transition";
for i = 1:K
    app.(['State' num2str(i) 'Label']).FontColor = custom_cm(i, :);
    app.(['State' num2str(i) 'Label']).Visible = 'on';
end

%% plotting states

NDN_plottingStates(app, resMatFile)

%% plotting stateFrequency
stateFrequency = histcounts(stateTransition(:), 1:K+1) / numel(stateTransition);
bar(app.UIAxes3_1, stateFrequency);


app.UIAxes3_1.YLim = [0, max(stateFrequency) + 0.1];
app.UIAxes3_1.XLim = [0.5, K + 0.5];
app.UIAxes3_1.XTick = 1:1:K;
app.UIAxes3_1.XTickLabel = TickLabel;
app.UIAxes3_1.Title.String = "State ratio";

app.UIAxes3_1.Visible = 'on';

app.UIAxes3_1.YAxis.Visible = 'on';
app.UIAxes3_1.XAxis.Visible = 'on';
app.UIAxes3_1.Title.Visible = 'on';

%% 
%% plotting Transition probability
state_to_state = zeros(K, K);
for s = 1:nSub
    for i = 1:nT-1
        current_state = stateTransition(s, i);    
        next_state = stateTransition(s, i+1);       
        state_to_state(current_state, next_state) = state_to_state(current_state, next_state) + 1;
    end
end

imagesc(app.UIAxes3_2, state_to_state)
app.UIAxes3_2.Colormap = flipud(gray);

textStrings = num2str(state_to_state(:), '%0.2f');       % Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  % Remove any space padding
fontSize = max(12 - K, 3);
[x, y] = meshgrid(1:size(state_to_state,1));  % Create x and y coordinates for the strings
hStrings = text(app.UIAxes3_2, x(:), y(:), textStrings(:), ...  % Plot the strings
    'HorizontalAlignment', 'center','FontSize', fontSize);

midValue = mean(state_to_state(:));
textColors = repmat(state_to_state(:) > midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));

app.UIAxes3_2.XLim = [0.5, K + 0.5];
app.UIAxes3_2.YLim = [0.5, K + 0.5];
app.UIAxes3_2.XTick = 1:1:K;
app.UIAxes3_2.YTick = 1:1:K;
app.UIAxes3_2.XTickLabel = TickLabel;
app.UIAxes3_2.YTickLabel = TickLabel;
app.UIAxes3_2.TickLength = [0 0];
app.UIAxes3_2.Title.String = "Transition probability between states";

app.UIAxes3_2.Visible = 'on';

app.UIAxes3_2.YAxis.Visible = 'on';
app.UIAxes3_2.XAxis.Visible = 'on';
app.UIAxes3_2.Title.Visible = 'on';

cbar = colorbar(app.UIAxes3_2);
app.cbar.UIAxes3_2 = cbar;
%% plotting correlation matrix
correlation_matrix = corrcoef(stateTransition');
imagesc(app.UIAxes3_3, correlation_matrix);
myJet = importdata("myJet.mat");
app.UIAxes3_3.Colormap = myJet;
app.UIAxes3_3.CLim = [-1 1];

app.UIAxes3_3.XLim = [0.5, nSub+0.5];
app.UIAxes3_3.YLim = [0.5, nSub+0.5];


app.UIAxes3_3.Title.String = "Subjects correlation";
app.UIAxes3_3.YAxis.Visible = 'off';
app.UIAxes3_3.XAxis.Visible = 'off';
app.UIAxes3_3.Title.Visible = 'on';
if nSub > 5
    span = floor(nSub / 3);
    app.UIAxes3_3.YTick = [0:span:(nSub - 1  - span), floor(nSub - 1)] +0.5;
    app.UIAxes3_3.YTickLabel = [0:span:(nSub - 1  - span), floor(nSub - 1)] + 1;
    app.UIAxes3_3.XTick = [0:span:(nSub - 1  - span), floor(nSub - 1)] +0.5;
    app.UIAxes3_3.XTickLabel = [0:span:(nSub - 1  - span), floor(nSub - 1)] + 1;
else
    span = 0:nSub-1;
    app.UIAxes3_3.YTick = span + 0.5;
    app.UIAxes3_3.YTickLabel = span + 1;
end



app.UIAxes3_3.XAxis.Visible = 'on';
app.UIAxes3_3.YAxis.Visible = 'on';
cbar = colorbar(app.UIAxes3_3);
app.cbar.UIAxes3_3 = cbar;
end

