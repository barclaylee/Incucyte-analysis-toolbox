%% To modify the layout the measurements made by Imaris
% This script takes the Imaris export csv file where all the measurement
% are listed time point after time point and re-shuffle them into collated
% columns with one track per column
clear all;
close all; 

%% Loading and various parameters
time_scale = 2; % time interval (in min)

[filename, path, ~] = uigetfile('.csv'); %select Position file
delimiter = ',';
% formatSpec = '%f%f%f%s%s%s%f%s%s%[^\n\r]'; % Important: the 6th column (TrackID) is imported as a STRING not a number
% Read file as raw text
raw_data = fileread([path filename]);
raw_data_split = regexp(raw_data, '\n', 'split');

%detect start line
startRow = 2 + find(~cellfun('isempty', regexp(raw_data_split,'====')));
disp(sprintf('Detected row %d as start of data...', startRow));

%extract header line
header_line = regexp(raw_data_split{startRow-1}, delimiter, 'split');
header_line = replace(header_line, {' ', '[', ']'}, '');
header_line = header_line(cellfun('isempty', regexp(header_line,'[\n\r]')));

%construct formatSpec for textscan()
formatSpec = '';
for i=1:length(header_line)
    if regexp(header_line{i}, 'Position|Time')
        formatSpec = [formatSpec '%f'];
    else
        formatSpec = [formatSpec '%s'];
    end
end
formatSpec = [formatSpec '%[^\n\r]'];

fileID = fopen([path filename],'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);

Extracted_data = table(dataArray{1:length(header_line)}, 'VariableNames', header_line);

%% Separate the main table into individual tables per TruelyUniqueName

% [TUN, TUN_idx_last, TUN_idx] = unique(Extracted_data(:,13),'stable'); % Use this line if you've generated unique TrackIDs above
[TUN, TUN_idx_last, TUN_idx] = unique(Extracted_data(:,'TrackID'),'stable');
disp(['Number of trajectories: ', mat2str(height(TUN))]);
unique_idx = accumarray(TUN_idx(:),(1:length(TUN_idx))',[],@(x) {sort(x)});
textprogressbar('Progress:   ');
indicator_progress = 0;
tracks = {};
for jj = 1:height(TUN);
    temporary_table=Extracted_data(unique_idx{jj},:);
    temporary_track=[temporary_table.Time*time_scale temporary_table.PositionX temporary_table.PositionY];
    % filename_export = strjoin([pathname '/' temporary_table.TruelyUniqueName(1) '.csv'],''); % Use this line if you've generated unique TrackIDs above
    tracks = cat(1, tracks, temporary_track);
    
    indicator_progress = indicator_progress + (100/height(TUN));
    textprogressbar(indicator_progress);
end
textprogressbar(' Done');
clear jj indicator_progress TUN* unique_idx Extracted_data pathname

str_header = min(find(filename == '_'));
save([path filename(1:str_header) 'tracks_for_MSDanalyzer.mat'], 'tracks');
disp(['Wrote: ' filename(1:str_header) 'tracks_for_MSDanalyzer.mat']);

clearvars -except tracks path filename str_header
%% Analyze tracks with MSD analyzer
N_DIM = 2;

ma = msdanalyzer(N_DIM, 'µm', 'min');
ma = ma.addAll(tracks);

% Plot trajectories
[hps, ha] = ma.plotTracks;
ma.labelPlotTracks(ha);

%Compute and plot MSD

ma = ma.computeMSD;
figure
hmsd = ma.plotMeanMSD(gca, true);

%Calculate power law of MSD fit
ma = ma.fitLogLogMSD(0.25);
ma.loglogfit

r2fits = ma.loglogfit.r2fit;
alphas = ma.loglogfit.alpha;
R2LIMIT = 0.8;

%Separate tracks by alpha value and r2 value
constrained = find(alphas < 0.75 & r2fits > R2LIMIT);
brownian = find(alphas >= 0.75 & alphas < 1.5 & r2fits > R2LIMIT);
directed = find(alphas >= 1.5 & r2fits > R2LIMIT);

total_sig = size(constrained,1) + size(brownian,1) + size(directed,1);

tracks_constrained = ma.tracks(constrained);
tracks_brownian = ma.tracks(brownian);
tracks_directed = ma.tracks(directed);

ma_const = msdanalyzer(N_DIM, 'µm', 'min');
ma_const = ma_const.addAll(tracks_constrained);

ma_brown = msdanalyzer(N_DIM, 'µm', 'min');
ma_brown = ma_brown.addAll(tracks_brownian);

ma_dir = msdanalyzer(N_DIM, 'µm', 'min');
ma_dir = ma_dir.addAll(tracks_directed);

subplot 131, [hps,ha] = ma_const.plotTracks; title(sprintf('constrained: n=%d',size(constrained,1)));
subplot 132, [hps,ha] = ma_brown.plotTracks; title(sprintf('brownian: n=%d',size(brownian,1)));
subplot 133, [hps,ha] = ma_dir.plotTracks; title(sprintf('directed: n=%d',size(directed,1)));

ma_const = ma_const.computeMSD;
ma_brown = ma_brown.computeMSD;
ma_dir = ma_dir.computeMSD;

figure;
subplot 131, ma_const.plotMeanMSD(gca, (size(constrained,1) > 0)); title(sprintf('constrained: n=%d',size(constrained,1)));
subplot 132, ma_brown.plotMeanMSD(gca, (size(brownian,1) > 0)); title(sprintf('brownian: n=%d',size(brownian,1)));
subplot 133, ma_dir.plotMeanMSD(gca, (size(directed,1) > 0)); title(sprintf('directed: n=%d',size(directed,1)));

figure;
subplot 131, ma_const.plotMSD(gca); title(sprintf('constrained: n=%d',size(constrained,1)));
subplot 132, ma_brown.plotMSD(gca); title(sprintf('brownian: n=%d',size(brownian,1)));
subplot 133, ma_dir.plotMSD(gca); title(sprintf('directed: n=%d',size(directed,1)));

save([path filename(1:str_header) 'MSD_analysis.mat']);
disp(['Wrote: ' filename(1:str_header) 'MSD_analysis.mat']);