%% ¢ÜState to State Transitions
function state_to_state=sf_state_to_state(labels,K)
T=length(labels); 
for i=1:K
    for j=1:K
        n_transition=0;
        for t=1:T-1
            if labels(t)==i&&labels(t+1)==j
                n_transition=n_transition+1;
            end
        end
         state_to_state(i,j)=n_transition;
        
    end
end
clear i
clear j

state_to_state=state_to_state-diag(diag(state_to_state));
for j=1:K
    tmp_sum(j)=sum(state_to_state(:,j));
end

for i=1:K
    for j=1:K    
       state_to_state(i,j)=state_to_state(i,j)/tmp_sum(j); 
    end
end
state_to_state(isnan(state_to_state))=0;