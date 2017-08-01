%% To modify the layout the measurements made by Imaris
% This script takes the Imaris export csv file where all the measurement
% are listed time point after time point and re-shuffle them into collated
% columns with one track per column

%% Loading and various parameters

threshold = 2 / 60; % um/s threshold for arrest coefficient
[filename, path, ~] = uigetfile('.csv'); %Select Speed file
delimiter = ',';
startRow = 5;
% formatSpec = '%f%s%s%f%f%s%s%s%s%s%s%s%[^\n\r]'; % Important: the 6th column (TrackID) is imported as a STRING not a number
formatSpec = '%f%s%s%f%s%s%[^\n\r]'; % Important: the 6th column (TrackID) is imported as a STRING not a n umber
fileID = fopen([path filename],'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
Extracted_data = table(dataArray{1:end-1}, 'VariableNames', {'Speed','Unit','Category','Time','TrackID','ID'});

%% STUPID FIX FOR A STUPID PROBLEM: in case some TrackID are not unique, the following added column (13th position) is concatenating the 
% 
% C_single = cell(size(Extracted_data,1),1); % Preallocation for speed
% C_multiple = [Extracted_data.TrackID Extracted_data.ID Extracted_data.OriginalID];
% for hh = 1:size(C_multiple,1);
%     C_single{hh,1} = strjoin(C_multiple(hh,:));
% end
% C_single_table = cell2table(C_single,'VariableNames',{'TruelyUniqueName'});
% Extracted_data = [Extracted_data C_single_table];
% clear C_* hh

%% Separate the main table into individual tables per TruelyUniqueName

% [TUN, TUN_idx_last, TUN_idx] = unique(Extracted_data(:,13),'stable'); % Use this line if you've generated unique TrackIDs above
[TUN, TUN_idx_last, TUN_idx] = unique(Extracted_data(:,5),'stable');
disp(['Number of trajectories: ', mat2str(height(TUN))]);
unique_idx = accumarray(TUN_idx(:),(1:length(TUN_idx))',[],@(x) {sort(x)});
indicator_progress = 0;
arrest_coeffs = [];

for jj = 1:height(TUN);
    speeds=table2array(Extracted_data(unique_idx{jj},1));
    num_arrest = length(find(speeds < threshold));
    tmp_coeff = num_arrest / length(speeds);
    arrest_coeffs = [arrest_coeffs; tmp_coeff];
    
end

tmp_table = horzcat(table(arrest_coeffs),TUN);
str_header = min(find(filename == '_'));
writetable(tmp_table, [path '/' filename(1:str_header) 'Arrest_Coefficient.csv']);
disp(['Wrote: ' filename(1:str_header) 'Arrest_Coefficient.csv']);