%% HEADER INFORMATION
%By: QuocBao Vu
%Created: Dec. 31, 2012
%Modified: Dec. 31, 2012
%Version: 1
%
%The program reslices dicom image stack maunally by having the user typing
%out the commands in the script before running. First a Dicom3D object is
%create from the input directory to repersent the data. The user then can
%make the changes to the image by programming the commands in the scrips.
%After all the commands have been executed the program will write volume to
%file. 
%
%The recommend order of operations when reslicing the images
%   1.  Change the pixel spacing and crop out the desired area from the GUI
%       that pops up if needed
%   2.  Make the Dicom3D object Isometric. This is very important if the
%       user wants to rotate the image such that is slice in different
%       planes
%   3.  Apply the nessacry rotations to the image to change the slice plane
%   4.  Invert the image if nessaray. What Inverting the image does if it
%       will write the file out such that the filenumber and image number
%       is in reverse. This is to address some issue with multi-rigid
%   5.  Compress the number of slices by setting a bigger slice spacing to 
%       reduce the number of slices in the image.
%   6.  Write the file to the output directory. The user can specify an
%       output filename but one is not need. The default file name is set
%       to "image"
%
%Modification Commands
%   changePixelSpacing(newPixelSpacing) - Changes the pixel spacing of the
%       imagestack to the desired newPixelSpacing. Depending on the value
%       of newPixelSpacing a GUI to crop out a desired area may or may not
%       pop up
%
%   makeIsometric() - Makes the volume of the image stack isometric,
%       meaning the slice spacing will equal the pixel spacing. If the user
%       wants to rotation the image this step is very important. If no call
%       to make the volume isometric before a rotation is applied the
%       program will error out
%
%   rotateUp() - Rotates the volume clockwise about the horizontal axes
%       (Right hand rule with the horizontal vector pointing right and
%       vertical vector up)
%
%   rotateDown() - Rotates the volume counter clockwise about the
%       horizontal axes (Right hand rule with the horizontal vector 
%       pointing right and vertical vector up)
%
%   rotateLeft() - Rotates the volume counter clockwise about the vertical
%       axes horizontal axes (Right hand rule with the horizontal vector 
%       pointing right and vertical vector up)
%
%   rotateRight() - Rotates the volume clockwise about the vertical axes
%       (Right hand rule with the horizontal vector pointing right and 
%       vertical vector up)
%
%   rotateCW() - Rotates the volume clockwise inplane
%
%   rotateCCW() - Rotates the volume counter clockwise inplane
%
%   Invert() - Invert the image in the thrid dimensions
%
%   compress(newSliceSpacing) - Changes the slices spacing and number of
%       slice in the image stack. Can be used to reduce the number of
%       images and increase the number of images. Do not try to increase
%       the number of images when the image is already Isometric because
%       any size larger than 512 is not supported
%
%   write(directory, filename) - Writes the volume out the specified
%       directory with the specified filename. Note that a filename does 
%       not need to be specified. If no filename is specified the default
%       filename is "image".
%% EXECUTION CODE

clear all
close all
clc

%Set the input and output directory
inputDirectory = 'D:\DFSS\cd003\InputDicom\';
outputDirectory = 'Test2';

%Set Desired pixel spacing and slice spacing. This section does not need to
%be set you can just call the command and enter the value then
newPixelSpacing = [];
newSliceSpacing = [];

%Initialize the 3D dicom stack object
imageStack = Dicom3D(inputDirectory);

%Enter the commands to be executed manually. Remember before any rotation
%to the image a call to make the image isometric must be made

imageStack.changePixelSpacing(.45);
imageStack.makeIsometric();
imageStack.rotateUp();
imageStack.rotateCCW();
imageStack.rotateCCW();
imageStack.invert();

%Output the modifed image to file
if (~exist(outputDirectory, 'dir'))
    mkdir(outputDirectory);
end
imageStack.write(outputDirectory);

%% END PROGRAM