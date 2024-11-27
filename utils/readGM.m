function [d_GM, dR_GM, h_GM] = readGM(grayMatterMask)
%readGM can Read greyMatter mask, and return the 3dim and 1dim data
% Input:
%   1): grayMatterMask - the filename of the image
%   Output:
%   1): d_GM - 3D data of the grayMatterMask
%   2): dR_GM - reshape the 3D data(imageDim(1), imageDim(2), imageDim(3))
%       to the shape like (imageDim(1) * imageDim(2) * imageDim(3), 1)
%   3): h_GM - head info of the grayMatterMask file.

[d_GM, h_GM] = yjj_Read(grayMatterMask);
imageDim = h_GM.ImageSize;
dR_GM = reshape(d_GM,imageDim(1)*imageDim(2)*imageDim(3),1);
end
