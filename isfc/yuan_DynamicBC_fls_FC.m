function Matrix = yuan_DynamicBC_fls_FC(ROI_sig,mu)
[nobs,nvar] = size(ROI_sig);
ROI_sig = zscore(ROI_sig);

beta = zeros(nvar,nvar,nobs); % FC
Matrix=zeros(nvar,nvar,nobs);
for k=1:nvar
    betak = zeros(nvar,nobs);
    for j=1:nvar
        %             fprintf('.')
        if j~=k
            betak(j,:) = wgr_fls(ROI_sig(:,k), ROI_sig(:,j), mu);
        end
    end
    beta(k,:,:) = betak;
    fprintf('.')
end
fprintf('.\n')
for k=1:nobs
    Matrix(:,:,k) = (beta(:,:,k)+beta(:,:,k)')/2;
end
%     save(save_info.nii_mat_name,'FCM');
end
% toc

function b_FLS = wgr_fls(X,y,mu);
[N,K] = size(X);
G=zeros(N*K,N);
A=zeros(N*K,N*K);
mui = mu*eye(K);
ind = 1:K;

for i=1:N
    G(ind,i) = X(i,:);
    if i==1
        Ai = X(i,:)'*X(i,:) + mui;
        A(ind,ind)= Ai ;
        A(ind,ind+K)= - mui;
    elseif i~=1 && i~=N
        Ai = X(i,:)'*X(i,:) + 2*mui;
        A(ind,ind)= Ai ;
        A(ind,ind+K)= - mui;
        A(ind,ind-K)= - mui;
    else% i==N
        Ai = X(i,:)'*X(i,:) + mui;
        A(ind,ind)= Ai ;
        A(ind,ind-K)= - mui;
    end
    ind = ind+K;
end
b_FLS = linsolve(A,G*y);
b_FLS = reshape(b_FLS,K,N)';
end

