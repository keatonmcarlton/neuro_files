files = dir(fullfile(folderPath, '*'));
folderPath = 'images_of_data';

invisible_figure;
hold on;
snr = zeros(height(spikeData));
%%%% could be more efficient?
%for n = 1:2
    for k = 1:length(files)
        fileName = files(k).name;
        if strcmp(fileName, '.') || strcmp(fileName, '..')
            continue;
        end
        %fullFilePath = fullfile(folderPath, fileName);
        if ~files(k).isdir
            %delete(fullFilePath);
            delete(fullfile('graphs_for_stats', fileName))
            delete(fullfile('images_of_data', fileName))
            %fprintf('Deleted: %s\n', fullFilePath);
        end
    end
%end

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
cd(originalDir);
cd("generated_data\");
cd(uniqueFolder);
mkdir("spikes\");
mkdir("statistics\");
cd("spikes\");
for p = 1:number_of_channels_to_process
    for k = 1:spikesInFile
        snr(k) = eventArr(k, 5)/rms(filenum); %todo, change rms based on probe (file)
        % Plot spike (peak and trough) centered around the spike index
        time_axis_ms = ((1:length(spikeData(k,:))) - ms_before * ms_to_event) * event_to_ms;
        plot(time_axis_ms, spikeData(k, :));
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
ylabel('Voltage (μV)');
title(['Overlayed Spikes (Aligned at Inflection), cutoff:' ...
    num2str(cutoffConstant) ' sigma']);
legend('Neural Signal');
hold off;
%templating graph

png = 1;
for l=1:height(spikeData)
    invisible_figure;
    time_axis_ms = ((1:length(spikeData(l, :))) - ms_before * ms_to_event) * event_to_ms;
    plot(time_axis_ms, spikeData(l, :));
    xline(0,'--b');
    yline(0, '--r');
    xlabel('Time (ms)');
    ylabel('Voltage (μV)');
    title(['Spike Number ' num2str(l) ': SNR:' num2str(snr(l)) ...
        ' cutoff:' num2str(cutoffConstant) 'sigma']);
    legend('Neural Signal');
    saveas(gcf, ['spike number ' num2str(l) '.png']);
    %fprintf(['SNR for spike %f: %c\n',l,num2str(snr(l))]);
    disp(['SNR for spike ', num2str(l),': ',num2str(snr(l))]);
    disp(['Peak-Trough value for spike ', num2str(l), ': ',num2str(eventArr(l,6))])
end
cd .. ;
cd("statistics\");
%individual graphs
folderPath = 'graphs_for_stats';

% need to adjust so that it works for either as an array (like for snr) or is just a
% single value (like for peak-trough)
%disp(['Average SNR: ',(num2str((sum(snr))/spikesInFile))])
%disp(['Average Peak-Trough value: ',(num2str((sum(eventArr(:,6)))/spikesInFile))])
% adjust so that all of the channels are on each graph?
%invisible_figure = figure("Visible", false);
% need to transpose?
histogram((snr(:,1)));
ylabel('Number of Spikes');
xlabel('SNR (N/A)');
title('SNR for spikes in channel 1:');
saveas(gcf, 'SNR histogram.png');

invisible_figure;
bp = boxplot(snr(:,1));
disp(['Minimum SNR value: ', num2str(min(snr(:,1)))]);
disp(['Maximum SNR value: ', num2str(max(snr(:,1)))]);
disp(['Median SNR value: ', num2str(median(snr(:,1)))]);
disp(['25th and 75th Quantile SNR values: ', num2str(quantile(snr(:,1),[0.25,0.75]))]);
disp(['Interquartile range SNR value: ', num2str(iqr(snr(:,1)))]);
disp(['Average SNR value: ', num2str(grpstats(snr(:,1)))]);
ylabel('SNR (N/A)');
title('SNR for spikes in channel 1:');
saveas(gcf, 'SNR boxplot.png');

invisible_figure;
%bar(eventArr(:,6));
boxplot(eventArr(:,6));
disp(['Minimum P-T value: ', num2str(min(eventArr(:,6)))]);
disp(['Maximum P-T value: ', num2str(max(eventArr(:,6)))]);
disp(['Median P-T value: ', num2str(median(eventArr(:,6)))]);
disp(['25th and 75th Quantile P-T values: ', num2str(quantile(eventArr(:,6),[0.25,0.75]))]);
disp(['Interquartile range P-T value: ', num2str(iqr(eventArr(:,6)))]);
disp(['Average P-T value: ', num2str(grpstats(eventArr(:,6)))]);
disp(['STD of P-T values: ', num2str(std(eventArr(:,6)))]);

ylabel('Peak-Trough (μV)');
title('Peak-Trough value for spikes in channel 1:');
saveas(gcf, 'P-T boxplot.png');
cd(originalDir);