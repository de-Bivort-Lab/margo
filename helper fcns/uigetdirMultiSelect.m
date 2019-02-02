function [files] = uigetdirMultiSelect()

import com.mathworks.mwswing.MJFileChooserPerPlatform;
jchooser = javaObjectEDT('com.mathworks.mwswing.MJFileChooserPerPlatform');
jchooser.setFileSelectionMode(javax.swing.JFileChooser.DIRECTORIES_ONLY);
jchooser.setMultiSelectionEnabled(true);

jchooser.showOpenDialog([]);

if jchooser.getState() == javax.swing.JFileChooser.APPROVE_OPTION
    jFiles = jchooser.getSelectedFiles();
    files = arrayfun(@(x) char(x.getPath()), jFiles, 'UniformOutput', false);
elseif jchooser.getState() == javax.swing.JFileChooser.CANCEL_OPTION
    files = [];
else
    error('Error occurred while picking file');
end