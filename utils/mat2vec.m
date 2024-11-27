function [vec, IND] = mat2vec(mat)
% vec = mat2vec(mat)
% returns the lower triangle of mat
% mat should be square

[n,m] = size(mat);

if n ~=m
    error('mat must be square!')
end


temp = ones(n);
%% find the indices of the lower triangle of the matrix
IND = find((temp-triu(temp))>0);

vec = mat(IND);