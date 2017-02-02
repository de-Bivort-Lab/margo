function int_test_gui()

f=figure(1);
uictl = uicontrol('Style','pushbutton','Callback',@pushbutton_Callback);

    function pushbutton_Callback(src,event)
        a=2;
        b=3;
        disp(a+b);
    end

end