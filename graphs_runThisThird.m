figure;
hold on;
snr = zeros(height(spikeData));
for k = 1:length(files)
    fileName = files(k).name;
    if strcmp(fileName, '.') || strcmp(fileName, '..')
        continue;
    end
    fullFilePath = fullfile(folderPath, fileName);
    if ~files(k).isdir
        delete(fullFilePath);
        fprintf('Deleted: %s\n', fullFilePath);
    end
end

spikes = zeros(1, 16);
% Identify rows where the first column is equal to x
for h=1:height(eventArr)
    for j = 1:16
        if j == eventArr(h, 1)
            spikes(j) = spikes(j) + 1;
        end
    end
end
spikesInFile = sum(spikes);
for p = 1:filenum
    for k = 1:spikesInFile
        snr(k) = eventArr(k, 5)/rms(filenum); %todo, change rms based on probe (file)
        % Plot spike (peak and trough) centered around the spike index
        time_axis_ms = ((1:length(spikeData(k,:))) - ms_before * ms_to_event) * event_to_ms;
        plot(time_axis_ms, spikeData(k, :));
        filePath = fullfile(targetFolder, num2str(png));
        xline(0,'--b');
        yline(0, '--r');
        %saveas(gcf, filePath);
        png= png+1;
    end
end
disp(['Spikes detected: ', num2str(spikes)]);
spikesPerMin = zeros(1, 16);
for m = 1:height(fileList)
    spikesPerMin(m) = spikes(m) / str2double(recordingLength);
end
disp(['Spikes per minute: ', num2str(spikesPerMin)]);
xlabel('Time (ms)');
ylabel('Voltage (mV)');
title(['Overlayed Spikes (Aligned at Inflection), cutoff:' ...
    num2str(cutoffConstant) ' sigma']);
legend('Neural Signal');
hold off;
%templating graph

png = 1;
for l=1:height(spikeData)
    figure;
    time_axis_ms = ((1:length(spikeData(l, :))) - ms_before * ms_to_event) * event_to_ms;
    plot(time_axis_ms, spikeData(l, :));
    filePath = fullfile(targetFolder, ['spike number ' num2str(l) '.png']);
    xline(0,'--b');
    yline(0, '--r');
    xlabel('Time (ms)');
    ylabel('Voltage (mV)');
    title(['Spike Number ' num2str(l) ': SNR:' num2str(snr(l)) ...
        ' cutoff:' num2str(cutoffConstant) 'sigma']);
    legend('Neural Signal');
    saveas(gcf, filePath);
    %fprintf(['SNR for spike %f: %c\n',l,num2str(snr(l))]);
    disp(['SNR for spike ', num2str(l),': ',num2str(snr(l))]);
    disp(['Peak-Trough value for spike ', num2str(l), ': ',num2str(eventArr(l,6))])
end
%individual graphs

% need to adjust so that it works for either as an array (like for snr) or is just a
% single value (like for peak-trough)
disp(['Average SNR: ',(num2str((sum(snr))/spikesInFile))])
disp(['Average Peak-Trough value: ',(num2str((sum(eventArr(:,6)))/spikesInFile))])