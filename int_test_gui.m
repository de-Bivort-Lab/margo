function int_test_gui()

f=figure(1);
uictl1 = uicontrol('Style','pushbutton','Position',[10, 10, 50, 50],'Callback',@pushbutton_Callback);
uictl2 = uicontrol('Style','pushbutton','Position',[100, 100, 50, 50],'Callback',@pushbutton_Callback);



end

function pushbutton_Callback(src,event)
    a=2;
    b=3;
    disp(a+b);
end