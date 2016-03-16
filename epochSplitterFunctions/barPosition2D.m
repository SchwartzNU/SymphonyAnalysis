function val = barPosition2D(epoch)
    Xpos = epoch.get('positionX');
    Ypos = epoch.get('positionY');
    if Xpos
        s = sign(Xpos);
    else
        s = sign(Ypos);
    end
    val = s*round(sqrt(Xpos^2 + Ypos^2));
end