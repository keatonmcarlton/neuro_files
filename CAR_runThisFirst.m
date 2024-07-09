%%constants
clear;
folderPath = 'data'; % Path to the folder containing CSC files
bitvolts_to_volts = 3.05e-8; %analog to digital conversion
ms_to_event = 32;
event_to_ms = 0.03125;
fileList = dir(fullfile(folderPath, '*.ncs'));
% % manually sort files yuck
S = struct;
for i = 1:height(fileList)
    temp = ['CSC', num2str(i), '.ncs'];
    s(i).name = temp;
end
[s.folder] = deal(fileList.folder);
[s.date] = deal(fileList.date);
[s.bytes] = deal(fileList.bytes);
[s.isdir] = deal(fileList.isdir);
[s.datenum] = deal(fileList.datenum);
fileList = s;
spikesPerFile = zeros(1, 16);
% Get a list of all NCS files in the specified directory
exportHeaders = [];
exportTimestamps = [];
numChannels = (height(fileList)); % Get the number of NCS files
% oldData array to store reshaped data before common average referencing

for fileIdx = 1:16
    % read data from the NCS file
    filename = fullfile(folderPath, fileList(fileIdx).name); 
    % Get the full file path

    [timestamps, channelNumbers, SampleFrequencies, NumberOfValidSamples, Samples, header] ...
    = Nlx2MatCSC(filename, [1 1 1 1 1], 1, 1, []);
    %this function reads neuralynx data set into matlab (.csc file)
    exportHeaders = [exportHeaders header];
    if fileIdx == 1
        oldData = zeros(512 * length(Samples), numChannels); % Initialize oldData array
        exportChannels = channelNumbers;
    else
        exportChannels = [exportChannels; channelNumbers];
    end
    
    
    Samples = (Samples);
    timestamps = (timestamps);
    oldData = single(oldData);
    %%reducing space complexity, can increase later

    reshapedData = (reshape((Samples), [], 1)); 
    % reshape data and store it in the oldData array (as a column)
    % reshape as a column array

    oldData(:, fileIdx) = (reshapedData); 
    % store in oldData
end
%%now we have our data in a usable format. we can edit and perform
%%noise detection and reduction on this data set now

channelNumbers = (channelNumbers);
%%reducing memory requirement, can increase later

oldData = (oldData * bitvolts_to_volts * 1e6);
%our data, as given from the header in the files, is in bitvolts. this
%converts it into microvolts.

%%now what we want to perform is Coherence-based Common Average Referencing
%%we take the average across the rows and state that any commonalities
%%among the electrodes are "noise" (overgeneralizing for now) to get us a
%%decent idea of the noise floor so we can subtract noise.

Average = single(mean(oldData(:, :), 2));
%average across all rows

newData = oldData - Average;
%subtract the common average

numChannels = 1; %size(oldData, 2);

%How many files we have. useful for iterating

%%debug options%%

Tread = 1;
%How many samples we want to downscale by the factor of (quicker operations)

upper_limit = 500;   lower_limit = -upper_limit; 
% y-axis, optional. good for maintaining scale in before/after

sampling_rate = 32e3; %assume 32kHz
    %use this if you want accurate time domain

time_axis_ms = double(0:size(newData, 1)-1) * 1000 / sampling_rate;
%each data point = .03125ms (reciprocal of 32000khz)
%also assumes newData columns are all same size. they better be. you will
%get an error if not

starting = 3.41754;
ending = 3.41762;

%adjusts window size and position. you can set this to 1 and end
%respectively if you want the full file

%startingIndex = find(starting * 1e5 == time_axis_ms);
startingIndex =1 ;
%endingIndex = find(ending * 1e5 == time_axis_ms);
endingIndex = length(time_axis_ms);

%%end debugging options%%

for i = 1:16
    fileName = [num2str(i), '.ncs'];
    outputData = int16(reshape(newData(:, i), 512, [])/(bitvolts_to_volts*1e6));
    outputData = double(outputData);
    Mat2NlxCSC(fileName, 0, 1, 1,...
    [1 1 1 1 1 1], timestamps, (exportChannels(i,:)-1),...
    SampleFrequencies, NumberOfValidSamples, outputData, exportHeaders(:,i));
end

figure;
for i = 1:numChannels
    subplot(numChannels, 1, i);
    plot(time_axis_ms(startingIndex:Tread:endingIndex), ...
        oldData(startingIndex:Tread:endingIndex, i));
    %here you might replace "end" with "endingIndex" and at the others

    xlabel("Time(ms)");
    ylabel("Raw Voltage(uV)");
    ylim([lower_limit upper_limit]);
    pngFileName = ['CSC_', num2str(i), ' before CAR'];
    title(['CSC ', num2str(i), ' before CAR']);
    ax = gca;
    ax.XAxis.Exponent = 0;
    %%saveas(gcf, pngFileName, 'png');
end
figure;
plot(time_axis_ms(startingIndex:Tread:endingIndex), ...
    Average(startingIndex:Tread:endingIndex));

xlabel("Time(ms)");
ylabel("Averaged Voltage(uV)");
ylim([lower_limit upper_limit]);
pngFileName = 'Average of all';
title('Average of all');
ax = gca;
ax.XAxis.Exponent = 0;
%%saveas(gcf, pngFileName, 'png');
%in case you want to save the image

sigmaVals = std(newData);
figure;
for i = 1:numChannels
    subplot(numChannels, 1, i);
    plot(time_axis_ms(startingIndex:Tread:endingIndex), ...
        newData(startingIndex:Tread:endingIndex, i));

    xlabel("Time(ms)");
    ylabel("Raw Voltage - CAR(uV)");
    ylim([lower_limit upper_limit]);
    pngFileName = ['CSC_', num2str(i), ' after CAR'];
    title(['CSC ', num2str(i), ' after CAR']);
    ax = gca;
    ax.XAxis.Exponent = 0;
    %%saveas(gcf, pngFileName, 'png');
end