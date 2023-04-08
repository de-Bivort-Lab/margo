classdef MatlabVersionChecker
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        CURRENT_RELEASE string = string(version('-release'));
    end
    
    methods(Static)

        function out = isReleaseOlderThan(release)
            out = MatlabVersionChecker.CURRENT_RELEASE < string(release);
        end

        function out = isReleaseNewerThan(release)
            out = MatlabVersionChecker.CURRENT_RELEASE > string(release);
        end

        function out = isReleaseEqualTo(release)
            out = MatlabVersionChecker.CURRENT_RELEASE == string(release);
        end

    end
end

