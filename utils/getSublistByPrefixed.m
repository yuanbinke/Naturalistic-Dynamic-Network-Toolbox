function [sublist] = getSublistByPrefixed(inputdir, prefix)
cd(inputdir);
if isempty(prefix) || nargin == 1
    sublist = [];
    return
end
if isequal(prefix, '*')
    sublist = dir('*');
    sublist = sublist(3:end);
else
    if prefix(end) == '*'
        sublist = dir(prefix);
    else
        sublist = dir([prefix '*']);
    end
end
end

