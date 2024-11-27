function mat=sf_vec2mat_Asy(V,vec)
vec=vec(:);
mat=zeros(V,V);
k=0;
for i=1:V
        mat(i,:)=vec((i-1)*V+1:i*V);
end

% temp=ones(V);
% IND = find((temp-triu(temp))>0);
% 
% vec2 = mat(IND);
% if ~isequal(vec,vec2)
%     error('Error: vector size does not match, please check')
% end
end