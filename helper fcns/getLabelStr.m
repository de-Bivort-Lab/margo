function [labelStr] = getLabelStr(expmt)

labelStr = '';

f = 'Strain';
if isfield(expmt,f)
    labelStr = [labelStr '_' expmt.(f)];
end

f = 'Treatment';
if isfield(expmt,f)
    labelStr = [labelStr '_' expmt.(f)];
end

f = 'Day';
if isfield(expmt,f)
    labelStr = [labelStr '_' num2str(expmt.(f))];
end

lab_fields = expmt.meta.labels_table.Properties.VariableNames;

f = 'ID';
if any(strcmp(f,lab_fields))
    labelStr = [labelStr '_' num2str(expmt.meta.labels_table.(f)(1)) '-' num2str(expmt.meta.labels_table.(f)(end))];
end

if ~isempty(labelStr)
    labelStr(1)=[];
end