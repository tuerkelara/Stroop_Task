% Stroop Task Implementation (by John Ridley Stroop)
% === READ.ME ===
% Introduction
% Idea: 
% - Fixcross (500 ms)
% - Stimulus (Word in color, kb wait, max. 4 sec.)
% - measure RT
% - Feedback
% - at the end of the task: results as feedback (false, correct)
% - ITI (500 ms)

% Conditions:
% - Congruent (red in red)
% - Incongruent (red in blue)

% Keys:
% red -> d
% green -> g
% blue -> j
% yellow -> k
% =======================================================================

% === Demodata ===
% Dialogfenster für Demografische Daten
prompt = {
    'VP-Nummer: (VP_00)'
    'Geburtsdatum (TT.MM.JJJJ):'
    'Geschlecht (m/w/div):'
};

dlgtitle = 'Versuchspersonendaten';
fieldsize = [1 50];
definput = {'VP_00', '00.00.0000', 'm'};

answer = inputdlg(prompt, dlgtitle, fieldsize, definput);

% error when empty -> x, "cancel" ({})
if isempty(answer)
    error('Experiment abgebrochen.');
end

% Initial variables for Datasheet
vp       = answer{1};
birthday = answer{2};
gender   = answer{3};

% Check up for false data in birthday, gender
try
    datetime(birthday,'InputFormat','dd.MM.yyyy');
catch
    error('Bitte Datum im Format TT.MM.JJJJ eingeben.');
end

gender = lower(answer{3});
if ~ismember(gender, {'m','w','div'})
    error('Geschlecht muss m, w oder div sein.');
end


% === window ===
ListenChar(1); % keys not in MatLab
% Task on Monitor
screens = Screen('Screens');
screenNumber = max(screens);
Screen('Preference', 'SkipSyncTests', 1);
[window, windowRect] = Screen('OpenWindow', screenNumber, [128 128 128]);
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

[xCenter, yCenter] = RectCenter(windowRect);

% === Instructions ===
Screen('TextSize', window, 40);
Screen('TextFont', window, 'Arial');

instructionText = [ ...
    'Willkommen zum Experiment!\n\n' ...
    'Ihre Aufgabe ist es, die FARBE des Wortes\n' ...
    'so schnell und so genau wie möglich anzugeben.\n\n' ...
    'Bitte IGNORIEREN Sie die Bedeutung des Wortes.\n\n' ...
    'Tastenbelegung:\n' ...
    '\n\n\n\n' ...
    '\n' ...
    '\n' ...
    '\n' ...
    '\n' ...
    '\n' ...
    '\n' ...
    '\n\n\n\n' ...
    'Drücken Sie die LEERTASTE, um zu beginnen.'
];

% Load PNG for Instruction -> texture for better timing
img = imread('Keys.png');
texture = Screen('MakeTexture', window, img); 
Screen('DrawTexture', window, texture);
DrawFormattedText(window, instructionText, 'center', 'center');
Screen('Flip', window);

% Wait on Space
KbReleaseWait;
while true
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('space'))
        break;
    end
end

% === Fixcross Matrix ===
fixSize = 100;
mid = fixSize/2;
fixCross = ones(fixSize,fixSize)* 128;
fixCross(mid-2:mid+2,:) = 0;
fixCross(:,mid-2:mid+2) = 0;
% Change in Texture
fixcrossTex = Screen('MakeTexture', window, fixCross);
fixRect = CenterRectOnPointd([0 0 fixSize fixSize], xCenter, yCenter); % fit in mid 


% === Keys ===
KbName('UnifyKeyNames');
keys.red    = KbName('d');
keys.green  = KbName('f');
keys.blue   = KbName('j');
keys.yellow = KbName('k');
RestrictKeysForKbCheck([KbName('d'), KbName('f'), KbName('j'), KbName('k')]);

% === Trials ===
Screen('TextSize', window, 100);
trials = {};
trialNumber = 1;
words = {'ROT', 'GRUEN', 'BLAU', 'GELB'};
colors = {[255 0 0], [0 255 0], [0 0 255], [255 255 0]};
colorNames = {'ROT', 'GRUEN', 'BLAU', 'GELB'};

for i = 1:length(words)
    for z = 1:length(colors)
        if strcmp(words{i}, colorNames{z})
            congruency = 'Congruent';
        else
            congruency = 'Incongruent';
        end
        trials(end+1,:) = {trialNumber, words{i}, colors{z}, colorNames{z}, congruency};
        trialNumber = trialNumber + 1;
    end
end


% === Randomize Trials ===
nTrials = size(trials,1); % 1 -> size_row
randIdx = randperm(nTrials);
trials = trials(randIdx,:);

% Results 
results = cell(nTrials,10);

% Fliptime
tPre = 0.5; % Fixcross
ITI = 0.5; % Inter-Trial Interval 
maxRespTime = 1.5;

% === Trial Loop ===

for t = 1:nTrials
    % Fixcross
    Screen('DrawTexture', window, fixcrossTex, [], fixRect);
    Onset = Screen('Flip', window);
    
    % Stimulus
    DrawFormattedText(window, trials{t,2}, 'center', 'center', trials{t,3});
    stimOn = Screen('Flip', window, Onset + tPre);
    
    % Reactiontime
    keyPressed = 0;
    pressedKey = NaN;
    rt = "na";
    deadline = stimOn + maxRespTime;
    
    while ~keyPressed && GetSecs < deadline
        [keyIsDown, endRT, keyCode] = KbCheck;
        if keyIsDown
            rt = endRT - stimOn;
            keyPressed = 1;
            pressedKey = find(keyCode); % Info about pressed key
        end
    end
    
    % Check Correctness
    word = trials{t,2};
    color = trials{t,4};
    
    if strcmp(color,'ROT') && pressedKey == keys.red
        correct = 1;
    elseif strcmp(color,'GRUEN') && pressedKey == keys.green
        correct = 1;
    elseif strcmp(color,'BLAU') && pressedKey == keys.blue
        correct = 1;
    elseif strcmp(color,'GELB') && pressedKey == keys.yellow
        correct = 1;
    else
        correct = 0;
    end

    
    % Feedback
    if correct
        DrawFormattedText(window, 'Richtig!', 'center', 'center', [0 0 0]);
    else
        DrawFormattedText(window, 'Falsch!', 'center', 'center', [0 0 0]);
    end
    Onset_feedback = Screen('Flip', window);
    Screen('Flip', window, Onset_feedback + ITI);
    
    % Translate number on keyboard to color
    if isnan(pressedKey)
        pressedColor = 'MISSED';
        correct = 0; 
    else
        keyName = KbName(pressedKey);
        switch keyName
        case 'd'
            pressedColor = 'ROT';
        case 'f'
            pressedColor = 'GRUEN';
        case 'j'
            pressedColor = 'BLAU';
        case 'k'
            pressedColor = 'GELB';
        end
    end
    
    results{t,1} = vp;
    results{t,2} = birthday;
    results{t,3} = gender;
    results{t,4} = trials{t,1};
    results{t,5} = trials{t,2};
    results{t,6} = trials{t,4};
    results{t,7} = trials{t,5};
    results{t,8} = pressedColor;
    results{t,9} = rt;
    results{t,10} = correct;
end

resultsDir = 'Stroop_Results';
T = cell2table(results, 'VariableNames',{'VP','Geburtstag','Geschlecht','Trial','Word','Color','Condition','KeyPressed','RT','Correct'});
filename = fullfile(resultsDir,[vp '_Stroop.xlsx']);
writetable(T, filename);

RestrictKeysForKbCheck([]);
Screen('CloseAll');
ListenChar(0);
Priority(0);
disp('Experiment beendet. Ergebnisse gespeichert!');