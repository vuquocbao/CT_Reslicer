%% CLASS HEADER INFORMATION
%By: QuocBao Vu
%Created: Dec. 20th, 2012
%Last Modified: Dec. 20th, 2012
%Version: 1
%
%This class is the model for the reslicing program. It contains the
%underlying data for the whole gui from the components values and the state
%of the loaded dicom image. When a user interact with the gui the
%controller will tell the model what do with the data and the that data
%will be processed in this class

%% CLASS DEFINITION
classdef DicomViewerModel < handle
    
    properties (Access = public)
        mainSliceNumber;
        secSliceNumber;
        mainPixelSpacing;
        secPixelSpacing;        
        mainSliceSpacing;
        secSliceSpacing;
        mainDirectory;
        secDirectory;
        
        useIsometricImage;
        mainContrastMax;
        mainContrastMin;
        secContrastMax;
        secContrastMin;
        
        mainSliderValue;
        secSliderValue;
        
        targetPixelSpacing;
        compressSliceSpacing;
        
        mainDicom3D;
        secDicom3D;
        
        mainSliderMax;
        secSliderMax;
        isLoadMain;
        isLoadSec;
        outputFilename;
        
        writeDir;
        log;
       
    end
    
    properties (Constant)
        DEFAULT_RESOLUTION      = 512;
        DEFAULT_CONTRAST_MAX    = 2500;
        DEFAULT_CONTRAST_MIN    = 0;
        
        DEFAULT_MAIN_SLIDER_MIN = 1;
        DEFAULT_SEC_SLIDER_MIN  = 1;
        
        DEFAULT_OUTPUT_FILENAME = 'Image'
    end
    
    methods
        %post: Construct the model and initialize all the values to the
        %      initial values
        function this = DicomViewerModel()
            this.mainDirectory      = '';
            this.secDirectory       = '';
            this.mainSliceNumber    = NaN;
            this.secSliceNumber     = NaN;
            this.mainPixelSpacing   = NaN;
            this.secPixelSpacing    = NaN;
            this.mainSliceSpacing   = NaN;
            this.secSliceSpacing    = NaN;
            
            this.useIsometricImage  = false;
            this.mainSliderValue    = this.DEFAULT_MAIN_SLIDER_MIN;
            this.secSliderValue     = this.DEFAULT_SEC_SLIDER_MIN;
            this.mainContrastMax    = this.DEFAULT_CONTRAST_MAX;
            this.mainContrastMin    = this.DEFAULT_CONTRAST_MIN;
            this.secContrastMax     = this.DEFAULT_CONTRAST_MAX;
            this.secContrastMin     = this.DEFAULT_CONTRAST_MIN;
            this.outputFilename     = this.DEFAULT_OUTPUT_FILENAME;
        end
        
        %post: Load the images and data in mainDirectory and set the pixel
        %      spacing, slice spacing, etc values if the directory exist
        function loadMainData(this)
            if (~isempty(this.mainDirectory))
                if (exist(this.mainDirectory, 'dir'))
                    this.mainDicom3D = Dicom3D(this.mainDirectory);
                    this.mainPixelSpacing = this.mainDicom3D.getPixelSpacing();
                    this.mainSliderMax = this.mainDicom3D.getNumberOfSlices();
                    this.mainSliceSpacing = this.mainDicom3D.getSliceSpacing();
                    this.isLoadMain = true;
                    this.mainSliderValue = this.DEFAULT_MAIN_SLIDER_MIN;
                    this.log = java.util.Stack();
                    this.outputFilename = this.DEFAULT_OUTPUT_FILENAME;
                else
                    this.isLoadMain = false;
                    error('Directory doesn''t exist');
                end
            end
        end
        
        %post: Load the images and data in secDirectory and set the pixel
        %      spacing, slice spacing, etc values if the directory exist
        function loadSecData(this)
            if (~isempty(this.secDirectory))
                if (exist(this.secDirectory, 'dir'))
                    this.secDicom3D = Dicom3DFilename(this.secDirectory);
                    this.secPixelSpacing = this.secDicom3D.getPixelSpacing();
                    this.secSliceSpacing = this.secDicom3D.getSliceSpacing();
                    this.secSliderMax = this.secDicom3D.getNumberOfSlices();
                    this.isLoadSec = true;
                else
                    this.isLoadSec = false;
                    error('Directory doesn''t exist');
                end
            end
        end
        
        %post: Get the slice in the main data speficed by mainSliderValue
        function slice = getSliceMain(this)
            slice = this.mainDicom3D.getSlice(this.mainSliderValue);
        end
        
        %post: Get the slice in the secondary data specified by the
        %      secSliderValue
        function slice = getSliceSec(this)
            slice = this.secDicom3D.getSlice(this.secSliderValue);
        end
        
        %post: Get the image number in the main data
        function sliceNumber = getMainImageNumber(this)
            sliceNumber = this.mainDicom3D.getTrueImageNumber(...
                this.mainSliderValue);
        end
        
        %post: Get the image number in the secondary data
        function sliceNumber = getSecImageNumber(this)
            sliceNumber = this.secDicom3D.getTrueImageNumber(...
                this.secSliderValue);
        end
        
        %post: Returns if the 3D image in the main data set is inverted
        function b = isInverted(this)
            b = this.mainDicom3D.isInverted();
        end
        
        %post; Inverts the 3D image in the main data set
        function invert(this)
            this.mainDicom3D.invert();
        end
        
        %post: Makes the 3D image in the main data set isometric and then
        %      updating the main value to the correct values
        function makeIsometric(this)
            this.mainDicom3D.makeIsometric();
            this.mainSliderMax = this.mainDicom3D.getNumberOfSlices; 
            this.mainSliderValue = 1;
            this.mainPixelSpacing = this.mainDicom3D.getPixelSpacing();
            this.mainSliceSpacing = this.mainDicom3D.getSliceSpacing();
        end
        
        %post: Returns a boolean specifiying if the image in the main data
        %      set is isometric
        function b = isIsometric(this)
            b = this.mainDicom3D.isIsometric();
        end
        
        %post: Reset all changes made to the image and the value in the
        %       main data set
        function reset(this)
            this.mainDicom3D.reset();
            this.mainPixelSpacing = this.mainDicom3D.getPixelSpacing();
            this.mainSliceSpacing = this.mainDicom3D.getSliceSpacing();
            this.mainSliderMax = this.mainDicom3D.getNumberOfSlices();
            this.mainSliderValue = 1;
        end
        
        %post: Change the pixel spacing of the image in the main data set
        %      and them updating the main values after the change
        function changePixelSpacing(this)
            this.mainDicom3D.changePixelSpacing(this.targetPixelSpacing);
            this.mainPixelSpacing = this.mainDicom3D.getPixelSpacing();
            this.mainSliceSpacing = this.mainDicom3D.getSliceSpacing();
            this.mainSliderMax = this.mainDicom3D.getNumberOfSlices();
            this.mainSliderValue = this.DEFAULT_MAIN_SLIDER_MIN;
        end
        
        %post: Resets all rotation done to the image
        function resetRotation(this)
            this.mainDicom3D.resetRotation();
        end
        
        %post: Rotate the image clockwise about the horzontal axis
        function rotateUp(this)
            this.mainDicom3D.rotateUp();
        end
        
        %post: Rotate the image connter clockwise about the horizontal axis
        function rotateDown(this)
            this.mainDicom3D.rotateDown();
        end
        
        %post: Rotate the image in the main data set clockwise about the
        %      vertical axis
        function rotateLeft(this)
            this.mainDicom3D.rotateLeft();
        end
        
        %post: Rotate the image in the main data set counter clockwise
        %      about the vertical axis
        function rotateRight(this)
            this.mainDicom3D.rotateRight();
        end
        
        %post: Rotate the image in the main data set clockwise inplane
        function rotateCW(this)
            this.mainDicom3D.rotateCW();
        end
        
        %post: Rotate the image in the main data set counter clockwise
        %       inplane
        function rotateCCW(this)
            this.mainDicom3D.rotateCCW();
        end
        
        %post; Compress the number of slices or change the slice spacing of
        %      the 3D image in the main data set
        function compress(this)
            this.mainDicom3D.compress(this.compressSliceSpacing);
            this.mainPixelSpacing = this.mainDicom3D.getPixelSpacing();
            this.mainSliceSpacing = this.mainDicom3D.getSliceSpacing();
            this.mainSliderMax = this.mainDicom3D.getNumberOfSlices();
            this.mainSliderValue = this.DEFAULT_MAIN_SLIDER_MIN;
        end
        
        %post: Writes the current 3D dicom image to the set writeDir
        function write(this)
            if (isempty(this.outputFilename))
                this.mainDicom3D.write(this.writeDir);
            else
                this.mainDicom3D.write(this.writeDir, this.outputFilename);
            end
        end
        
        %post: Adds a command to the log
        function logPush(this, command)
            if (~isa(command, 'char'))
                error('Invalid variable type');
            else
                if (strcmpi(command, 'CPS'))
                    while (~this.log.isEmpty())
                        this.log.pop();
                    end
                    this.log.push('CPS');
                    this.log.push(this.targetPixelSpacing);
                    if (this.isIsometric())
                        this.log.push('ISO');
                    end
                    if (this.isInverted())
                        this.log.push('Invert');
                    end
                elseif (strcmpi(command, 'ISO'))
                    this.log.push('ISO');
                elseif (strcmpi(command, 'Compress'))
                    this.log.push('Compress');
                    this.log.push(this.compressSliceSpacing);
                elseif (strcmpi(command, 'Reset'))
                    while (~this.log.isEmpty())
                        this.log.pop();
                    end
                elseif (strcmpi(command, 'resetRotation'));
                    c = this.log.pop();
                    while (strcmpi(c, 'upR') || strcmpi(c, 'downR') || ...
                            strcmpi(c, 'rightR') || strcmpi(c, 'leftR') ...
                            || strcmpi(c, 'ccwR') || strcmpi(c, 'cwR') || ...
                            strcmpi(c, 'Invert'))
                        c = this.log.pop();
                    end
                    this.log.push(c);
                    if (this.isInverted())
                        this.log.push('Invert');
                    end
                else
                    this.log.push(command);
                end
            end         
        end
        
        %post: Prints the log out to file in the code directory
        function printLog(this)
            cloneStack = this.log.clone();
            auxStack = java.util.Stack();
            while (~cloneStack.isEmpty())
                auxStack.push(cloneStack.pop());
            end
            
            fid = fopen('DicomViewerCommandLog.txt', 'wt');
            while (~auxStack.isEmpty())
                command = auxStack.pop();
                if (isa(command, 'char'))
                    fprintf(fid, '%s\n', command);
                else
                    fprintf(fid, '%4.8f\n', command);
                end
            end
            
            fclose(fid);
        end
    end
    
    methods
        %post: set the directory in the main data set 
        function setMainDirectory(this, mainDir)
            this.mainDirectory = mainDir();
        end
        
        %post: Returns the directory for the main data set
        function output = getMainDirectory(this)
            output = this.mainDirectory;
        end
        
        %post: set the directory in the secondary data set
        function setSecDirectory(this, secDir)
            this.secDirectory = secDir;
        end
        
        %post: Return the directory for the secondary data set
        function output = getSecDirectory(this)
            output = this.secDirectory;
        end
        
        %post: Return the max allowed value for the main slider
        function max = getMainSliderMax(this)
            max = this.mainSliderMax;
        end
        
        %post: return the max allowed value for the secondary slider
        function max = getSecSliderMax(this)
            max = this.secSliderMax;
        end
        
        %post: Returns if the data was loaded sucessfully in the main data
        %      set
        function boolean = isLoadMainSuccessful(this)
            boolean = this.isLoadMain;
        end
        
        %post: Returns if the data was loaded sucessfully in the secondary
        %      data set
        function boolean = isLoadSecSuccessful(this)
            boolean = this.isLoadSec;
        end
        
        %post: Set the main slider value to the input value
        function setMainSliderValue(this, value)
            this.mainSliderValue = ceil(value);
        end
        
        %post Set the secondary slider value to the input value
        function setSecSliderValue(this, value)
            this.secSliderValue = ceil(value);
        end
        
        %post: Return the main slider current value
        function value = getMainSliderValue(this)
            value = this.mainSliderValue;
        end
        
        %post: Return the secondary slider current value
        function value = getSecSliderValue(this)
            value = this.secSliderValue;
        end
        
        %post: Return the pixel spacing of the volume in the main data set
        function value = getMainPixelSpacing(this)
            value = this.mainPixelSpacing;
        end
        
        %post: Return the slice spacing of the volume in the main data set
        function value = getMainSliceSpacing(this)
            value = this.mainSliceSpacing;
        end
        
        %post: Return the pixel spacing of the volume in the secondary data
        %      set
        function value = getSecPixelSpacing(this)
            value = this.secPixelSpacing;
        end
        
        %post: Return the slice spacing of the volume in the secondary data
        %      set
        function value = getSecSliceSpacing(this)
            value = this.secSliceSpacing;
        end
        
        %post: Set the min value for the image contrast in the main data
        %      set
        function setMainContrastMin(this, value)
            this.mainContrastMin = ceil(value);
        end
        
        %post: Set the max value for the image contrast in the main data
        %      set
        function setMainContrastMax(this, value)
            this.mainContrastMax = ceil(value);
        end
        
        %post: Set the min value for the image contrast in the secondary
        %      data set
        function setSecContrastMin(this, value)
            this.secContrastMin = ceil(value);
        end
        
        %post: Set the max value for the image contrast in the secondary
        %      data set
        function setSecContrastMax(this, value)
            this.secContrastMax = ceil(value);
        end
        
        %post: Return the current min value of the image contrast in the
        %      main data set
        function value = getMainContrastMin(this)
            value = this.mainContrastMin;
        end
        
        %post: Return the current max value of the image contrast in the
        %      main data set
        function value = getMainContrastMax(this)
            value = this.mainContrastMax;
        end
        
        %post: Return the current min value of the image contrast in the
        %      secondary data set
        function value = getSecContrastMin(this)
            value = this.secContrastMin;
        end
        
        %post: Return the current max value of the image contrast in the
        %      secondary data set
        function value = getSecContrastMax(this)
            value = this.secContrastMax;
        end
        
        %post: Set the target pixel spacing for chaging the pixel spacing
        %      to the input value
        function setTargetPixelSpacing(this, inputValue)
            this.targetPixelSpacing = inputValue;
        end
        
        %post: Set the slice spacing for compression to the input value
        function setCompressSliceSpacing(this, value)
            this.compressSliceSpacing = value;
        end
        
        %post: Set the output directory to write the dicom files
        function setWriteDir(this, value)
            this.writeDir = value;
        end
        
        %post: Returns the output directory to write the dicom files
        function writeDir = getWriteDir(this)
            writeDir = this.writeDir;
        end
        
        %post: Set the output filename
        function setOutputFilename(this, name)
            this.outputFilename = name;
        end
        
        %post: Returns the output filename
        function filename = getOutputFilename(this)
            filename = this.outputFilename;
        end      
    end
   
end
%% END DEFINITION


