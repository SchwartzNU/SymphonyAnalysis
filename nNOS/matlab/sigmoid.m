function y = sigmoid(x, Vhalf, slope)
y = 1./(1+(exp(-(x-Vhalf)./slope)));