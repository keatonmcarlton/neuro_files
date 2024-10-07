sigmaVals = std(newData);
cutoffConstant =6;
thresholds(1, :) = cutoffConstant * sigmaVals;
preSpike = round(0.001 * 32000);
postSpike = 2 * preSpike;
parfor ch = 1:16
    signal = newData(:, ch);

    spikeIndices = find(signal < -thresholds(ch));
    minDistance = round(0.001 * 32000);

    spikeIndices = spikeIndices([true; diff(spikeIndices) > minDistance]);

    validSpikes = spikeIndices(spikeIndices > preSpike & spikeIndices + postSpike <= length(signal));

    waveforms = arrayfun(@(idx) signal(idx - preSpike:idx + postSpike), validSpikes, 'UniformOutput',false);

    spikeTimes{ch} = validSpikes / 32000;

    spikeWaveforms{ch} = cell2mat(waveforms');

    numSpikes(ch) = length(validSpikes);
    fprintf('Channel %d: Detected %d spikes\n', ch, numSpikes(ch));
end
fs = 32000;
ch = 1;
signal = newData(:, 1);

grid on;
hold off;

figure;
hold on;
windowSize = round(0.006 * 32000);
halfWindow = floor(windowSize / 2);
spikeIndices = round(spikeTimes * fs);
for i = 1: length(spikeIndices)
    idx = spikeIndices(i);
    for idx = spikeIndices
        if idx > halfWindow && (idx + halfWindow) <= length(signal)
            plot(-halfWindow:halfWindow, signal(idx-halfWindow:idx+halfWindow), 'Color', [0.7 0.7 1], 'LineWidth', 1);
        end
    end
end
% for j = 1:16
%     h5create('NCS_HDF5.h5', ['/channel' num2str(j)], 19543040);
%     h5write('NCS_HDF5.h5', ['/channel' num2str(j)], newData(:, 1));
% end

