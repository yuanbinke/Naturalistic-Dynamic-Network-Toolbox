function dwell_time=sf_dwell_time(labels,K,TR)
%获取这个labels中各个k的总数
for k=1:K
    state_location=find(labels==k);                                  
    dwell_time(k)=(length(state_location)* TR); %time=%%(100*2）：the number of subjects * the number of sessions(lr/rl)
end
    

