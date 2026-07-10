function Data = art_simulated_stock_data(n)
%SIMULATED_STOCK_DATA Generate stock-like OHLC data.
if nargin < 1, n = 150; end
rng(42);
ret = 0.02*randn(n,1);
closeP = 100 + cumsum(ret*30 + 0.05);
openP = closeP + randn(n,1)*0.6;
highP = max(openP,closeP) + abs(randn(n,1))*1.2 + 0.2;
lowP = min(openP,closeP) - abs(randn(n,1))*1.2 - 0.2;
try
    t = datetime('today') - days(n-1:-1:0)';
catch
    t = (1:n)';
end
Data = table(t,openP,highP,lowP,closeP, ...
    'VariableNames',{'Time','Open','High','Low','Close'});
end
