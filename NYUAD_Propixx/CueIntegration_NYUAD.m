function [VP, pa] = CueIntegration_NYUAD(display);

%change
subject = input('Enter subject [test]: ','s');
if isempty(subject)
    % error('Enter subject name to start experiment');
    subject = 'test';
end
%% Setup parameters and viewing geometry
data = [];
global GL; % GL data structure needed for all OpenGL demos
backGroundColor = [0.5 0.5 0.5].*255; % Gray-scale - calibrate for display so white and black dots have same contrast with background
skipSync = 0; % skip Sync to deal with sync issues (should be for debugging only)
VP = SetupDisplay_NYUAD(skipSync, backGroundColor, display);
if VP.stereoMode == 8
    Datapixx('SetPropixxDlpSequenceProgram',1); % 1 is for RB3D mode, 3 for setting up to 480Hz, 5 for 1440Hz
    Datapixx('RegWr');
    Datapixx('SetPropixx3DCrosstalkLR', 0); % minimize the crosstalk
    Datapixx('SetPropixx3DCrosstalkRL', 0); % minimize the crosstalk
end

VP.backGroundColor = backGroundColor;
priorityLevel=MaxPriority(VP.window);
Priority(priorityLevel);
pa = SetupParameters_NYUAD(VP);
pa.response = zeros(pa.numberOfTrials,1);
kb = SetupKeyboard();
pa.trialNumber = 0;
fn = 1; %Frame 1
dontClear = 0; % Don't clear,on flip, we manually clear screen

kb = SetupKeyboard();
VP = MakeTextures(pa,VP);

%% Generate new dot matrices for quick drawing rather than doing the calculations between frames
Screen('SelectStereoDrawbuffer', VP.window, 0);
Screen('DrawText', VP.window, 'Preparing Experiment...',VP.Rect(3)/2,VP.Rect(4)/2);
Screen('SelectStereoDrawbuffer', VP.window, 1);
Screen('DrawText', VP.window, 'Preparing Experiment...',VP.Rect(3)/2,VP.Rect(4)/2);
VP.vbl = Screen('Flip', VP.window, [], dontClear);
create_stim_NYUAD(VP,pa)
s_size = strrep(num2str(pa.stimulusSizeDeg),'.','_'); % for indexing into the dot matrix structure created above.
load('DotBank.mat')
StateID = 0;
OnGoing = 1;
% Preload mex files
GetSecs; KbCheck;
%% Experiment Starts
while ~kb.keyCode(kb.escKey) && OnGoing
    
    [kb.keydown, ~, kb.keyCode] = KbCheck(-1);
    
    if kb.keyCode(kb.escKey) % Quit on escape
        % error('Escape key pressed');
        OnGoing = 0;
    end
    
    %% States control the experimental flow (e.g., inter trial interval, stimulus, response periods)
    switch StateID
        case 0
            % Draw blank window until button pressed
            Screen('SelectStereoDrawbuffer', VP.window, 0);
            DrawBackground(VP);
            Screen('DrawText', VP.window, 'Press a button to begin',VP.Rect(3)/2,VP.Rect(4)/2);
            
            Screen('SelectStereoDrawbuffer', VP.window, 1);           
            DrawBackground(VP);
            Screen('DrawText', VP.window, 'Press a button to begin',VP.Rect(3)/2,VP.Rect(4)/2);
            VP.vbl = Screen('Flip', VP.window, [], dontClear);
            
            % Doesn't work on my macbook but should work on others   
            kb.keyIsDown = 0;
            while kb.keyIsDown == 0;
                    [kb,~] = CheckKeyboard(kb); % if response with keyboard
                    [kb,~] = CheckResponseButton_MRI(kb); % if response with response button MRI                    
            end
            
            % Draw blank window until MRI triggers
            Screen('SelectStereoDrawbuffer', VP.window, 0);
            DrawBackground(VP);            
            Screen('SelectStereoDrawbuffer', VP.window, 1);
            DrawBackground(VP);
            VP.vbl = Screen('Flip', VP.window, [], dontClear);
            
%            %waiting for trigger 
            kb.keyIsDown = 0;
            while ~kb.keyIsDown
                    [kb,~] = CheckTrigger_MRI(kb); % if response with response button MRI
       
            end
            
            begintime = GetSecs;
            StateID = 1; % Inter trial interval
            FirstStep = 1;
            
        case 1 %% inter trial interval
            if FirstStep==1
                % Draw prerendered ITI window
                Screen('SelectStereoDrawbuffer', VP.window, 0);
                %change 5
                DrawBackground(VP);
                %Screen('FillRect', VP.window, VP.backGroundColor);
                Screen('SelectStereoDrawbuffer', VP.window, 1);
                DrawBackground(VP);
                %Screen('FillRect', VP.window, VP.backGroundColor);
                VP.vbl = Screen('Flip', VP.window, [], dontClear);
                
                pa.trialNumber = pa.trialNumber + 1;
                
                % Get this trial's parameters
                if pa.trialNumber > pa.numberOfTrials
                    totaltime = GetSecs - begintime;
                    pause(0.5)
                    OnGoing = 0; % End experiment                   
                    break;
                else
                    pa.trial = pa.design(pa.trialNumber,:); % Get this trial's parameters
                end
                
                % Get the stimulus location
                if size(pa.allPositions,1)>1
                    [x, y] = pol2cart(d2r(pa.allPositions(pa.trial(1),1)), tand(pa.allPositions(pa.trial(1),2))*VP.screenDistance);
                else
                    [x, y] = pol2cart(d2r(pa.allPositions(1)), tand(pa.allPositions(2))*VP.screenDistance);
                end
                VP.dstCenter = [x, y];
                
                % Get condition and load a stimulus
                pa.current_condition = char(pa.conditionNames(pa.trial(5)));
                pa.whichCondition = char(pa.current_condition);
                % We have a large stimulus "bank" with many repeats of the same stimulus type: pick a random one
                dotMatrix.blank = dotMatrix.monoR;
                rand_stim = randi([1,size(dotMatrix.comb,6)]);
                pa.current_stimulus = squeeze(dotMatrix.(char(pa.current_condition))(pa.trial(1),pa.trial(4),:,:,:,rand_stim));
                
                % The stimuli are identical for towards and away motions,
                % the only thing that changes is the order in which the
                % frames are presented.
                if pa.directions(pa.trial(3)) == 1
                    pa.current_stimulus = flip(pa.current_stimulus,3);
                end
                
                
                StateTime = GetSecs;
                FirstStep = 0;
                
            else % We have the stimulus parameters, now just wait until the ITI is over
                EndT = GetSecs - StateTime;
%  change               
%                EndT = GetSecs - StateTime;
%                 if EndT >= pa.ITI %intertrial interval
%                     StateID = 2; % send to fixation point
%                     FirstStep = 1;
%                 end
                          
                    StateID = 2; % send to fixation point
                    FirstStep = 1;
               
            end
            
        case 2   % Fixation Point starts - note that stimulus is not presented yet. This is just time to maintain fixation.
            if FirstStep==1 % Begin new trial - draw fixation point
                StateTime = GetSecs;
                fn = 1; % frame number
                % Draw prerendered Fixation window
                Screen('SelectStereoDrawbuffer', VP.window, 0);
            %change
DrawBackground(VP);
            %Screen('FillRect', VP.window, VP.backGroundColor);
                Screen('DrawDots', VP.window, [0 0],pa.fixationDotSize,pa.fixationDotColor,[VP.Rect(3)./2 VP.Rect(4)./2],2);
                Screen('SelectStereoDrawbuffer', VP.window, 1);
            %change
DrawBackground(VP);
            %Screen('FillRect', VP.window, VP.backGroundColor);
                Screen('DrawDots', VP.window, [0 0],pa.fixationDotSize,pa.fixationDotColor,[VP.Rect(3)./2 VP.Rect(4)./2],2);
                VP.vbl = Screen('Flip', VP.window, [], dontClear);

                FirstStep = 0;
            else % Wait for however long then present a stimulus
                CurrentTime = GetSecs;
                EndT = CurrentTime - StateTime;
                
                if EndT > pa.fixationAcqDura 
                    StateID = 3;
                    FirstStep = 1;
                end
            end
            
        case 3 % Begin drawing stimulus 
            colors = pa.current_stimulus(:,5:7,fn);
            % Outline of aperture for debugging
%             rad = tand(1.5)*VP.screenDistance*VP.pixelsPerMm;
%             rect = [0 0 rad*2 rad*2];
%             rect = CenterRectOnPoint(rect, VP.Rect(3)/2, VP.Rect(4)/2);
%             rect([1,3]) = rect([1,3]) + VP.dstCenter(1)*VP.pixelsPerMm;
%             rect([2,4]) = rect([2,4]) + VP.dstCenter(2)*VP.pixelsPerMm;
            
            for view = 0:1 %VP.stereoViews
                Screen('SelectStereoDrawbuffer', VP.window, view);

                %% Draw dots based on condition and viewing parameters
                if view == 0
                    pa.dotPosition = [pa.current_stimulus(:,1,fn), pa.current_stimulus(:,3,fn)].*VP.pixelsPerMm;
                    
                else
                    pa.dotPosition = [pa.current_stimulus(:,2,fn), pa.current_stimulus(:,3,fn)].*VP.pixelsPerMm;
                    
                end
                
                switch pa.whichCondition
                    case{'comb'}
                        Screen('DrawDots',VP.window, pa.dotPosition', pa.current_stimulus(:,4,fn), colors', [VP.Rect(3)/2, VP.Rect(4)/2], 2);
                        if view == 0 && pa.photo_align
                            Screen('DrawDots',VP.window, [VP.Rect(1)+25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                        elseif view == 1 && pa.photo_align
                            Screen('DrawDots',VP.window, [VP.Rect(3)-25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                        end
                    case {'monoL'}
                        if view == 0 % only draw on this trial's eye
                            Screen('DrawDots',VP.window, pa.dotPosition', pa.current_stimulus(:,4,fn), colors', [VP.Rect(3)/2, VP.Rect(4)/2], 2);
                            if pa.photo_align
                                Screen('DrawDots',VP.window, [VP.Rect(1)+25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                            end
                        end
                        
                    case {'monoR'}
                        if view == 1 % only draw on this trial's eye
                            Screen('DrawDots',VP.window, pa.dotPosition', pa.current_stimulus(:,4,fn), colors', [VP.Rect(3)/2, VP.Rect(4)/2], 2);
                            if pa.photo_align
                                Screen('DrawDots',VP.window, [VP.Rect(3)-25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                            end
                        end
                        
                    case {'bino'}
                        %                             pa.dotPosition(:,1:2) = (pa.dotPosition(:,1:2) + [VP.dstCenter(1), VP.dstCenter(2)]).*VP.pixelsPerMm;
                        Screen('DrawDots',VP.window, pa.dotPosition', pa.current_stimulus(:,4,fn), colors', [VP.Rect(3)/2, VP.Rect(4)/2], 2);
                        if view == 0 && pa.photo_align
                            Screen('DrawDots',VP.window, [VP.Rect(1)+25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                        elseif view == 1 && pa.photo_align
                            Screen('DrawDots',VP.window, [VP.Rect(3)-25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                        end
                        
                    case {'blank'}
                        colors = repmat(backGroundColor,size(colors,1),1);
                        if view == 1 % only draw on this trial's eye
                            Screen('DrawDots',VP.window, pa.dotPosition', pa.current_stimulus(:,4,fn), colors', [VP.Rect(3)/2, VP.Rect(4)/2], 2);
                            if pa.photo_align
                                Screen('DrawDots',VP.window, [VP.Rect(3)-25 VP.Rect(4)-25], 50, [255 255 255],[0 0],2);
                            end
                        end
                        
                end
                %change 2
                DrawBackground(VP);           
                Screen('DrawDots', VP.window, [0 0],pa.fixationDotSize,pa.fixationDotColor,[VP.Rect(3)./2 VP.Rect(4)./2],2);
            end
            
            VP.vbl = Screen('Flip', VP.window, [], dontClear); % Draw frame
            
            fn = fn+1; % Next frame number
            if fn> pa.numFlips % If we have exceeded the frames then the stimulus is complete
                StateID = 4;
                FirstStep = 1;
            end
            
        case 4  %% Get your response
            if FirstStep == 1
                % Clear the screen
                Screen('SelectStereoDrawbuffer', VP.window, 0);
                %change
                DrawBackground(VP);
                %Screen('FillRect', VP.window, VP.backGroundColor);
                Screen('SelectStereoDrawbuffer', VP.window, 1);
                %change
                DrawBackground(VP);
                %Screen('FillRect', VP.window, VP.backGroundColor);
                VP.vbl = Screen('Flip', VP.window, [], dontClear);
                
                % Start timer (e.g., you could record response latency)
                StateTime = GetSecs;
                
                FirstStep = 0;
            else
                % Wait for response....add code here!
                %change 18               
                DrawBackground(VP);
                Screen('DrawDots', VP.window, [0 0],pa.fixationDotSize+3,[1 1 1],[VP.Rect(3)./2 VP.Rect(4)./2],2);
                VP.vbl = Screen('Flip', VP.window, [], dontClear);
                EndT = 0;
                kb.keyIsDown = 0;
                stop = 0;
                while ~kb.keyIsDown && stop ==0                    
                    KbCheck;
                    [kb,stop] = CheckKeyboard(kb); % if response with keyboard
                    [kb,stop] = CheckResponseButton_MRI(kb); % if response with response button MRI
                    pa.response(pa.trialNumber,:) = kb.resp;                   
                    if  EndT >= pa.ITI
                        break
                    end
                    EndT = GetSecs - StateTime;
                end
                pause(pa.ITI-EndT)
                FirstStep = 1;
                StateID = 1;
            end
    end
end
%% Save your data here!!!

accuracy = pa.design(:,3)==pa.response;
for condition = 1:pa.exp_mat(5)
    acc=sum(accuracy(pa.design(:,5)==condition))/size(pa.repeat_design,1)*100;
    disp(['Accuracy - ' char(pa.conditionNames{condition}) ': ' num2str(acc) '%'])
end
filename = fullfile([pwd, '/results/' subject '-' datestr(now,30), '.mat']);
save(filename,'pa');

%% Clean up
RestrictKeysForKbCheck([]); % Reenable all keys for KbCheck:
ListenChar; % Start listening to GUI keystrokes again
ShowCursor;
clear moglmorpher;
Screen('CloseAll');%sca;
clear moglmorpher;
Priority(0);
Datapixx('SetPropixxDlpSequenceProgram',0);
Datapixx('RegWrRd');
Datapixx('Close');

end