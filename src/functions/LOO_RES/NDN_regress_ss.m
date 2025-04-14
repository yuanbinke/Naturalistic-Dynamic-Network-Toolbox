function [b,r] = NDN_regress_ss(y,X)
%UNTITLED perform regression.
% Perform regression
% Input:
%   y - Independent variable.
%   X - Dependent variable
% Output:
%   b - beta of regression model.
%   r - residual.
%
% Reference: 
% y_regress_ss(y,X,Contrast,TF_Flag) Written by YAN Chao-Gan
[n,ncolX] = size(X);
[Q,R,perm] = qr(X,0);
p = sum(abs(diag(R)) > max(n,ncolX)*eps(R(1)));
if p < ncolX
    R = R(1:p,1:p);
    Q = Q(:,1:p);
    perm = perm(1:p);
end
b = zeros(ncolX,1);
b(perm) = R \ (Q'*y);
yhat = X*b;                     % Predicted responses at each data point.
r = y-yhat;                     % Residuals.
end

