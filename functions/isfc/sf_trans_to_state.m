%% ③Transitions to spectific states (state2/3/4 to state1)
function transitions_to_state=sf_trans_to_state(labels,K)
%计算每个状态切换了多少次
T=length(labels); 
for k=1:K
     n_transition=0;
    for j=2:T
        if labels(j)==k&&labels(j-1)~=k            %the adjacent labels is different
            n_transition=n_transition+1;
        end
    end
    transitions_to_state(k)=n_transition;
 end


