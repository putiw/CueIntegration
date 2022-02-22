function create_stim_NYUAD(VP,pa)

% Goal: Create a more efficient stimulus generation by identifying the
% primary constraints in the process.

% We find a vector traveling towards the cyclopean eye that is centered at
% some u,v on the screen, or is parallel to this vector and within some arbitrary
% screen aperture:
% vec = [u, v, viewing_dist]

% This screen aperture should be defined by some circle with aperture center
% x0,y0:
% (x - x0)^2 + (y - y0)^2 = r^2

% Now, technically the front of all possible volumes are defined by our
% chosen disparity constraints, creating a disparity sphere/cylinder

% We need to determine where the screen aperture, which projects along a
% vector towards the cyclopean eye, intersects with this disparity cylinder.

% At this intersection point, the left and right eye projetions must be
% within the aperture.
% ---------------------------
% This defines all vectors we can use to create dots.

debug = 0;
num_vecs = 10000;
% Do this for each aperture if there are multiple defined
for ap = 1:size(pa.allPositions,1)
    % Let's get a pool of 10,0000 vectors within our aperture
    
    [VP.dstCenter(1), VP.dstCenter(2)] = pol2cart(d2r(pa.allPositions(ap,1)), tand(pa.allPositions(ap,2))*VP.screenDistance);
    xLocFixationPoint = 0;
    ConvergenceAngleFixation = atand(((VP.IOD/2)+xLocFixationPoint)/VP.screenDistance) + atand(((VP.IOD/2)-xLocFixationPoint)/VP.screenDistance); %left eye + right eye
    ops = optimset(@fminsearch);
    ops.TolFun = 0.01;
    ops.Display = 'off';
    ops.MaxIter = 5;
    f = @(xDepth,disp) abs((atand(((VP.IOD/2)+0)/(xDepth)) + atand(((VP.IOD/2)-0)/(xDepth))) - (ConvergenceAngleFixation)-disp);
    [disp_rad] = fminsearch(@(xDepth,disp) f(xDepth,1),VP.screenDistance);
    aperture_mm = tand(pa.screenAperture)*VP.screenDistance; % radius
    
    % Generate a lookup table of disparities/depths
%     disp('Generating disparity lookup table...')
    disparity_range = [-pa.disparityLimit,pa.disparityLimit];
    step = 0.001;
    disparity_depth_lookup = Disparity_Gradient(disparity_range,step,VP);
    disp('complete')
    
%     disp('Finding dots that can traverse the whole volume');
    % Get dot x,y
    theta = 2*pi*rand(num_vecs,1); % Random thetas
    r = sqrt(rand(num_vecs,1))*tand(pa.screenAperture)*VP.screenDistance; % Random radii
    dots(:,1) = r.*cos(theta);
    dots(:,2) = r.*sin(theta);
    dots(:,3) = VP.screenDistance;
    % Now all of these dots have vectors that are offset by stimulus
    % location (VP.dstCenter)
    dots(:,1:2) = dots(:,1:2) + VP.dstCenter;
    
    % L is the direction of the trajectory, defined by:
    l = [VP.dstCenter(1), VP.dstCenter(2), VP.screenDistance];
    l = l/vecnorm(l'); % make it a unit vector
    l = repmat(l,num_vecs,1); % matrix to do it with all our dots
    lines = [dots, l];
    % The disparity limits define a cylinder formed by the Vieth Muller circle
    % defined by the disparity. We need to intersect the lines with the cylinder
    % to find the corresponding world locations quickly
    %   LINE     = [x0 y0 z0  dx dy dz]
    %   CYLINDER = [x1 y1 z1 x2 y2 z2 R]
    [center, rad] = circlefit3d([-VP.IOD/2,0,0], [VP.IOD/2,0,0], [0,0,disp_rad]); % Fit a circle
    cylinder = [center(1), -100, center(3),... % bottom of cylinder (arbitrary y value)
        center(1), 100, center(3),... % top 
        rad]; % radius
    for d = 1:size(lines,1)
        points = intersectLineCylinder(lines(d,:), cylinder,'checkBounds',false); % find intersection of line and cylinder
        pos_vec(d,:) = points(2,:); % Always the second intersection (the first is behind the eyes)
    end
    
    % The actual left and right dot positions, offset correctly for
    % each eye, can be triangulated as follows (by similar triangles):
    leftStereoX = ((VP.IOD/2 + pos_vec(:,1)).*(VP.screenDistance./pos_vec(:,3))) - VP.IOD/2;
    rightStereoX = VP.IOD/2 - ((VP.IOD/2 - pos_vec(:,1)).*(VP.screenDistance./pos_vec(:,3)));
    stereoY = pos_vec(:,2).* (VP.screenDistance./pos_vec(:,3));
    dL = sqrt((VP.dstCenter(1)-leftStereoX).^2 + (VP.dstCenter(2)-stereoY).^2); % distance from aperture center
    dR = sqrt((VP.dstCenter(1)-rightStereoX).^2 + (VP.dstCenter(2)-stereoY).^2); % distance from aperture center
    % grab the dots that don't exit the aperture
    surviving_dots = find(~(dL > tand(pa.screenAperture)*VP.screenDistance | dR > tand(pa.screenAperture)*VP.screenDistance));
    viable_dot_starts = dots(surviving_dots,:);
    
    % Do the same for the binocular condition since this will be different
    leftStereoX = tand(atand((dots(:,1) + VP.IOD/2)./VP.screenDistance)+(pa.disparityLimit/2)).*VP.screenDistance - VP.IOD/2;
    rightStereoX = tand(atand((dots(:,1) - VP.IOD/2)./VP.screenDistance)-(pa.disparityLimit/2)).*VP.screenDistance + VP.IOD/2;
    stereoY = dots(:,2);
    dL = sqrt((VP.dstCenter(1)-leftStereoX).^2 + (VP.dstCenter(2)-stereoY).^2); % distance from aperture center
    dR = sqrt((VP.dstCenter(1)-rightStereoX).^2 + (VP.dstCenter(2)-stereoY).^2); % distance from aperture center
    % grab the surviving dots
    surviving_dots = find(~(dL > tand(pa.screenAperture)*VP.screenDistance | dR > tand(pa.screenAperture)*VP.screenDistance));
    bino_viable_dot_starts = dots(surviving_dots,:);
    
    % Now we have a bank of viable dot starting positions. If these dots don't
    % exit at the front portion of the volume, then they will never exit the
    % aperture! Creat a huge matrix of all our different stimuli.
    
    % If we are using reverse phi, half need to be white and half black
    if pa.reversePhi == 1 || pa.IOVD == 1
        pa.dotColor = [ones(ceil(pa.numberOfDots/2),3); zeros(floor(pa.numberOfDots/2),3)].*255;
        pa.dotColor(:,4) = 255;
    else
        pa.dotColor = [ones(ceil(pa.numberOfDots),3)].*255;
        pa.dotColor(:,4) = 255;
    end
    
    %% Use these valid starting positions to generate stimuli
    begin = GetSecs;
    conditions = [{'comb'},{'monoL'},{'bino'}]; % skip monoR, we will use the same matrix as monoL, just the other eye
    for cond = 1:length(conditions) % for each condition
        for c = 1:length(pa.coherence) % for each coherence
            noise_dots = [];
            signal_dots = [];
            loopers = [];
            pa.dots = [];
            o= [];
            for s = 1:pa.numberOfRepeats % create a stimulus for each block
                % Get new dots for this stimulus
                if cond == 3
                    newDots = datasample(bino_viable_dot_starts,pa.numberOfDots);
                else
                    newDots = datasample(viable_dot_starts,pa.numberOfDots);
                end
                pa.dots(:,1:3) = newDots;
                pa.dots(:,4) = ones(pa.numberOfDots,1); % just pick the direction (aribitrary since delta disp determines direction when making stimuli)
                temp_disp = linspace(-pa.disparityLimit, pa.disparityLimit, pa.numberOfDots+1);
                temp_disp(end) = []; % remove last one
                temp_disp = temp_disp + mean(diff(temp_disp))/2 + pa.deltaDisp; % center at 0, then account for the "first step" you'll take
                temp_disp = temp_disp - 2*pa.disparityLimit*rand(1); % randomly shift so that there are no patterns over time
                pa.dots(:,6) = temp_disp;
                
                for nn = 1:pa.numFlips % Loop through all the frames for this trial
                    numCoherentDots = round((pa.coherence(c)*pa.numberOfDots)); %get the number of coherent dots for this trial
                    pa.coherentDots = datasample([1:pa.numberOfDots],numCoherentDots,'Replace',false); %pick which dots are signal dots
                    %Give signal dots a 5th index equal to 1, noise dots equal to 0
                    pa.dots(:,5) = 0;
                    pa.dots(pa.coherentDots,5) = 1;
                    
                    noise_dots = find(pa.dots(:,5) == 0);
                    signal_dots = find(pa.dots(:,5) == 1);
                    
                    % Update the disparity values and check for looping dots
                    pa.dots(:,6) = pa.dots(:,6) - pa.deltaDisp;
                    % are you looping?
                    loopers = find(abs(pa.dots(:,6)) > pa.disparityLimit);
                    
                    if ~isempty(loopers)
                        if pa.reversePhi == 1
                            colors = pa.dotColor(loopers,1); % should be 0 or 1 now.
                            b_colors = colors/255;
                            colors = abs(b_colors -1).*255; % reverses the color
                            pa.dotColor(loopers,1:3) = repmat(colors,1,3);
                        end
                        if cond == 3
                            newDots = datasample(bino_viable_dot_starts,length(loopers));
                        else
                            newDots = datasample(viable_dot_starts,length(loopers));
                        end
                        pa.dots(loopers,1:3) = newDots;
                        residual = abs(pa.dots(loopers,6)) - pa.disparityLimit;
                        pa.dots(loopers,6) = pa.disparityLimit - residual; % place you on the edge + remaining distance
                    end
                    
                    if ~isempty(noise_dots)
                        % Grab new dots for the noise dots -- changes every frame
                        if cond == 3
                            newDots = datasample(bino_viable_dot_starts,length(noise_dots));
                        else
                            newDots = datasample(viable_dot_starts,length(noise_dots));
                        end
                        pa.dots(noise_dots,1:3) = newDots;
                        pa.dots(noise_dots,6) = pa.disparityLimit*2*rand(length(noise_dots),1) - pa.disparityLimit; % give a random disparity to these dots
                    end
                    
                    if cond ~= 3
                        % Instead of calculating the disparity directly for each
                        % dot, we approximate it from a matrix of predefined
                        % disparity values and corresponding depths, each depth
                        % defining a particular "disparity cylinder"
                        % We must find the intersection points for all these dots:
                        % L is the direction of the line, defined by:
                        l = [VP.dstCenter(1), VP.dstCenter(2), VP.screenDistance];
                        l = l/vecnorm(l'); % make it a unit vector
                        depths = interp1(disparity_depth_lookup(:,1),disparity_depth_lookup(:,2),pa.dots(:,6));
                        
                        for d = 1:size(pa.dots,1)
                            %   LINE     = [x0 y0 z0  dx dy dz]
                            line = [pa.dots(d,1:3), l];
                            %   CYLINDER = [x1 y1 z1 x2 y2 z2 R]
                            [center, rad] = circlefit3d([-VP.IOD/2,0,0], [VP.IOD/2,0,0], [0,0,depths(d)]); % Fit a circle
                            cylinder = [center(1), -100, center(3),... % bottom location
                                center(1), 100, center(3),... % top location
                                rad]; % radius
                            points = intersectLineCylinder(line, cylinder,'checkBounds',false);
                            pa.dots(d,1:3) = points(2,:); % Always the second intersection, z value
                            
                            % Great plot for debugging to ensure the dot
                            % always is on the same "line" until looping
%                             if d == 1
%                                 if nn == 1
%                                     figure; hold on; light;
%                                     [v1 f1] = cylinderMesh(cylinder);
%                                     drawMesh(v1, f1, 'FaceColor', 'y');
%                                     drawPoint3d([-VP.IOD/2,0,0], 'ro');
%                                     drawPoint3d([VP.IOD/2,0,0], 'ro');
%                                     drawPoint3d([VP.dstCenter(1) VP.dstCenter(2) VP.screenDistance], 'bo');
%                                     
%                                 end
%                                 drawLine3d(line);
%                                 drawPoint3d(points(2,:), 'ok');
%                             end
                            
                        end
                        % Get the screen coordinates
                        leftStereoX = ((VP.IOD/2 + pa.dots(:,1)).*(VP.screenDistance./pa.dots(:,3))) - VP.IOD/2;
                        rightStereoX = VP.IOD/2 - ((VP.IOD/2 - pa.dots(:,1)).*(VP.screenDistance./pa.dots(:,3)));
                        stereoY = pa.dots(:,2).* (VP.screenDistance./pa.dots(:,3));
                        
                        pa.dotDistance = VP.screenDistance - pa.dots(:,3);
                        dotPixelSize = pa.dotDiameter.* VP.screenDistance./pa.dots(:,3); %(pa.dotDistance ./ VP.screenDistance); %include monocular size cue
                    else
                        pa.dots(:,3) = VP.screenDistance;
                        leftStereoX = tand(atand((pa.dots(:,1) + VP.IOD/2)./VP.screenDistance)+pa.dots(:,6)./2).*VP.screenDistance - VP.IOD/2;
                        rightStereoX = tand(atand((pa.dots(:,1) - VP.IOD/2)./VP.screenDistance)-pa.dots(:,6)./2).*VP.screenDistance + VP.IOD/2;
                        stereoY = pa.dots(:,2);
                        pa.dotDistance = pa.dots(:,3);
                        dotPixelSize = pa.dotDiameter.* VP.screenDistance./pa.dots(:,3); %include monocular size cue
                    end
                    dot_mat = [leftStereoX,rightStereoX, stereoY, dotPixelSize, pa.dotColor];
                    % We have the dots for this frame, now we just need to save them.
                    dotMatrix.(conditions{cond})(ap,c,:,:,nn,s) = dot_mat;
                    if cond == 2
                        dotMatrix.monoR(ap,c,:,:,nn,s) = dot_mat; % add to right eye matrix, should be okay since it is a different pattern for the right eye
                    end
                end
            end
        end
    end
end
save('DotBank.mat','dotMatrix','-v7.3');
gen_time = GetSecs - begin;
% disp(['Total Stimulus Generation Time: ' num2str(gen_time)]);
end
