%By: QuocBao Vu
%Created: Dec. 20th, 2012
%Modified: Dec. 20th, 2012
%Version: 3
%
%This class is a gui for cropping and image to a 512x512 resolution after
%it has been resized due to a change in the pixel spacing. The cropping gui
%has the ability to scroll thru the whole stack to find the be position to
%crop the image stack. A pre define 512x512 box defines the cropping region


classdef CroppingGUIV3 < handle
    %CROPPINGGUIV3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frame;              %Figure window
        
        volume;             %The 3d Image stack
        volumeSize;         %The dimensions of the 3D image stack
        imageSize;          %Allowable image size
        display;            %The axes to display the image and cropping box
        scroll;             %Scroll to scroll thru the image stack
        returnButton;       %Save the cropping values and closes the window
        positionDisplayX;   %display of the x cropping values
        positionDisplayY    %display of the y cropping values
        croppingROI         %The cropping rectangle
        cropValues          %The crop values
    end
    
    methods
        %post: Contructs the gui using the input image and the desired
        %      image size
        function this = CroppingGUIV3(image, imageSize)
            if (~isempty(findobj('name', 'Cropping GUI')))
                close(findobj('name', 'Cropping GUI'))
            end
            this.volume = image;
            this.volumeSize = size(this.volume);
            this.imageSize = imageSize;
            
            %Contruct the window
            this.frame = figure;
            set(this.frame, 'outerposition', [0, 0, ...
                this.volumeSize(1) + 300, this.volumeSize(1) + 35]);
            set(this.frame, 'name', 'Cropping GUI');
            set(this.frame, 'Menubar', 'none');
            set(this.frame, 'resize', 'off');
            set(this.frame, 'Color', [.85 .85 .85]);
            movegui(this.frame, 'center');
            
            %Create the axes
            this.display = axes(...
                'units', 'pixel', ...
                'position', [5, 5, this.volumeSize(1), this.volumeSize(2)]);
            
            %Create the scroll
            this.scroll = uicontrol(...
                'style', 'slider', ...
                'position', [this.volumeSize(2) + 18, 10, 20, ...
                    this.volumeSize(1)], ...
                'min', 1, 'max', this.volumeSize(3), 'value', ...
                    round(this.volumeSize(3)/2), ...
                'sliderstep', [1/this.volumeSize(3), 10/this.volumeSize(3)], ...
                'callback', {@(src, event) scrollCallback(this, src, event)});
            
            %Create the return button
            this.returnButton = uicontrol(...
                'style', 'pushbutton', ...
                'string', 'Close and Return Cropping Values', ...
                'fontsize', 9, ...
                'Position', [this.volumeSize(2) + 50, ...
                    this.volumeSize(2) - 50, 200, 30], ...
                'callback', {@(src, event) returnButtonCallback(this, src, event)});
            
            %Create the x position display
            this.positionDisplayX = uicontrol(...
                'style', 'text', ...
                'position', [this.volumeSize(2) + 50, ...
                    this.volumeSize(2) - 125, 200, 25],...
                'fontsize', 12, ...
                'fontweight', 'bold', ...
                'Backgroundcolor', get(gcf, 'color'));
            
            %Create the y position display
            this.positionDisplayY = uicontrol(...
                'style', 'text', ...
                'position', [this.volumeSize(2) + 50, ...
                    this.volumeSize(2) - 150, 200, 25], ...
                'fontsize', 12, ...
                'fontweight', 'bold', ...
                'Backgroundcolor', get(gcf, 'color'));
            
            %show an image in the middle of the stack
            imshow(this.volume(:,:, round(this.volumeSize(3))/2), [0 5000]);
            
            %Create the cropping rectangle
            this.createCroppingROI();
        end
        
        %post: Creates the cropping rectangle using the desired image size
        function createCroppingROI(this)
            this.croppingROI  = imrect(gca, [0, 0, this.imageSize, this.imageSize]);
            setResizable(this.croppingROI, false);
            fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
            setPositionConstraintFcn(this.croppingROI,fcn);
            addNewPositionCallback(this.croppingROI, @(p) croppingROIPositionCallback(this, p));
            outputX = ['xMin = 0 xMax = ' num2str(this.imageSize)];
            set(this.positionDisplayX, 'string', outputX);
            outputY = ['yMin = 0 yMax = ' num2str(this.imageSize)];
            set(this.positionDisplayY, 'string', outputY);
        end
        
        %post: Returns the cropping values
        function croppingValue = getCroppingValues(this)
            croppingValue = this.cropValues;
        end
        
        %post:Returns the handle of the frame
        function f = getFrame(this)
            f = this.frame();
        end
    end
    
    methods 
        %post: Changes the image to the correct slice when using the scroll
        %      bar
        function scrollCallback(this, src, event)
            value = round(get(this.scroll, 'Value'));
            axes(this.display);
            imshow(this.volume(:,:,value), [0 5000]);
            this.createCroppingROI();
        end

        %post: Save the cropping values and closes the gui
        function returnButtonCallback(this, src, event)
            value = ceil(getPosition(this.croppingROI));
            this.cropValues = [value(1), value(1) + this.imageSize-1; ...
                value(2), value(2) + this.imageSize - 1];
            close(this.frame);
        end

        %post: Updates the x and y position display as the cropping
        %      rectangle is moved around in different position of hte image
        function croppingROIPositionCallback(this, p)
            position = ceil(p);
            outputX = ['xMin = ' num2str(position(1)) '    xMax = ' num2str(position(1) + 512 - 1)];
            outputY = ['yMin = ' num2str(position(2)) '    xMax = ' num2str(position(2) + 512 - 1)];

            set(this.positionDisplayX, 'string', outputX);
            set(this.positionDisplayY, 'string', outputY);
        end
    end
    
end

