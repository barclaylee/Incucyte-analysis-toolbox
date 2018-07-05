% This script takes the Imaris 'Speed' statistic exported csv file where all the measurement
% are listed time point after time point and calculates the arrest
% coefficient based on user-set threshold
clear all
close all

%% Loading and various parameters

% Make sure speed is um/s in csv file!!!
threshold = 2; % um/min threshold for arrest coefficient
[filename, path, ~] = uigetfile('.csv'); %Select Speed file

Extracted_data = parse_csv([path filename]);

%% Separate the main table into individual tables per TruelyUniqueName

[TUN, TUN_idx_last, TUN_idx] = unique(Extracted_data(:,'TrackID'),'stable');
disp(['Number of trajectories: ', mat2str(height(TUN))]);
unique_idx = accumarray(TUN_idx(:),(1:length(TUN_idx))',[],@(x) {sort(x)});
indicator_progress = 0;
arrest_coeffs = [];

for jj = 1:height(TUN);
    speeds=Extracted_data{unique_idx{jj},'Speed'};
    num_arrest = length(find(speeds < threshold));
    tmp_coeff = num_arrest / length(speeds);
    arrest_coeffs = [arrest_coeffs; tmp_coeff];
    
end

tmp_table = horzcat(table(arrest_coeffs),TUN);
str_header = min(find(filename == '_'));
writetable(tmp_table, [path '/' filename(1:str_header) 'Arrest_Coefficient.csv']);
disp(['Wrote: ' filename(1:str_header) 'Arrest_Coefficient.csv']);