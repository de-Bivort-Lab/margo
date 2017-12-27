function expmt = autoAnalyze(expmt,varargin)

% master analyze function that parses the experiment input and runs
% the analysis function for the corresponding experiment. Called by
% analyze_multiFile.m


switch expmt.Name
    
    case 'Basic Tracking'
        expmt = analyze_arenacircling(expmt,varargin{:});
        
    case 'Arena Circling'
        expmt = analyze_arenacircling(expmt,varargin{:});
        
    case 'Y-maze'
        expmt = analyze_ymaze(expmt,varargin{:});
        
    case 'LED Y-maze'
        expmt = analyze_ledymaze(expmt,varargin{:});
        
    case 'Slow Phototaxis'
        expmt = analyze_slowphototaxis(expmt,varargin{:});
        
    case 'Optomotor'
        expmt = analyze_optomotor(expmt,varargin{:});
        
    case 'Circadian'
        expmt = analyze_circadian(expmt,varargin{:});
        
    otherwise
        errordlg('Experiment name not recognized, no analysis performed');
        
end