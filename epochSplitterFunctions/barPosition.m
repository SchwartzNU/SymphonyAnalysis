function val = barPosition(epoch)
    Xpos = epoch.get('positionX');
    Ypos = epoch.get('positionY');
    if Xpos == 0
        val = round(Ypos);
    else
        val = round(Xpos);
    end
end