function [i_src,i_set]=cmpCamSettings(src,settings)

% compare settings of the active src with local settings in the gui
% 
% OUTPUTS
% 
% i_src = mapping vector to the indices of i_src which are paired with the
% corresponding index of i_set

src_info = propinfo(src);
src_names = fieldnames(src_info);
set_names = fieldnames(settings);

n = max([length(set_names) length(src_names)]);
i_src = [];
i_set = [];

for i = 1:length(set_names)
    if any(ismember(src_names,set_names(i)))
        aib = find(ismember(src_names,set_names(i)));
        i_src = [i_src aib];
        i_set = [i_set i];
    end
end




        
        
    
    
    
    
    
    
    
        