function fitVals = raisedCosine(params, span)

w = round(params(1));
h = params(2);
offset = round(params(3));
fitVals = rcos(span, w, h, offset);

