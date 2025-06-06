function [volData, volHead] = NDN_Read(FileName, VolumeIndex)
%function [volData, volHead] = NDN_Read(FileName, VolumeIndex)
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

if isfield(volHead.raw, 'scl_slope')
    scl_slope = volHead.raw.scl_slope;
else
    scl_slope = 1;
end

if isfield(volHead.raw, 'scl_inter')
    scl_inter = volHead.raw.scl_inter;
else
    scl_inter = 0;
end

volData = double((volData .* scl_slope) + scl_inter);

if strcmpi(ext,'.gz')
    delete(FileName);
end


end