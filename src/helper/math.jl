function bino(n, k)
    if (k == 2)
        return (n * (n - 1)) / 2
    end

    if (k == 0 || k == n)
        return 1;
    end
    return bino(n - 1, k - 1) + bino(n - 1, k);
end