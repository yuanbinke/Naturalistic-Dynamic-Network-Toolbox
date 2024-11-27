function [flag] = yjj_isUiobjNull(app, types)
%YJJ_IS_UIOBJ_NOTNULL can determine whether the EditField on the interface
% is empty
%
%INPUT:
% app               - a uiobject
% types             - a string array and an optional argument, ["EditField"]
%                   is default value of types. 
%OUTPUT:
% flag              - 0 represent all EditField in app have been assgined
%                   with a value, 1 represent the value of some EditFields
%                   is null
propNames = properties(app);
if nargin == 1
    types = ["EditField"];
end
for i = 1:numel(propNames)
    for j = 1:numel(types)
        type = char(types{j});
        strs = strsplit(class(app.(propNames{i})), '.');

        if isequal(strs{end}, type) && isempty(app.(propNames{i}).Value) && ~startsWith(propNames{i}, 'n_')

            objName = strrep(propNames{i}, 'EditField', '');
            objName = strrep(objName, 'e_', '');
            if isequal(propNames{i}, 'subdirPrefixEditField')
                msg = ['The value of this EditField should not be empty.' ...
                    ' Please assign a new value.For example, you can type ' ...
                    '"sub" if the target directorys with a prefix "sub" '];
                title = ['Please assign a value for' objName];
                msgbox(msg, title, 'warn')
                flag = 1;
                return 
            else

                msg = ['The value of ' objName ' should not be empty. Please assign a new value.'];
                title =  ['Please assign a value for' objName];
                msgbox(msg, title, 'warn')
                flag = 1;
                return 
            end


        end
    end
end
flag = 0;

end
