% This script imports spots created in MATLAB into ImarisXT
% Alternative to Imaris spot detection which doesn't work well with
% phase-contrast images
% After import, spots can be tracked in Imaris
% 
% Instructions for use:
%     Open your tiff series in Imaris
%     Create spots .mat file using ilastik_spots_segmented.m
%         .mat file contains:
%             PositionXYZ (Nx3 array): X,Y,Z position of each spot
%             IndicesT (Nx1 array): time INDEX of each corresponding spot 
%                 Needs to start from t=0 !!!
%             Radii (Nx1 array): radius of corresponding spot

clear all
close all

%% set parameters
x_len = 1581.12; %length in microns of image
y_len = 1185.84; %height in microns of image
time_scale = 2; % time interval (in min)

[filename, path, ~] = uigetfile('.mat');
load([path filename]);
%% connect to Imaris interface
cd('C:\Program Files\Bitplane\Imaris x64 8.4.1\XT\matlab'); %set this to directory containing ImarisLib.jar
%cd('/Applications/Imaris 8.4.1.app/Contents/SharedSupport/XT/matlab');
javaaddpath ImarisLib.jar;
vImarisLib = ImarisLib;
aServer = vImarisLib.GetServer;
vObjectId = aServer.GetObjectID(0);
vImarisApplication = vImarisLib.GetApplication(vObjectId);

aSurpassScene = vImarisApplication.GetSurpassScene;

%Swap Z and T
X_size = vImarisApplication.GetDataSet.GetSizeX;
Y_size = vImarisApplication.GetDataSet.GetSizeY;
Z_size = vImarisApplication.GetDataSet.GetSizeZ;
T_size = vImarisApplication.GetDataSet.GetSizeT;

vDataSet = vImarisApplication.GetFactory.CreateDataSet;
vDataSet.Create(Imaris.tType.eTypeUInt8,X_size,Y_size,1,1,Z_size);

for z = 0:Z_size - 1
    tmp =  vImarisApplication.GetDataSet.GetDataSliceBytes(z,0,0);
    vDataSet.SetDataSliceBytes(fliplr(tmp),0,0,z);
end

vDataSet.SetTimePointsDelta(time_scale * 60); % Set time interval
vDataSet.SetChannelColorRGBA(0, 16777215); %Set color of tiff series to gray

vImarisApplication.SetDataSet(vDataSet);

%Fix scale bar
vDataSet.SetExtendMinX(0);
vDataSet.SetExtendMinY(0);
vDataSet.SetExtendMinZ(0);
vDataSet.SetExtendMaxX(x_len);
vDataSet.SetExtendMaxY(y_len);
vDataSet.SetExtendMaxZ(1);

%Load spots
vSpots = vImarisApplication.GetFactory.CreateSpots;
vSpots.SetColorRGBA(65535);

%Calculate scaling value: needed since spots are calculated on raw pixel
%locations
scale_fix = x_len/X_size;
PositionXYZ_adjusted = PositionXYZ * scale_fix;
PositionXYZ_adjusted(:,2) = y_len - PositionXYZ_adjusted(:,2); %flip spots over Y - different coordinate axis in Imaris...
vSpots.Set(PositionXYZ_adjusted, IndicesT, Radii);
aSurpassScene.AddChild(vSpots, -1);


