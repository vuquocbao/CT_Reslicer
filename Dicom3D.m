%By: QuocBao Vu
%Created: Dec. 31, 2012
%Modified: Dec. 31, 2012
%Version: 3
%
%The class is the driver for making mofication to dicom image stacks. The
%modification that are allowed are changing the pixel spacing rotatin the
%image to another slice plane and changing the slice spacing. The recommend
%order of operation to make modifaction is to first change the pixel
%spacing then make the image isometric before calling any rotations and
%then compressing the number of slices if needed. The CroppingGUIV3.m is
%need when chaning the pixel spacing and that is the only external file
%needed to make changes to the data set. Note that the only input is the
%a directory and this can only support 512x512 images and maximum 512
%number of slices when the image is isometric

classdef Dicom3D < handle 
    properties
        directory;              %Main directory to load files from
        fileset;                %List of all the files in the data set
        dicomInfo;              %The header infromation
        originalPixelSpacing;   %Original Pixel Spacing of the data set
        originalSliceSpacing;   %Origianl Slice spacing of the data set
        originalVolume;         %Original 3D volume of the data
        originalIsoVolume;      %Original volume after making it isometric
        isometricVolume;        %Modified isometric volume
        
        pixelSpacing;           %Current pixel spacing
        sliceSpacing;           %Current slice spacing
        volume;                 %Current modifable volume
        
        inverted;               %If the volume had been inverted
        isometric;              %If the volume is isometric
        addExtension;        
        
        imageC;                 %Final image with black slices cropped out
    end
    
    methods
        %post: Construct a Dicom3D object that repersents an dicom image
        %      stack with the nessacry header infromation to modify the
        %      volume with rotations, changing the pixel spacing, chaing
        %      the slice spacing and make the volume isometric
        function this = Dicom3D(directory)
            this.addExtension = false;
            this.directory = directory;
            if (this.directory(end) ~= '\')
                this.directory = [this.directory '\'];
            end
            this.compileFiles();
            this.loadInformation();
            this.createDicomVolume();
            
            if (length(this.volume) ~= 512)
                makeVolume512(this, 512);
            end
            this.inverted = false;
            this.isometric = false;
        end
        
        %post: Inverts the volume in the thrid dimension
        function invert(this)
            this.volume = flipdim(this.volume, 3);
            this.inverted = ~this.inverted;
        end
        
        %post: Makes the inplane resolution 512 x 512 by centering the 
        %      image inside a black 512 x 512 image
        function makeVolume512(this, imageSize)
            volumeSize = size(this.volume);
            rowStartIdx = ceil((imageSize - size(this.volume,1)) /2) + 1;
            columnStartIdx = ceil((imageSize - size(this.volume,2)) / 2) + 1;
            
            rowEndIdx = rowStartIdx + volumeSize(1) - 1;
            columnEndIdx = columnStartIdx + volumeSize(2) - 1;
            
            newVolume = uint16(zeros(imageSize, imageSize, volumeSize(3)));
            newVolume(rowStartIdx:rowEndIdx, columnStartIdx:columnEndIdx, 1:volumeSize(3)) = this.volume;
            
            this.volume = newVolume;
        end
        
        %post: Reset all changes made to the image
        function reset(this)
            this.volume = this.originalVolume;
            this.pixelSpacing = this.originalPixelSpacing;
            this.sliceSpacing = this.originalSliceSpacing;
            this.inverted = false;
            this.isometric = false;
        end
        
        %post: Changes the pixel spacing of the image volue to the target
        %      value. If the target value is smaller than the current pixel
        %      spacing the image will be enlarged by a factor and a gui
        %      will be used to crop a section of the image. If the target
        %      value is smaller than the current value the image will
        %      shrink and will be center in a black 512 by 512 image
        function changePixelSpacing(this, targetValue)
            resizeFactor = this.pixelSpacing/targetValue;
            imageSize = size(this.volume, 1);
            this.volume = this.originalVolume;
            this.volume = imresize(this.volume, resizeFactor, 'bilinear');
            
            if (size(this.volume, 1) <= imageSize && ...
                    size(this.volume, 2) <= imageSize)
                this.makeVolume512(imageSize);
            else
                this.launchCroppingGUI(imageSize);
            end
            this.pixelSpacing = targetValue;
            this.sliceSpacing = this.originalSliceSpacing;
            if (this.isIsometric())
                this.makeIsometric();
            end 
            if (this.isInverted)
                this.volume = flipdim(this.volume, 3);
            end
        end
        
        %post: Generates a volume that has isometric voxels. If after
        %      making the volume isometric and the z-dimension is greater
        %      than 512 and error is thrown since resolution greater than
        %      512 is not supported. Other wise the image is centered if
        %      the dimension is less than 512
        function makeIsometric(this)
            %Compute ratio and resizing factor and the correct dimension of
            %the resize image
            dim = size(this.volume);
            resizeFactor = this.sliceSpacing/this.pixelSpacing;
            resizeDimensions = ceil([dim(1) dim(3) * resizeFactor]);
            boxSize = dim(1);
            
            %Resize the image in the z direction
            s = this.volume;
            parfor i = 1:dim(2)
                slice = squeeze(s(:,i,:));
                sliceResized = imresize(slice, resizeDimensions, 'bilinear');
                sliceReshaped = reshape(sliceResized, dim(1), 1, ...
                    resizeDimensions(2))
                temporaryVolume(:,i,:) = sliceReshaped;
            end
            
            %Check to see if the z-dimension is greater than 512. If not
            %centers the image in the z-direction
            if (size(temporaryVolume, 3) > boxSize)
                error(['Image Stack can not be converted in to Isometric'...
                    ',Increase the pixel Spacing and try again']);
            else
                topIndex = ceil((boxSize - size(temporaryVolume, 3)) / 2) + 1;
                isoVolume = uint16(zeros(boxSize, boxSize, boxSize));
                isoVolume(:,:,topIndex:topIndex+size(temporaryVolume, 3)-1) = temporaryVolume;

                this.volume = isoVolume;
                this.sliceSpacing = this.pixelSpacing;
                this.isometric = true;
            end
            
            if (this.pixelSpacing == this.originalPixelSpacing)
                this.originalIsoVolume = isoVolume;
            end
            this.isometricVolume = isoVolume;      
        end
        
        %post: Writes the Volume to the file using the inputed output 
        %      directory and fileanem. If no filename is specified a 
        %      default filename "image" is assigned. The data is writen
        %      first then read back in to update the header information
        function write(this, outputDirectory, filename)
            this.checkDirectory(outputDirectory)
            if (outputDirectory(end) ~= '\')
                outputDirectory = [outputDirectory '\'];
            end
            if (nargin == 2)
                filename = 'image';
            else 
                filename = filename;
            end
            
            this.imageCrop();
            
            for i = 1:size(this.imageC, 3)
                fileNumber = this.getFileNumber(i);
                dicomwrite(this.imageC(:,:,i), [outputDirectory filename fileNumber '.dcm'], ...
                    'ObjectType', 'CT Image Storage', 'CompressionMode', 'none');
            end
            updateInfo(this, outputDirectory, filename);
        end
        
        %pre:  3D image must be isometric (throws error if not)
        %post: Rotates the 3D image 90 degress about the vertical axis
        function rotateRight(this)
            if (~this.isIsometric)
                error('Image Volume is not Isometric');
            else
                dummyVolume = this.volume;
                parfor i = 1:size(dummyVolume, 1)
                    slice = squeeze(dummyVolume(i, :, :))
                    rotateIm = imrotate(slice, 90);
                    dummyVolume(i, :, :) = rotateIm;
                end
                this.volume = dummyVolume;
            end
        end
        
        %pre:  3D image must be isometric (throws error if not)
        %post: Rotate the 3D image -90(270) degrees about the vertical axis 
        function rotateLeft(this)
            if (~this.isIsometric)
                error('Image Volume is not Isometric');
            else
                dummyVolume = this.volume;
                parfor i = 1:size(dummyVolume, 1)
                    slice = squeeze(dummyVolume(i, :, :))
                    rotateIm = imrotate(slice, -90);
                    dummyVolume(i, :, :) = rotateIm;
                end
                this.volume = dummyVolume;
            end
        end
        
        %pre:  3D image must be isometric (throws error if not)
        %post: Rotate the 3D image -90(270) degrees about the horizontal
        %      axes
        function rotateUp(this)
            if (~this.isIsometric)
                error('Image Volume is not Isometric');
            else
                dummyVolume = this.volume;
                parfor i = 1:size(dummyVolume, 2)
                    slice = squeeze(dummyVolume(:, i, :))
                    rotateIm = imrotate(slice, -90);
                    dummyVolume(:, i, :) = rotateIm;
                end
                this.volume = dummyVolume;
            end
        end
        
        %pre:  3D image must be isometric (throws error if not)
        %post: Rotate the 3D image 90 degress about the horizontal axes
        function rotateDown(this)
            if (~this.isIsometric)
                error('Image Volume is not Isometric');
            else
                dummyVolume = this.volume;
                parfor i = 1:size(dummyVolume, 2)
                    slice = squeeze(dummyVolume(:, i, :))
                    rotateIm = imrotate(slice, 90);
                    dummyVolume(:, i, :) = rotateIm;
                end
                this.volume = dummyVolume;
            end
        end 
        
        %pre:  3D image must be isometric (throws error if not)
        %post: Rotate the 3D image 90 counter clockwise inplane
        function rotateCCW(this)
            if (~this.isIsometric)
                error('Image Volume is not Isometric');
            else
                dummyVolume = this.volume;
                parfor i = 1:size(dummyVolume, 3)
                    slice = squeeze(dummyVolume(:, :, i))
                    rotateIm = imrotate(slice, 90);
                    dummyVolume(:, :, i) = rotateIm;
                end
                this.volume = dummyVolume;
            end
        end
        
        %pre:  3D image must be isometric (throws error if not)
        %post: Rotate the 3D image -90(270) clockwise inplane
        function rotateCW(this)
            if (~this.isIsometric)
                error('Image Volume is not Isometric');
            else
                dummyVolume = this.volume;
                parfor i = 1:size(dummyVolume, 3)
                    slice = squeeze(dummyVolume(:, :, i))
                    rotateIm = imrotate(slice, -90);
                    dummyVolume(:, :, i) = rotateIm;
                end
                this.volume = dummyVolume;
            end
        end
        
        %post: Compress the image to have the input slice spacing
        function compress(this, newSliceSpacing)
            
            if (newSliceSpacing ~= this.sliceSpacing)
                %Make copy of current volume and get the dimensions
                tempVol = this.volume;
                dim = size(tempVol);
                %Compute the compression factor and new compressed dimensions
                compressionFactor = this.sliceSpacing/newSliceSpacing;
                compressDimensions = ceil([dim(1) dim(3) * compressionFactor]);

                parfor i = 1:dim(2)
                    slice = squeeze(tempVol(:,i,:));
                    sliceCom = imresize(slice, compressDimensions, 'bilinear');
                    sliceReshaped = reshape(sliceCom, dim(1), 1, ...
                        compressDimensions(2));
                    compVolume(:, i, :) = sliceReshaped;
                end

                this.volume = compVolume;
                this.sliceSpacing = newSliceSpacing;
                this.isometric = false;
            end
        end
        
        %post: reset any rotation made to the image
        function resetRotation(this)
            this.volume = this.isometricVolume;
            if (this.inverted)
                this.volume = flipdim(this.volume, 3);
            end
        end
        
        %post: Returns the number of slices in the volume. ie size in the
        %      third dimension
        function nS = getNumberOfSlices(this)
            nS = size(this.volume, 3);
        end
        
        %post: Returns the slice specified by the user input
        function slice = getSlice(this, index)
            if (index > size(this.volume, 3) || index < 1)
                error('Invalid Slice Number');
            end
            slice = this.volume(:,:,index);
        end
        
        %post: Returns the correct image number even when the image is
        %      inverted
        function imageNumber = getTrueImageNumber(this, sliceNumber)
            if (sliceNumber < 1 || sliceNumber > size(this.volume, 3))
                error('Index Out of Bounds Exception');
            end
            
            imageNumber = sliceNumber;
            if (this.isInverted())
                imageNumber = (size(this.volume, 3) + 1) - sliceNumber;
            end
        end
        
    end
    
    
    %Get and Set Methods
    methods
        
        %post: Returns the current pixel spacing 
        function ps = getPixelSpacing(this)
            ps = this.pixelSpacing;
        end
        
        %post: Returns the current slice spacing of the volume
        function ss = getSliceSpacing(this)
            ss = this.sliceSpacing;
        end
        
        %post: Returns if the current volume is inverted
        function boolean = isInverted(this)
            boolean = this.inverted;
        end
        
        %post: Returns if the volume is isometric
        function boolean = isIsometric(this)
            boolean = this.isometric;
        end
        

    end
    
    methods (Access = protected)
        %post: Compiles all the dicom files in the directory. If the dcm   
        %      extension is not there the files are copy to a tempaoray
        %      folder and the extension is add on.
        function compileFiles(this)
            %Compile files in the directory
            recompile = false;
            listing = dir(this.directory);
            files = cell(size(listing));
            for i = 1:size(listing)
                files{i} = listing(i).name;
            end
            
            for i = size(listing):-1:1
                string = files{i};
                if (isempty(regexpi(string, '.*\.dcm', 'match')))
                    files(i) = [];
                else
                    if (~isempty(regexpi(string, 'dir', 'match')))
                        files(i) = [];
                    end
                    
                end
            end
            
            %Copy to temparay folder and add dcm extension to the file
            listing = dir(this.directory);
            if (isempty(files))
                recompile = true;
                if (~exist([this.directory 'tempfolder'], 'dir'))
                    mkdir(this.directory, 'tempFolder');
                end
                for i  = 1:length(listing)
                    if (~listing(i).isdir ...
                        && isempty(strfind(listing(i).name, '.')))
                    copyfile([this.directory listing(i).name], ...
                        [this.directory 'tempFolder\' listing(i).name '.dcm']);
                    end
                end
            end
            
            %Recompile with the new directory and files
            if (recompile)
                listing = dir([this.directory 'tempFolder']);
                this.directory = [this.directory 'tempFolder\'];
                for i = 1:size(listing)
                    files{i} = listing(i).name;
                end
            end
            if (recompile)
                for i = size(listing):-1:1
                    string = files{i};
                    if (isempty(regexpi(string, '.*\.dcm', 'match')))
                        files(i) = [];
                    else
                        if (~isempty(regexpi(string, 'dir', 'match')))
                            files(i) = [];
                        end
                    end
                end
            end
                        
            this.fileset = sort(files);
        end
        
        %post: Loads the dicomInfo header file and reads the pixel and
        %      slice spacing. If the slice spacing fields is missing the
        %      slice spacing will be computed using two images
        function loadInformation(this)
            if (isempty(this.fileset))
                error(['Cannot Load Dicom Header Information: List of' ...
                       ' files is empty']);
            else
                this.dicomInfo = dicominfo([this.directory this.fileset{1}]);
                this.originalPixelSpacing = this.dicomInfo.PixelSpacing(1);
                this.pixelSpacing = this.originalPixelSpacing;
                
                if (isfield(this.dicomInfo, 'SpacingBetweenSlices'))
                    this.originalSliceSpacing = ...   
                        this.dicomInfo.SpacingBetweenSlices;
                else
                    this.originalSliceSpacing = computeSliceSpacing(this);
                end
                this.sliceSpacing = this.originalSliceSpacing;
            end
        end
        
        %post: compute the slice spacing between two images
        function spacing = computeSliceSpacing(this)
            info1 = dicominfo([this.directory this.fileset{1}]);
            info2 = dicominfo([this.directory this.fileset{2}]);
            position1 = info1.ImagePositionPatient;
            position2 = info2.ImagePositionPatient;
            
            spacing = sqrt(sum((position1 - position2).^2));
        end
        
        %post: Determine the order of the file using the instance number
        %      and returning the new ordered list of files
        function fileOrder = getFileOrder(this)
            info1 = dicominfo([this.directory this.fileset{1}]);
            info2 = dicominfo([this.directory this.fileset{2}]);
            
            if (info1.InstanceNumber > info2.InstanceNumber)
                fileOrder = flipup(this.fileset);
            else
                fileOrder = this.fileset;
            end
        end
        
        %post: Reads in each dicom file to create the volume
        function createDicomVolume(this)
            order = this.getFileOrder();
            for i = 1:length(order)
                this.volume(:,:,i) = dicomread([this.directory order{i}]);
            end
            this.originalVolume = this.volume;
            
            if (length(this.volume) > 512)
                error('Image resolution greater than 512 not supported')
            end
        end 
        
        %post: Update the header information after writing the files. The
        %      instance number is written in revers if the image is
        %      inverted. This is to keep consistancy when reading files.
        function updateInfo(this, outputDirectory, filename)
            for i = 1:size(this.imageC, 3)
                fileNumber = this.getFileNumber(i);
                data = dicomread([outputDirectory filename fileNumber '.dcm']);
                info = dicominfo([outputDirectory filename fileNumber '.dcm']);
                info.ImageOrientationPatient = this.dicomInfo.ImageOrientationPatient;
                info.PixelSpacing = [this.pixelSpacing; this.pixelSpacing];
                if (this.inverted)
                    info.InstanceNumber = size(this.imageC, 3) + 1 - i;
                    info.ImagePositionPatient = [0;0;((size(this.imageC, 3))-i)*this.sliceSpacing];
                else
                    info.InstanceNumber = i;
                    info.ImagePositionPatient = [0;0;(i-1)*this.sliceSpacing];
                end
                
                dicomwrite(data, [outputDirectory filename fileNumber '.dcm'], info);
            end
        end
        
        %post: Launch a gui after chaing the pixel spacing to crop out a
        %      512 by 512 area using the cropping values returned from the
        %      gui.
        function launchCroppingGUI(this, imageSize)
            cropGui = CroppingGUIV3(this.volume, imageSize);
            waitfor(cropGui.getFrame());
            cropValue = cropGui.getCroppingValues();
            
            subVolume = this.volume(cropValue(2,1):cropValue(2,2),...
                cropValue(1,1):cropValue(1,2),:);
            this.volume = subVolume;
        end
        
        
        %post: Crops the any extra black empty slices at the front and back
        %      of the stack
        function imageCrop(this)
            sumImage = sum(sum(this.volume));
            sumImageSq = squeeze(sumImage);
            index = find(sumImageSq ~= 0);
            index = sort(index);
            sliceMin = index(1);
            sliceMax = index(end);
            
            this.imageC = this.volume(:,:,sliceMin:sliceMax);
        end
    end
    
    methods (Static)
        %post: check for valid inputs for directories
        function checkDirectory(directory)
            if (~isa(directory, 'char'))
                throw(MException('DicomVolume:checkDirectory:IllegalArgumentException', ...
                    'Input is not of type String'));
            end
            if (~exist(directory, 'dir'))
                throw(MException('DicomVolume:checkDirectory:DirectoryNotFoundException', ...
                    'Directory does not exsit'));
            end
        end
        
        %post: Generates a file number using the input index value
        function string = getFileNumber(index) 
            num = num2str(index);
            numZeros = '000';
            numStr = [numZeros(length(num):end) num];
            
            string = numStr;
        end     
    end  
end

