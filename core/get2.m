      function vals = get2(obj, paraName)
            nobj = numel(obj);
            %obtain the size of object
            flag_numeric = false;
            if isnumeric(get(obj(1),paraName)) && length(get(obj(1),paraName))==1
                vals = zeros(size(obj));
                flag_numeric = true;
            else
                vals = cell(size(obj));
            end
            for n=1:nobj
                if flag_numeric
                    vals(n) = get(obj(n),paraName);
                else
                    vals{n} = get(obj(n),paraName);
                end
            end
        end
        %% DT