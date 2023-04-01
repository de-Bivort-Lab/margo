function updateMonitor(deviceId, monitorStatus)
%UPDATEMONITOR Updates the debivort.org monitor page

MONITOR_URI = 'http://lab.debivort.org/mu.php';
DEVICE_ID_QUERY_PARAM = 'id';
STATUS_QUERY_PARAM = 'st';

endpoint = sprintf('http://%s?%s=%d&%s=%d', MONITOR_URI, ...
    DEVICE_ID_QUERY_PARAM, deviceId, ...
    STATUS_QUERY_PARAM, monitorStatus.code);

webop = weboptions('Timeout', 0.25);
status=true;
try
    webread(endpoint, webop);
catch
    status = false;
end

if ~status
    gui_notify(sprintf('unable to connect to %s', MONITOR_URI), handles.disp_note);
end

end

