function useViewInitialization(app)
%useViewInitialization 初始化mlapp的初始位置，让他居中

% get UIFigure Name
allFields = fieldnames(app);
uiFigureFields = allFields(endsWith(allFields, 'UIFigure'));
if numel(uiFigureFields) ~= 0
    figName = uiFigureFields{1};
else
    disp("Attribute ending with 'UIFigure' could not be found")
    return
end

% get screen's Info
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);

% get windowWidth windowHeight
position = app.(figName).Position;
windowWidth = position(3);
windowHeight = position(4);

% calculate
left = (screenWidth - windowWidth)/2;
bottom = 3 * (screenHeight - windowHeight)/4;


% set
app.(figName).Position = [left, bottom, windowWidth, windowHeight];



end

