%save incucyte exported tiffs to tiff series
%each series ~ 7 day
clear all
close all

directory = 'RAW';

% Create list of file names
files = dir(directory);
filenames = {files.name};
filenames = filenames(3:end);

% Get weekly time points
% day 7, day 14, day 21 media changes (avoid analysis)

% Extract zero time point:
start_filename = filenames{1};
zero_day = regexp(filenames{1},'(\d\d\d\d)y(\d\d)m(\d\d)d_(\d\dh\d\dm)','tokens');
zero_year = str2num(zero_day{1}{1});
zero_month = str2num(zero_day{1}{2});
zero_time = zero_day{1}{4};
zero_day = str2num(zero_day{1}{3});

% Find weekly time points
% day 1, day 8, day 15, day 22
num_days = max(max(calendar(zero_year, zero_month)));
time_idx = [];
time_day = [];
for day = 1:7:22
    %calculate target date
    target_day = zero_day+day;
    target_month = zero_month;
    target_year = zero_year;
    
    if target_day > num_days
        target_day = target_day - num_days;
        target_month = target_month + 1;
    end
    
    if target_month > 12
        target_month = 1;
        target_year = target_year + 1;
    end
    
    time_day = [time_day day];
    time_idx = [time_idx find(contains(filenames, sprintf('%04dy%02dm%02dd_%s',target_year,target_month,target_day,zero_time)))];
    
end

time_idx_end = time_idx + 719;

%sanity check: view images
for i=1:length(time_idx)
    img = imread(['RAW/' filenames{time_idx(i)}]);
    imshow(rgb2gray(img));
    pause;
end
close all

for j=1:length(time_idx)
    output_file = sprintf('%02dday.tif',time_day(j));
    bt = Tiff(output_file, 'w');
    
    firstDir = 1;
    for i = time_idx(j):time_idx_end(j)
        imdata = rgb2gray(imread(fullfile(directory, filenames{i})));
        
        if ~firstDir
            writeDirectory(bt);
        end
        
        tags.ImageLength         = size(imdata,1);
        tags.ImageWidth          = size(imdata,2);
        tags.Photometric         = Tiff.Photometric.MinIsBlack;
        tags.BitsPerSample       = 8;
        tags.SamplesPerPixel     = 1;
        tags.RowsPerStrip        = 6;
        tags.Compression         = Tiff.Compression.None;
        tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tags.Software            = 'MATLAB';
        tags.XResolution         = 0.8183;
        tags.YResolution         = 0.8183;
        tags.ResolutionUnit      = 1;
        setTag(bt, tags)
        
        write(bt, imdata);
        disp(sprintf('Writing day=%d t=%d ...',time_day(j), i));
        
        firstDir = 0;
    end
    close(bt)
end