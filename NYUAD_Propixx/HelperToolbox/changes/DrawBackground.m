function DrawBackground(VP)

Screen('SelectStereoDrawBuffer', VP.window, 1);
Screen('DrawTexture', VP.window, VP.bg(VP.curBg));
% Screen('DrawLines', VP.window, VP.fixationCrosshairs(:,1:4), VP.lineWidth, VP.fixationCrosshairColors(:,1:4), VP.windowCenter, 1);

Screen('SelectStereoDrawBuffer', VP.window, 0);
Screen('DrawTexture', VP.window, VP.bg(VP.curBg));
% Screen('DrawLines', VP.window, VP.fixationCrosshairs(:,5:8), VP.lineWidth, VP.fixationCrosshairColors(:,1:4), VP.windowCenter, 1);