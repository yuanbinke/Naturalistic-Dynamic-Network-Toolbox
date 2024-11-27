function initializeProgress(app, position)
%INITIALIZEPROGRESS can intialize a uiaxes object as a progress bar
% Input:
% app           - a uifigure object
% position      - a 1*4 matrix [left, bottom, width, height], an optional
%                 argument, represent the position of the uiaxes object
%

if nargin == 1
    position = [108,22,521,35];
end
propList = properties(app);
app.ax = uiaxes(app.(propList{1}), 'Position', position, 'XTick', [], 'YTick', [],...
    'Color', [1, 1, 1], 'XLim', [0, 1], "YLim", [0 1]);
app.ax.Title.String = "Initializing";
app.ax.Visible = 'off';
try
    app.ax.Toolbar.Visible = 'off';
catch
end
app.ax.XColor = [0.94, 0.94, 0.94];
app.ax.YColor = [0.94, 0.94, 0.94];
app.ax.HitTest = 'off';
app.isCreateAx = true;
app.ProgrssBarLabel.Visible = 'off';


end

