function [vec, IND] = mat2vec_Asym(mat)
% vec = mat2vec(mat)
% returns the full data of mat acccording to rows
% mat should be square

[n,m] = size(mat);

if n ~=m
    error('mat must be square!')
end

vec=zeros(1,n*m);
for i=1:n
   vec(1, (i-1) * m + 1 : m * i)=mat(i,:)' ;
end
% temp = ones(n);
% %% find the indices of the lower triangle of the matrix
% IND = find((temp-triu(temp))>0);
% 
% vec = mat(IND);