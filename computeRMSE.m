function RMSE = computeRMSE(x, y)
    RMSE = sqrt(mean((x - y) .^ 2));
end