function rcs = rcs_wetland(x)
    % x is the grazing angle in deg
    % rcs is the radar cross section in m^2
    p1 = -4.3868e-06;
    p2 = 0.00098614;
    p3 = -0.071347;
    p4 = 2.2443;
    p5 = -44.959;
    rcs = p1*x^4 + p2*x^3 + p3*x^2 + p4*x + p5;
end