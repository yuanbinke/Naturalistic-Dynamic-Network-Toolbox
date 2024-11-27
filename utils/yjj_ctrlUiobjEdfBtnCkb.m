function yjj_ctrlUiobjEdfBtnCkb(app, action)
%YJJ_OFFUIOBJEDFBTN Control the editable state of the editField, buttons
%and checkbox of the 'app'
%
%
%INPUT:
% app               - a uiobject
% action            - a string, controls the type of action to perform,
%                   specified as one of the following strings:
%                       - 'on': Executes the operation and enables the
%                       editField and buttons for editing.
%                       - 'off': Executes the operation but disables the
%                       editField and buttons, making them non-editable.
%


propNames = properties(app);
for i = 1:numel(propNames)

    strs = strsplit(class(app.(propNames{i})), '.');

    if isequal(strs{end}, 'EditField') && ~startsWith(propNames{i}, 'e_')
        app.(propNames{i}).Editable = action;
    end

    if isequal(strs{end}, 'Button')
        app.(propNames{i}).Enable = action;
    end

    if isequal(strs{end}, 'CheckBox')
        app.(propNames{i}).Enable = action;
    end
end



end


