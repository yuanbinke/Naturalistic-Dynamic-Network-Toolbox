function mat = NDN_vec2mat(vec, n)
%NDN_VEC2MAT converts a (n-1)n/2 vector into an nn matrix 'mat' with its
% lower triangular part populated by the vector elements. Additionally,
% 'mat' is made symmetric with its diagonal elements set to 1.
%
%NDN_VEC2MAT 将一个 (n-1)*n/2 向量转化为 n*n矩阵mat的下三角,  并且mat成为一
% 个对称的矩阵，对角线为1
%Input:
% vec           - a (n-1)n/2 vector
% n             - a double, represent the size of the matrix
%Output:
% mat           - The matrix 'mat' is a symmetric matrix, with its lower
% triangular part populated by the contents of 'vec', and the diagonal
% elements are set to one.

temp=ones(n);
IND = find((temp-triu(temp))>0);
mat = zeros(n, n);
vec = vec(:);
if length(vec) ~= (n-1)*n/2
    error("he size of the input vector 'vec' does not correspond to the given 'n'.")
end
mat(IND) = vec;
mat = mat + mat' + eye(n);
end

