%%todo search depolarization detection
%%negative detection cutoff

ms_to_event = 32;
event_to_ms = 0.03125;
folderPath = 'images_spikes';
files = dir(fullfile(folderPath, '*'));
targetFolder = fullfile(fileparts(mfilename('fullpath')), folderPath);
filenum = 1;
%filenum = 16;

cutoffConstant =5;
cutoffVals(1, :) = cutoffConstant * sigmaVals;
upperCutoff = 150;
cutoffVals(2, :) = upperCutoff; % 15 * sigmaVals

eventArr = zeros(height(newData), 6); %5);
% eventArr = [fileOrigin, spike zero crossing, depolarization end]


png = 1;
i = 1;
spikes = 0;
b = [0,0,0];
%for i =1: length(newData)
    cutoff = cutoffVals(i);
    for j=2:height(newData)
        zeroCrossingIndices = [0,0,0];
        if (newData(j, i) > cutoff && newData(j-1, i) <= upperCutoff)
            % Check for the next 2 zero crossings after the threshold
            zeroCrossingIndices(1) = find(newData(j:-1:1, i) <= 0, 1);
            zeroCrossingIndices(2) = find(newData(j:end, i) <= 0, 1) + j;
            zeroCrossingIndices(3) = find(newData(zeroCrossingIndices(2):end, i) >= 0, 1)...
            + zeroCrossingIndices(2);
            if ~isempty(zeroCrossingIndices) && ~isequal(zeroCrossingIndices, b)
                % Calculate the distance between the two zero crossings
                crossingDistance = (zeroCrossingIndices(3) - ...
                zeroCrossingIndices(2))*event_to_ms;
                % Check if the zero crossings are within the range
                if crossingDistance >= (1)&& crossingDistance <= (5)
                    % Update event index and mark the event
                    firstEvent = j;
                    secondEvent = zeroCrossingIndices(2) - 1;
                    thirdEvent = zeroCrossingIndices(3) - 1;

                    eventArr(j, 1) = i;
                    eventArr(j, 2) = firstEvent;
                    eventArr(j, 3) = secondEvent;
                    eventArr(j, 4) = thirdEvent;

                    % want to save new value in a 6th row
                    % peak to trough value is max value from 1st-2nd
                    % subtract min value from 2nd-3rd
                    spikeMaxValue = max(newData( ...
                        firstEvent:secondEvent, i));
                    eventArr(j, 5) = spikeMaxValue;
                    spikeMinValue = min(newData( ...
                        secondEvent:thirdEvent, i));
                    peakToTrough = spikeMaxValue - spikeMinValue;
                    eventArr(j, 6) = peakToTrough;
                    if(spikeMaxValue < upperCutoff)
                        j = zeroCrossingIndices(3) - 1;
                        spikes = spikes + 1;
                    else
                        eventArr(j, :) = [0,0,0,0,0];
                        j= j+1;
                    end
                    % advance j to the second zero crossing
                end
            else
                % Move to the next element if fewer than 2 zero crossings are found
                j = j + 1;
            end
            %zeroCrossingIndices = [0,0];
        elseif (newData(j,i) < -cutoffVals(i) && newData(j-1, i) >= cutoffVals(i))
                % Check for the next zero crossing after the threshold
            zeroCrossingIndices(1) = find(newData(j:-1:1, i) >= 0, 1);
            zeroCrossingIndices(2) = find(newData(j:end, i) >= 0, 1) + j;
            if ~isempty(zeroCrossingIndices) && ~isequal(zeroCrossingIndices, b)
                % Calculate the distance between the two zero crossings
                crossingDistance = (zeroCrossingIndices(2) - ...
                zeroCrossingIndices(1))*event_to_ms;
                % Check if the zero crossings are within the range
                if crossingDistance >= (1)&& crossingDistance <= (5)
                    % Update event index and mark the event
                    firstEvent = zeroCrossingIndices(1) - 1;
                    secondEvent = zeroCrossingIndices(2) - 1;
                    thirdEvent = -1;

                    eventArr(j, 1) = i;
                    eventArr(j, 2) = firstEvent;
                    eventArr(j, 3) = secondEvent;
                    eventArr(j, 4) = thirdEvent;

                    spikeMaxValue = mmin(newData( ...
                        firstEvent:secondEvent, i));
                    eventArr(j, 5) = spikeMaxValue;
                    spikeMinValue = min(newData( ...
                        secondEvent:thirdEvent, i));
                    peakToTrough = spikeMaxValue - spikeMinValue;
                    eventArr(j, 6) = peakToTrough;
                    if(spikeMaxValue < upperCutoff)
                        j = zeroCrossingIndices(2) - 1;
                        spikes = spikes + 1;
                    else
                        eventArr(j, :) = [0,0,0,0,0];
                        j= j+1;
                    end
                    % advance j to the second zero crossing
                end
            else
                % Move to the next element if fewer than 2 zero crossings are found
                j = j + 1;
            end
        else
            % Move to the next element if the threshold condition is not met
            j = j + 1;
        end
    end
%end
noise = newData(:, 1);
rms = zeros(1, filenum);
zeroRows = all(eventArr == 0, 2);
eventArr(zeroRows, :) = [];
%trims the fat and makes a noise array

% this checks that no 2 spikes are counted twice
for i = height(eventArr)-1:-1:2
    if eventArr(i, 3) == eventArr(i-1, 3)
        eventArr(i-1, :) = [];
    end
end

spikeRange = [0,0];
for f = 1:filenum
    for popLast = height(eventArr):-1:1
        spikeRange = eventArr(:, [2 4]);
        spikeBegin = eventArr(popLast, 2);
        spikeEnd = eventArr(popLast, 4);
        noise(spikeBegin:spikeEnd) = [];
    end
    guy = noise(:).^2;
    sumOfSquares = sum(guy);
    intermediate = sumOfSquares/height(guy);
    rms(f) = sqrt(intermediate);
end
%this removes all detected spikes from noise array, leaving just the noise
%so we can perform rms to get noise floor


% Extract events of all detected spikes (zeros)
upper_limit = 2e-4;   lower_limit = -upper_limit;
%event array, debugging purposes
spikeIndex = [0,0];

ms_before = 6;
ms_after = 6;
spikes = 0;
%% 
spikeData = zeros( height(eventArr),1+(ms_after+ms_before)*ms_to_event);
spikesPerFile = zeros(1, 16);
for i = 1:1 %num probes
    % Identify rows where the first column is equal to x
    spikesInFile = (eventArr(:, 1) == i);
    % Count the number of such rows
    numEvents = sum(spikesInFile);
    spikesPerFile(1,i) = numEvents;
    for k = 1:numEvents
        % Plot spike (peak and trough) centered around the spike index
        if eventArr(k, 1) == i
            if eventArr(k, 4)==0
                spikeData(k, :) = newData(eventArr(k, 2)-(ms_before*ms_to_event): ...
                (eventArr(k, 2))+(ms_after*ms_to_event), i);
            else
                spikeData(k, :) = newData(eventArr(k, 3)-(ms_before*ms_to_event): ...
                (eventArr(k, 3))+(ms_after*ms_to_event), i);
            end
        end
    end
end

% zeroRows = all(spikeData == 0, 2);
% spikeData(zeroRows, :) = [];
