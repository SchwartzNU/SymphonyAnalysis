function y = rcos(span, w, h, offset)
%if offset <= 0 || offset + 2*w > span %out of bounds error
if offset <= 0 %out of bounds error
    y = ones(1,span) * inf;
    return;
end

if w < 2 %out of bounds error
   y = ones(1,span) * inf;
   return;
end

if h < 0 %out of bounds error
   y = ones(1,span) * inf;
   return;
end

y = zeros(1,span);
x = linspace(-pi,pi,2*w);
c = real(cos(x).^0.5);
c = c.*h;
y(offset:offset+(2*w)-1) = c;
y = y(1:span);