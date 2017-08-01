function H = polarerror(T,R,Err)
% POLARERROR - polar plot with error bars
% H = polarerror(T,R,Err) ;

if mean(R) < 0
    R = -1*R;% - min(yvals);
    disp('Mean value is negative, so all values are flipped over 0')
end

T = T(:) ;
R = R(:) ;
E = [R-Err(:) R+Err(:)] ;
E(:,3) = NaN ;

x = [T T T].' ;
y = E.' ;
H(1) = polar(x(:),y(:),'-') ; hold on ; % error bars
T = [T; T(1)];
R = [R; R(1)];
H(2) = polar(T, R , 'o-') ; hold off ; % values