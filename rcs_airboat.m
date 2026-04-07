function rcs = rcs_airboat(x)
    % x is the grazing angle in deg
    % rcs is the radar cross section in m^2
    p1 = -4.41228e-9;
    p2 =  1.24415e-6;
    p3 = -1.2775e-4;
    p4 =  5.7724e-3;
    p5 = -0.1075;
    p6 =  0.5756;
    p7 =  5.9000;
    rcs = p1*x^6 + p2*x^5 + p3*x^4 + p4*x^3 + p5*x^2 + p6*x + p7;
end