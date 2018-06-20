function path = unixify(path)
% convert path to unix compatible file path

    path(path=='\')='/';
    