function scrProp=initialize_projector(background_color)

% Clear the workspace
sca;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));

% Screen Number
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, background_color);
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Perform initial flip to gray background and sync us to the retrace:
vbl = Screen('Flip', window);

% Numer of frames to wait before re-drawing
waitframes = 1;

scrProp.screenNumber = screenNumber;
scrProp.window = window;
scrProp.windowRect = windowRect;
scrProp.xCenter = xCenter;
scrProp.yCenter = yCenter;
scrProp.black = black;
scrProp.white = white;
scrProp.vbl = vbl;
scrProp.ifi=ifi;
scrProp.waitframes = waitframes;