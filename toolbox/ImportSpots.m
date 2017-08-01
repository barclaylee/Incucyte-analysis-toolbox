% Import spots created by identify_spots_batch.m in MATLAB into ImarisXT
% Use phase-focus TIFFs from Incucyte
% Barclay Lee
% connect to Imaris interface
x_len = 1581.12; %length in microns
y_len = 1185.84;

cd('C:\Program Files\Bitplane\Imaris x64 8.4.1\XT\matlab');
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

vDataSet.SetTimePointsDelta(120); % Set time interval
vDataSet.SetChannelColorRGBA(0, 16777215); %Set color to gray

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

PositionXYZ_adjusted = PositionXYZ * 1.22;
PositionXYZ_adjusted(:,2) = y_len - PositionXYZ_adjusted(:,2);
vSpots.Set(PositionXYZ_adjusted, IndicesT, Radii);
aSurpassScene.AddChild(vSpots, -1);

