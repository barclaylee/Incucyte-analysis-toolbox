%Script for processing segmented images exported from ilastik into spots
%.mat files for import into Imaris
%Segmented images are individual tiff binary images with cell values
%set to 1 and background values set to 2
%Method: threshold == 1, find connected components, find centroids

%% set parameters
clear all
close all

spot_radii = 2.5; %Radius of spots to show in Imaris (display purposes, not important)
area_threshold = 5; % lower threshold on region size - helps reduce false detections, change this to area threshold to whatever works best
%% process images
path = uigetdir('','Select folder with segmented images'); %Select segmented images
    %folder needs to contain only images (delete/move extra files)
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
    to_keep = areas >= area_threshold; 
    
    centroids = cat(1, props.Centroid);
    centroids_filt = centroids(to_keep,:);
    numSpots = size(centroids_filt,1);
    
%     %save detected spots to file for validation 
%     ind = sub2ind(size(img), centroids(:,2), centroids(:,1));
%     spots = zeros(size(img));
%     spots(ind) = 1;
%     imwrite(spots, 'spots.png');
    
    tmpPositionXYZ = [centroids_filt ones(numSpots,1)];
    tmpIndicesT = ones(size(tmpPositionXYZ,1),1)*(i-1);
    tmpRadii = ones(size(tmpPositionXYZ,1),1)*spot_radii;
    
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

