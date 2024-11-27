function yjj_Write(volData, fileName, volHead)
%Format: yjj_Write(volData, fileName, ?volHead)
%YJJ_WRITE Write images as NIfTI files.This function encapsulate niftiwrite() function.
%   yjj_Write(volData, fileName) writes a '.nii' file using the image data, 
%   it creates a 'combined' NIfTI file that contains both metadata 
%   and volumetric data and populates the file metadata using 
%   default values and volume properties like size and data type

%   Recommended: yjj_Write(volData, fileName, volHead) writes a '.nii' file using the image
%   data from volData and metadata from volHead. yjj_Write creates a 'combined'
%   NIFTI file, giving it the file extension '.nii'. If the metadata does
%   not match the image size, yjj_Write will update volHead.ImageSize.
%
%   For more details, please refer to niftiwrite() function's comments.

%     if data type is double, it will be saved as single for space saving
if class(volData) == 'double'
    volData = single(volData);
end

if nargin == 2
    niftiwrite(volData, fileName)
end
if nargin == 3
    volHead.ImageSize = size(volData);
    volHead.PixelDimensions = volHead.PixelDimensions(1:length(volHead.ImageSize));
    volHead.Datatype = class(volData);
    niftiwrite(volData, fileName, volHead)
end
% niftiwrite(varargin{:})
end
