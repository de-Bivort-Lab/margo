classdef NanFilteredStatistic
    %NANFILTEREDSTATISTIC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        functionHandle function_handle;
        functionId string;
        data double;
        dimensionToApply int32;
    end

    properties(Constant)
        NAN_FUNCTIONS_DEPRECATED_RELEASE = string('2020a');
        NAN_FUNCTION_PREFIX = string('nan');
        OMIT_NAN_FLAG = string('omitnan');
    end
    
    methods (Access = public)

        function this = NanFilteredStatistic(functionName, functionId, data, varargin)
            %NANFILTEREDSTATISTIC Construct an instance of this class
            %   Detailed explanation goes here
            this.functionHandle = NanFilteredStatistic.getFunctionHandle(functionName);
            this.functionId = functionId;
            this.data = data;
            this.dimensionToApply = this.getDimension(varargin);
        end

        function out = apply(this)

            if NanFilteredStatistic.isDeprecated() && this.dimensionToApply > 0
                out = this.functionHandle(this.data, this.dimensionToApply, NanFilteredStatistic.OMIT_NAN_FLAG);
            elseif NanFilteredStatistic.isDeprecated() && this.dimensionToApply < 0
                out = this.functionHandle(this.data(:), NanFilteredStatistic.OMIT_NAN_FLAG);
            elseif this.dimensionToApply > 0
                out = this.functionHandle(this.data, this.dimensionToApply);
            else
                out = this.functionHandle(this.data(:));
            end
        end
        
    end

    methods (Static)

        function isDeprecated = isDeprecated()
            isDeprecated = ~MatlabVersionChecker.isReleaseOlderThan( ...
                NanFilteredStatistic.NAN_FUNCTIONS_DEPRECATED_RELEASE);
        end

        function functionHandle = getFunctionHandle(functionName)

            if ~NanFilteredStatistic.isDeprecated()
                functionName = NanFilteredStatistic.NAN_FUNCTION_PREFIX + functionName;
            end

            functionHandle = str2func(functionName);
        end

    end

    methods (Access = private)

        function dimension = getDimension(this, args)
            
            if isempty(args) && sum(size(this.data) > 1) <= 1
                dimension = -1;
                return;
            end

            if isempty(args)
                dimension = 1;
                return;
            end
        
            if numel(args) > 1
                msg = sprintf('Unsupported number of inputs: %d', numel(args));
                throw(this.buildException('unsupportedInput', msg));
            end
        
            if ~isnumeric(args{1})
                msg = sprintf('Unsupported data type: %d for dimension argument', class(args{1}));
                throw(this.buildException('invalidDimensionType', msg));
            end
        
            dimension = args{1};
        end

        function exception = buildException(this, errorId, message)
            exception = MException(strcat(this.functionId, ':', errorId), message);
        end
    end
end

