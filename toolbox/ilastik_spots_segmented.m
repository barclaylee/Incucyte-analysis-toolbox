%scripts for processing spot probabilities exported from ilastik
%method: threshold == 1, find connected components
clear all
close all

path = uigetdir('','Select spot probabilities folder'); %Select spot probabilities
cd(path);
files = dir;
filenames = {files.name};
hidden_files = cellfun(@(x) strcmp(x(1),'.'), filenames); %remove hidden files from list
filenames = filenames(~hidden_files);

PositionXYZ = [];
IndicesT = [];
Radii = [];
for i = 1:size(filenames,2)
    disp(sprintf('Processing image %d',i));
    
    img = imread(filenames{i});
    
    %threshold: find simple segmentation regions
    img_thres = img == 1;
    
    %filter by area
    props = regionprops(img_thres,'Centroid','Area');
    areas = [props.Area];
    to_keep = areas >= 5; % can change this area threshold to whatever works best
    
    centroids = round(cat(1, props.Centroid));
    centroids_filt = centroids(to_keep,:);
    numSpots = size(centroids_filt,1);
    
%     %save detected spots to file for validation 
%     ind = sub2ind(size(img), centroids(:,2), centroids(:,1));
%     spots = zeros(size(img));
%     spots(ind) = 1;
%     imwrite(spots, 'spots.png');
    
    tmpPositionXYZ = [centroids_filt ones(numSpots,1)];
    tmpIndicesT = ones(size(tmpPositionXYZ,1),1)*(i-1);
    tmpRadii = ones(size(tmpPositionXYZ,1),1)*2.5;
    
    PositionXYZ = [PositionXYZ; tmpPositionXYZ];
    IndicesT = [IndicesT; tmpIndicesT];
    Radii = [Radii; tmpRadii];
    
%     %overlay detected peaks over probability map for validation
%     fig = imshow(img);
%     hold on
%     for i = 1:size(centroids_filt,1)
%         plot(centroids_filt(i,1),centroids_filt(i,2), 'y+');
%     end
%     hold off
clc
end

save('spots_ilastik','PositionXYZ','IndicesT','Radii');
disp(['Saved: ' path '/spots_ilastik.mat']);

