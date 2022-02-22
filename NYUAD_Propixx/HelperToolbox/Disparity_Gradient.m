function disparity_depth_lookup = Disparity_Gradient(disparity_range,step,VP)
% Create a "lookup" table that has the corresponding depth for the
% disparities in the range "disparity_range" incremented by "step"
% Fixation is assumed to be at 0,0:
ConvergenceAngleFixation = atand(((VP.IOD/2))/VP.screenDistance) + atand(((VP.IOD/2))/VP.screenDistance); %left eye + right eye
% Define the disparity equation:
f = @(xDepth,disp) abs((atand(((VP.IOD/2))/(xDepth)) + atand(((VP.IOD/2))/(xDepth))) - (ConvergenceAngleFixation)-disp);
% Generate a vector of disparities to evaluate at:
disparities = disparity_range(1):step:disparity_range(2);
% The following performs the anonymous function @(disp)
% which is actually just an fminsearch performed on
% funciton "f". We evaluate the anonymous function using
% our disparities vector which we have defined above.
depths = arrayfun(@(disp) fminsearch(@(xDepth) f(xDepth,disp),VP.screenDistance),disparities);

disparity_depth_lookup = [disparities', depths'];
end