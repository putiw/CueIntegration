function VP = SetupDisplay_NYUAD(skipSync,backGroundColor,Display)
if 1 == skipSync %skip Sync to deal with sync issues
    Screen('Preference','SkipSyncTests',1);
end

AssertOpenGL;
InitializeMatlabOpenGL(0,3);
PsychImaging('PrepareConfiguration');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINE DISPLAY SPECIFIC VIEWING CONDITIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch(Display) %Display Parameters
        
    case 0 %Lowell's Macbook
        VP.screenDistance = 570;   %mm
        VP.IOD = 60;               %mm
        VP.screenWidthMm = 332.5;      %mm
        VP.screenHeightMm = 207.8;     %mm
        VP.RefreshRate = 60;       % hz % Note that this is not necessary - the variable frameRate is defined below automatically but needs to be manually defined for macbooks
        VP.whiteValue = 255;
        VP.stereoMode = 8;         % set to 1 for a propixx
        VP.multiSample = 32;       % PTB will change automatically to max supported on your display
    case 1 % NYUAD
        VP.screenDistance = 880;   %mm
        VP.IOD = 62.5;               %mm
        VP.screenWidthMm = 711;
        %332.5;      %mm
        VP.screenHeightMm = VP.screenWidthMm*9/16; %207.8;     %mm
        % VP.RefreshRate = 60;       % hz % Note that this is not necessary - the variable frameRate is defined below automatically but needs to be manually defined for macbooks
        VP.whiteValue = 255;
        VP.stereoMode = 8;         % set to 1 for a propixx
        VP.multiSample = 32;       % PTB will change automatically to max supported on your display
    case 2 % puti laptop
        VP.screenDistance = 570;   %mm
        VP.IOD = 60;               %mm
        VP.screenWidthMm = 332.5;      %mm
        VP.screenHeightMm = 207.8;     %mm
        VP.RefreshRate = 60;       % hz % Note that this is not necessary - the variable frameRate is defined below automatically but needs to be manually defined for macbooks
        VP.whiteValue = 255;
        VP.stereoMode = 4;         % set to 1 for a propixx
        VP.multiSample = 32;       % PTB will change automatically to max supported on your display

end %Display Parameters Switch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SETUP PSYCHTOOLBOX WITH OPENGL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GL;                            %Global GL Data Structure, Cannot 'BeginOpenGL' Without It.

%PsychDefaultSetup(2);                 %Calls AssertOpenGL & performs other boilerplate setup operations
%InitializeMatlabOpenGL(1);            %Setup PsychToolbox for 3D rendering support; (0,0) disables error checking to speed up processes; (1) initializes MOGL_Wrapper
%PsychImaging('PrepareConfiguration'); %Prepare pipeline for configuration.
Screen('Preference', 'Verbosity', 3); % Increase level of verbosity for debug purposes:
Screen('Preference','VisualDebugLevel', 3);%control verbosity and debugging, level:4 for developing, level:0 disable errors
VP.screenID = max(Screen('Screens'));    %Screen for display.

% switch Display    
%     case 1
%         PsychImaging('AddTask','General','UseDataPixx'); % Tell PTB we want to display on a DataPixx device.
%         
%         if ~Datapixx('IsReady')
%             Datapixx('Open');
%         end
% 
%         
%         if (Datapixx('IsVIEWPixx'))
%             Datapixx('EnableVideoScanningBacklight');
%         end
%          Datapixx('EnableVideoStereoBlueline');
%          Datapixx('SetVideoStereoVesaWaveform', 2);      % If driving NVIDIA glasses
%          
%          if Datapixx('IsViewpixx3D') && UseDCdriving
%              Datapixx('EnableVideoLcd3D60Hz');
%          end
%         Datapixx('RegWrRd');        
%     case 2
%         PsychImaging('AddTask','General','UseDataPixx'); % Tell PTB we want to display on a DataPixx device.        
%      
%         if ~Datapixx('IsReady')            
%             Datapixx('Open');
%         end
%         Datapixx('DisablePropixxLampLed');
%         Datapixx('SetPropixxDlpSequenceProgram',2);        
%         Datapixx('EnablePropixxLampLed');
%         Datapixx('RegWr');
% end

VP.Display = Display;
if Display == 0
    [VP.window,VP.Rect] = PsychImaging('OpenWindow',VP.screenID,[backGroundColor],[],[],[], VP.stereoMode, VP.multiSample);
else
    [VP.window,VP.Rect] = PsychImaging('OpenWindow',VP.screenID,[backGroundColor],[],[],[], VP.stereoMode, VP.multiSample);
end
% [VP.window, VP.Rect] = Screen('OpenWindow',VP.screenID,[backGroundColor],[]); 
[VP.windowCenter(1),VP.windowCenter(2)] = RectCenter(VP.Rect); %Window center
VP.windowWidthPix = VP.Rect(3)-VP.Rect(1);
VP.windowHeightPix = VP.Rect(4)-VP.Rect(2);

% TODO: Check which stereomodes this will be correct for and update
% accordingly
if VP.stereoMode == 4
    VP.screenWidthPix = 2*VP.windowWidthPix;

else
    VP.screenWidthPix = VP.windowWidthPix;
end
VP.screenHeightPix = VP.windowHeightPix;

%Hmmm, Blending needs to be set both within and outside the BeginOpenGL
% context, which seems weird
glBlendFunc(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA); %Alpha blending for antialising
Screen('BeginOpenGL',VP.window); %Setup the OpenGL rendering context
    glViewport(0,0,VP.windowWidthPix,VP.windowHeightPix); %Define viewport
    glDisable(GL.LIGHTING); %Disable lighting; interacts with alpha blending (and often supersedes with unwanted results)
    glEnable(GL.DEPTH_TEST); %glDepthFunc(GL.LESS); %glDepthFunc(GL.LEQUAL); %Occlusion handling
    glEnable(GL.BLEND); glBlendFunc(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA); %Alpha blending for antialising
Screen('EndOpenGL',VP.window);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINE STRUCTURE HOLDING ALL VIEWING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Viewing Parameters
VP.ifi = Screen('GetFlipInterval', VP.window);
if VP.stereoMode
    VP.stereoViews = 1;
else
    VP.stereoViews = 0;
end

% Calculate the width of one eye's view (in deg)
VP.screenWidthDeg = 2*atand(0.5*VP.screenWidthMm/VP.screenDistance);
VP.pixelsPerDegree = VP.screenWidthPix/VP.screenWidthDeg; % calculate pixels per degree
VP.pixelsPerMm = VP.screenWidthPix/VP.screenWidthMm; %% pixels/Mm
VP.MmPerDegree = VP.screenWidthMm/VP.screenWidthDeg;
VP.degreesPerMm = 1/VP.MmPerDegree;

if Display == 0 
    VP.frameRate = VP.RefreshRate;
elseif Display ==2
    VP.frameRate = VP.RefreshRate;
else
    % get frame rate of display
    VP.frameRate = Screen('FrameRate',VP.window);
end
screenWindow = [0 0 1920 1080];
if VP.stereoMode == 4
    [VP.window,VP.Rect]=PsychImaging('OpenWindow', VP.screenID, backGroundColor, screenWindow, [], [], VP.stereoMode, VP.multiSample);
    SetStereoSideBySideParameters(VP.window, [0,0], [1, 0.5], [1,0], [1, 0.5]);
end
    
    
% VP.frameRate
% Define some colors - These are wrong in GL Context - eg glClearColor [0,1]
VP.white= WhiteIndex(VP.screenID);
VP.black= BlackIndex(VP.screenID);
VP.gray= (VP.white+VP.black)/2;
if round(VP.gray)==VP.white
    VP.gray=VP.black;
end
VP.inc=VP.white-VP.gray;

%change 2
% Set up alpha-blending for smooth (anti-aliased) drawing of dots:
Screen('BlendFunction', VP.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINE FRUSTUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the size and aspect ratio of the viewport:
ar=RectHeight(VP.Rect) / RectWidth(VP.Rect);
VP.halfWidth = VP.screenWidthMm/2; %ds.dotPitch*RectWidth(ds.VP.Rect)/2; % 130/2; % for DepthQ % in Mm
VP.halfHeight = ar * VP.halfWidth; % ds.dotPitch*RectHeight(winRect)/2;
VP.viewingAngle = atan(VP.halfWidth/VP.screenDistance); % br: Half the field of view (in radians)

% Position of the frustum (used for clipping only)
VP.near = 250; %25; %ds.viewingDistance - 1.1*ds.horopter; %-1; %eps;  %% the 1.1 factor prevents clipping of the paddle as it orbits
VP.far  = 2500; % in Mm
VP.halfFrustumWidth = VP.near * tan(VP.viewingAngle); % in Mm
VP.halfFrustumHeight = ar * VP.halfFrustumWidth; % in Mm

% Fixation cross/point parameters
VP.fixationSquareHalfSize = 0.5 * VP.pixelsPerDegree; % in degrees
VP.fixationLineWidth = 1; % in pixels?
VP.fixationDotDiameter = 3; % In pixels? %

VP.fixationCrosshairs = VP.fixationSquareHalfSize .* [-1.0 -0.5 1.0 0.5  1.0  0.5 -1.0 -0.5 0 0  -1.0 -0.5 1.0 0.5  1.0  0.5 -1.0 -0.5  0  0 ;... % [x1, ..., xn;
    1.5  1.0 1.5 1.0 -1.5 -1.0 -1.5 -1.0 2 1.0 1.5  1.0 1.5 1.0 -1.5 -1.0 -1.5 -1.0 -2 -1.0]; % [y1, ..., yn]
VP.fixationSquare = VP.fixationSquareHalfSize .* [-1 1 1 1 1 -1 -1 -1; 1 1 1 -1 -1 -1 -1 1];
VP.fixationCrosshairColors = [0 0 0 255; 0 0 0 255; 0 0 0 255; 0 0 0 255; 0 0 0 255; 0 0 0 255; 0 0 0 255; 0 0 0 255; 255 0 0 255; 255 0 0 255]';

%%%% AR LAB FRUSTUM INFO NOT CURRENTLY USED %%%%%
%The frustum is determined by projecting the screen boundaries onto the near clipping plane
clipNear = 0.1;     %Near clipping plane (mm)
clipFar = 10000;    %Far clipping plane (mm)

% Initial flip to sync us to VBL and get start timestamp:
VP.vbl = Screen('Flip', VP.window);
VP.tstart = VP.vbl;
VP.telapsed = 0;