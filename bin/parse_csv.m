function Extracted_data = parse_csv(file)
% Takes path to statistic csv exported from Imaris and converts to MATLAB table
% format
% Input:
%   file: filename of csv file (including path)

delimiter = ',';

raw_data = fileread(file);
raw_data_split = regexp(raw_data, '\n', 'split');

%detect start line
startRow = 2 + find(~cellfun('isempty', regexp(raw_data_split,'====')));
disp(sprintf('Detected row %d as start of data...', startRow));

%extract header line
header_line = regexp(raw_data_split{startRow-1}, delimiter, 'split');
header_line = replace(header_line, {' ', '[', ']', '^'}, '');
header_line = header_line(cellfun('isempty', regexp(header_line,'[\n\r]')));

%construct formatSpec for textscan()
formatSpec = '';
for i=1:length(header_line)
    if regexp(header_line{i}, 'Speed|Position|Time|Displacement')
        formatSpec = [formatSpec '%f'];
    else
        formatSpec = [formatSpec '%s'];
    end
end
formatSpec = [formatSpec '%[^\n\r]'];

fileID = fopen(file,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);

Extracted_data = table(dataArray{1:length(header_line)}, 'VariableNames', header_line);
end

