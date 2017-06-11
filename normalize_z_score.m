function y = normalize_z_score(x)
    m = mean(x);
    s = std(x);
    y = (x - m) / s;
end