function mat=sf_vec2mat(V,vec)
%将对一个n*n的称矩阵的一维形式 => n * n对称矩阵的二维形式
vec=vec(:);
mat=zeros(V,V);
k=0;
for i=1:(V-1)
    for j=(i+1):V
        k=k+1;
        mat(j,i)=vec(k);
    end
end

temp=ones(V);
IND = find((temp-triu(temp))>0);

vec2 = mat(IND);

tmp = vec;
tmp(isnan(tmp)) = 0;

tmp2 = vec2;
tmp2(isnan(tmp2)) = 0;

if ~isequal(tmp, tmp2)
    error('Error: vector size does not match, please check')
end
end