function mem = bytesAvailableMemory

OS = computer;

switch OS
    case 'PCWIN64'
        mem_stats = memory;
        mem = mem_stats.MemAvailableAllArrays;
    case 'GLNXA64'
        [~,out]=system('vmstat -s -S M | grep "free memory"');
        mem_MB=sscanf(out,'%f  free memory');
        mem = mem_MB * 1048576;
    case 'MACI64'
        [~,out]=unix('vm_stat | grep free');
        spaces=strfind(out,' ');
        mem = str2double(out(spaces(end):numel(out)))*4096;
end