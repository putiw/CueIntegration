function [RetrievedDepth] = DisparityToDepth(IOD, xLocMm, HorizontalDisparity, viewingDistance, xLocFixationPoint)
%% Keeping a constant horizontal disparity across the visual field
% Find the depth for a stimulus given a particular starting coordinate and
% desired horizontal disparity. VIEWING DISTANCE IS A NEGATIVE Z

% xLocCM should be the location of each dot in cm in the visual field.
% See Howard & Rogers book chapter on the Horopter for the disparity
% equation

% degreesPerCM = (2*atand(displayWidth/2/viewingDistance))/displayWidth;
% xLocDeg = xLocMm.*degreesPerCM;

ConvergenceAngleFixation = atand(((IOD/2)+xLocFixationPoint)/viewingDistance) + atand(((IOD/2)-xLocFixationPoint)/viewingDistance); %left eye + right eye
%%Go from Disparity to Depth
for h = 1:length(HorizontalDisparity)
    f = @(xDepth) abs((atand(((IOD/2)+xLocMm)/(xDepth)) + atand(((IOD/2)-xLocMm)/(xDepth))) - (ConvergenceAngleFixation)-HorizontalDisparity(h));
    [X,FVAL] = fminsearch(@(xDepth) f(xDepth),viewingDistance); % Finds a minimum of the anonymous function evaluated at xDepth and near the value - viewingDistance
    %         [X,FVAL] = lsqnonlin(@(xDepth) f(xDepth), viewingDistance); %, viewingDistance+pa.depthExtent/2, viewing);
    RetrievedDepth(h) = X;
    Errors = FVAL;
end

