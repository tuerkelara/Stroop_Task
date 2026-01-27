% Stroop Task Implementation (by John Ridley Stroop)
% Responses with the keys
% Introduction
% Idea: 
% - Fixcross (500 ms)
% - Stimulus (Word in color, kb wait, max. 4 sec.)
% - measure RT djkjkkjfdjfkfjjjkdk
% - Feedback
% - at the end of the task: results as feedback (false, correct)
% - Intertrial Interval (500 ms)

% Conditions:
% - Congruent (red in red)
% - Incongruent (red in blue)

% Keys:
% red -> d
% green -> g
% blue -> j
% yellow -> k

% TODO:
% Trials as a list -> load the list
% Randomising the trials
% Save the results as .xlsx
% =======================================================================

% === Biodata ===
prompt = {
    'VP-Nummer:'
    'Geburtsdatum (TT.MM.JJJJ):'
    'Geschlecht (m/w/div):'
};

dlgtitle = 'Teilnehmerdaten';
fieldsize = [1 50];
definput = {'VP00', '00.00.0000', 'm'};

answer = inputdlg(prompt, dlgtitle, fieldsize, definput);

% error when empty
if isempty(answer)
    error('Experiment abgebrochen.');
end

vp        = answer{1};
birthday = answer{2};
gender   = answer{3};


% === window ===

Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
screenNumber = max(screens);

[window, windowRect] = Screen('OpenWindow', screenNumber, [128 128 128]);

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

img = imread('Keys.png');
texture = Screen('MakeTexture', window, img);
Screen('DrawTexture', window, texture);
DrawFormattedText(window, instructionText, 'center', 'center');
Screen('Flip', window);

% Warten auf Leertaste
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
fixcrossTex = Screen('MakeTexture', window, fixCross);
fixRect = CenterRectOnPointd([0 0 fixSize fixSize], xCenter, yCenter);


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
nTrials = size(trials,1);
randIdx = randperm(nTrials);
trials = trials(randIdx,:);

% Results 
results = cell(nTrials,7);

% Fliptime
tPre = 0.5; % Fixcross
ITI = 0.5;
maxRespTime = 3;

% === Trial Loop ===
% Fixcross
for t = 1:nTrials
Screen('DrawTexture', window, fixcrossTex, [], fixRect);
    Screen('Flip', window);
    WaitSecs(tPre);
    
    % Stimulus
    DrawFormattedText(window, trials{t,2}, 'center', 'center', trials{t,3});
    stimOn = Screen('Flip', window);
    
    % Wait for keypress
    keyPressed = 0;
    while ~keyPressed && GetSecs - stimOn < maxRespTime
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            rt = GetSecs - stimOn;
            keyPressed = 1;
            pressedKey = find(keyCode);
        end
    end
    
    % Check Correctness
    word = trials{t,2};
    color = trials{t,3};
    
    if strcmp(word,'ROT') && pressedKey == keys.red
        correct = 1;
    elseif strcmp(word,'GRUEN') && pressedKey == keys.green
        correct = 1;
    elseif strcmp(word,'BLAU') && pressedKey == keys.blue
        correct = 1;
    elseif strcmp(word,'GELB') && pressedKey == keys.yellow
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
    Screen('Flip', window);
    WaitSecs(ITI);
    
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
    otherwise
        pressedColor = 'UNKNOWN';
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
vpStr = sprintf('%02d', vp);
filename = fullfile(resultsDir,['VP_' vpStr '_Stroop.xlsx']);
writetable(T, filename);

RestrictKeysForKbCheck([]);
Screen('CloseAll');
disp('Experiment beendet. Ergebnisse gespeichert!');