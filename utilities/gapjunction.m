function Rj = gapjunction(Rn,Rjp,i)
    
    Rj = (0.5*Rjp) - Rn + 0.5*sqrt((Rjp^2) + 4*(Rjp*Rn) + 4*(Rn)^2 + 4*i*(Rjp*Rn));
    
end