function h = saveDeletedFigure_callback(h,callbackdata)
saveas(h,['TestDisplay_' datestr(now,30)]);

delete(h);