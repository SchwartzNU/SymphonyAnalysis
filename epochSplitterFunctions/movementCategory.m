function type = movementCategory(epoch)
    centerSeed = epoch.get('motionSeedCenter');
    surroundSeed = epoch.get('motionSeedSurround');
    motionMode = epoch.get('motionMode');
    
    if strcmp(motionMode,'single step')
        surroundMove = mod(surroundSeed, 2);
        centerMove = mod(centerSeed, 2);
        
        if centerMove && surroundMove
            type = 'Global';
        elseif centerMove && ~surroundMove
            type = 'Center';
        elseif ~centerMove && surroundMove
            type = 'Surround';
        elseif ~centerMove && ~surroundMove
            type = 'No Movement';
        end
    else
        if centerSeed == surroundSeed
            type = 'Global';
        else
            type = 'Differential';
        end
    end
end