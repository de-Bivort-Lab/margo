classdef NanFilteredStatistic
    %NANFILTEREDSTATISTIC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        functionHandle;
        functionId;
        data;
        dimensionToApply;
    end
    
    methods (Access = public)

        function this = NanFilteredStatistic(functionHandle, functionId, data, varargin)
            %NANFILTEREDSTATISTIC Construct an instance of this class
            %   Detailed explanation goes here
            this.functionHandle = functionHandle;
            this.functionId = functionId;
            this.data = data;
            this.dimensionToApply = this.getDimension(varargin);
        end

        function out = apply(this)

            if this.dimensionToApply < 0
                out = this.applyToSingleDimension(this.data);
                return;
            end
            
            out = cellfun(@(x) this.applyToSingleDimension(x), num2cell(this.data, this.dimensionToApply));
        end
        
    end

    methods (Access = private)

        function value = applyToSingleDimension(this, x)
            mask = isnan(x);
            if all(mask)
                value = cast(NaN, class(x));
                return;
            end
            value = this.functionHandle(x(~mask));
        end

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
                msg = sprintf("Unsupported number of inputs: %d", numel(args));
                throw(this.buildException("unsupportedInput", msg));
            end
        
            if ~isnumeric(args{1})
                msg = sprintf("Unsupported data type: %d for dimension argument", class(args{1}));
                throw(this.buildException("invalidDimensionType", msg));
            end
        
            dimension = args{1};
        end

        function exception = buildException(this, errorId, message)
            exception = MException(strcat(this.functionId, ":", errorId), message);
        end
    end
end

