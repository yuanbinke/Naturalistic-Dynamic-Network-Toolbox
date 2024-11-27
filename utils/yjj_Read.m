function [volData, volHead] = yjj_Read(FileName, VolumeIndex)
%function [volData, volHead] = yjj_Read(FileName, VolumeIndex)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if ~exist(FileName,'file')
    error(['File doesn''t exist: ' FileName]);
end

[pathstr, name, ext] = fileparts(FileName);

if strcmpi(ext,'.gz')
    gunzip(FileName);
    FileName = fullfile(pathstr,[name]);
end

volHead = niftiinfo(FileName);
volData = niftiread(volHead);

if nargin == 2
    if VolumeIndex > size(volData, 4)
        error(['VolumeIndex' VolumeIndex 'out of range']);
    else
        volData = volData(:, : , :, VolumeIndex);
    end
end

volData = double(volData);

if strcmpi(ext,'.gz')
    delete(FileName);
end


end