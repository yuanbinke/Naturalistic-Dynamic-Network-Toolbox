function dwell_time=sf_dwell_time(labels,K,TR)
%��ȡ���labels�и���k������
for k=1:K
    state_location=find(labels==k);                                  
    dwell_time(k)=(length(state_location)* TR); %time=%%(100*2����the number of subjects * the number of sessions(lr/rl)
end
    

