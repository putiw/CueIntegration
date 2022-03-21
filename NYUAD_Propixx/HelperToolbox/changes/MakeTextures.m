function VP = MakeTextures(pa,VP)

% 1/f noise texture to help anchor vergence
[x,y] = meshgrid(-VP.Rect(3)/2:VP.Rect(3)/2,-VP.Rect(4):VP.Rect(4));
%[x,y] = meshgrid(-VP.Rect(4):VP.Rect(4),-VP.Rect(3):VP.Rect(3));

nBackgroundTextures = 4;
for bgii =1:nBackgroundTextures
    
    noysSlope = 1.1;
    noys = oneoverf(noysSlope, size(x,1), size(x,2));
    noys = VP.white.*noys;
    
    % Individual cutouts for each location
    positions   = allcomb(d2r(pa.thetaDirs), pa.rDirs.*VP.pixelsPerDegree );
    [centerX, centerY]     = pol2cart(positions(:,1), positions(:,2));
    centerY = -centerY;
    noys(:,:,2) = ones(size(noys));
    
    cheeseHoleLimit = pa.screenAperture * VP.pixelsPerDegree * 1.3;
    
    for ii = 1:length(centerX)
        noys(:,:,2) = noys(:,:,2) & (sqrt((centerX(ii)-x).^2+(centerY(ii)-y).^2) > cheeseHoleLimit);
    end
    %
    % noys(:,:,2) = noys(:,:,2) & (sqrt(x.^2+y.^2) < pa.rmax_bg);
    
    %noys(:,:,2) = noys(:,:,2) + (sqrt((x).^2+(y).^2) < (pa.fixationRadius*VP.pixelsPerDegree ));
    
    noys(:,:,2) = noys(:,:,2) .* VP.white;
    VP.bg(bgii)=Screen('MakeTexture', VP.window, noys);
end
VP.curBg = 1;
VP.noys=noys;
VP.fixationCrosshairs = [VP.fixationCrosshairs ...
    [VP.fixationCrosshairs(1,:) + (max(pa.rDirs).*VP.pixelsPerDegree ); VP.fixationCrosshairs(2,:)] ...
    [VP.fixationCrosshairs(1,:) - (max(pa.rDirs).*VP.pixelsPerDegree ); VP.fixationCrosshairs(2,:)] ...
    [VP.fixationCrosshairs(1,:); VP.fixationCrosshairs(2,:) + (max(pa.rDirs).*VP.pixelsPerDegree )] ...
    [VP.fixationCrosshairs(1,:); VP.fixationCrosshairs(2,:) - (max(pa.rDirs).*VP.pixelsPerDegree )]];

VP.fixationCrosshairColors = repmat(VP.fixationCrosshairColors, 1, 5);

end



