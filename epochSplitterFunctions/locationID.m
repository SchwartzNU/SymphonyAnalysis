function val = locationID(epoch)
if epoch.get('isPair')
    val = epoch.get('pairID');
else
    val = epoch.get('spot1ID');
end
