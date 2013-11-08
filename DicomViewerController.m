%% CLASS HEADER INFORMATION
%By: QuocBao Vu
%Created: Dec. 17, 2012
%Updated: Dec. 17, 2012
%Version: 3
%
%This is the controller class for the DicomViewer. It handles all the
%actions done by the user to the control and updates the model and view
%depending on the button that was pressed.

%% CLASS DEFINITION
classdef DicomViewerController < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frame;                      %Window
        model;                      %Gui's data
        view;                       %Gui's display to user
        
        dirPanelMain;               
        dirPanelSec;
        dirTextMain;
        dirTextSec;
        dirBrowserMain;
        dirBrowserSec;
        loadMain;
        loadSec;
        
        scrollMain;
        scrollSec;
        
        rotationPanel;
        rotateU;
        rotateD;
        rotateR;
        rotateL;
        rotateCCW;
        rotateCW;
        resetRotation;
        
        contrastPanelMain;
        contrastPanelSec;
        contrastMaxSetMain;
        contrastMinSetMain;
        contrastMaxSetSec;
        contrastMinSetSec;
        
        pixelSpacingPanel;
        pixelSpacingInput;
        matchSecPixel;
        pixelExecuteButton;
        
        modPanel;
        makeIsometric;
        invertImage;
        reset;
        
        compressPanel;
        compressButton;
        compressInput;
        
        writePanel;
        writeButton;
        writeDirectory;
        writeBrowser;
        filenameText;
        filenameInput;
        
        dialog;
    end
    
    methods
        
        %post: Contruct the DicomView Program with all the components and
        %      set the view and model
        function this = DicomViewerController(model, view)
            if (~isempty(findobj('name', 'DicomReslicingProgram')))
                close(findobj('name', 'DicomReslicingProgram'))
            end
            
            this.model = model;
            this.view = view;
            
            %Construct Figure
            this.frame = figure;
            set(this.frame, 'name', 'DicomReslicingProgram');
            set(this.frame, 'units', 'pixel', 'outerposition', [0 0 , 1600, 840], 'resize', 'off')
            set(this.frame, 'numbertitle', 'off');
            set(this.frame, 'menubar', 'none');
            movegui(this.frame, 'center')
         
            %Add Controls
            this.addDirectoryControls();
            this.addRotationControls();
            this.addScrollBars();
            this.addContrastControls();
            this.addPixelSpacingModControls();
            this.addOtherModControls();
            this.addCompressionControls();
            this.addOutputControls();
            
            %Add View Components
            view.addDisplay(this.frame);
            view.addDirTextBox(this.dirPanelMain, this.dirPanelSec);
            view.addInfoDisplay(this.frame);
            
            this.dialog = ProcessingDialog();
        end
    end
    
    %Control Construction
    methods
        %post: Create the directory controls with the load button for the
        %      main and secondary side
        function addDirectoryControls(this)
            %Main 
            %Directory Panel
            this.dirPanelMain = uipanel();
            set(this.dirPanelMain, ...
                'units', 'pixel', ...
                'position', [555, 667, 240, 130]);
            %Browser Button
            this.dirBrowserMain = uicontrol('style', 'pushbutton');
            set(this.dirBrowserMain, ...
                'parent', this.dirPanelMain, ...
                'units', 'normalized', ...
                'position', [.1 .25 .8 .15], ...
                'string', 'Select Directory', ...
                'callback', {@(src, event) dirBrowserMainCallback(this, src, event)});
            %Load Button
            this.loadMain = uicontrol('style', 'pushbutton');
            set(this.loadMain, ... 
                'parent', this.dirPanelMain, ...
                'units', 'normalized', ...
                'position', [.1 .05 .8 .15], ...
                'string' , 'Load Dicom Files', ...
                'enable', 'off', ...
                'callback', {@(src, event) loadMainCallback(this, src, event)});
            
            %Seconday 
            %Directory Panel
            this.dirPanelSec = uipanel();
            set(this.dirPanelSec, ...
                'units', 'pixel', ...
                'position', [1345, 667, 240, 130]);
            %Browser Button
            this.dirBrowserSec = uicontrol('style', 'pushbutton');
            set(this.dirBrowserSec, ...
                'parent', this.dirPanelSec, ...
                'units',' normalized', ...
                'position', [.1 .25 .8 .15], ...
                'string', 'Select Directory', ...
                'enable', 'off', ...
                'callback', {@(src, event) dirBrowserSecCallback(this, src, event)});
            %Load Button
            this.loadSec = uicontrol('style', 'pushbutton');
            set(this.loadSec, ...
                'parent', this.dirPanelSec, ...
                'units', 'normalized', ...
                'position', [.1 .05 .8 .15], ...
                'string', 'Load Dicom Files', ...
                'enable', 'off', ...
                'callback', {@(src, event) loadSecCallback(this, src, event)});
        end
        
        %post: Create the scroll bars for the main and secondary side
        function addScrollBars(this)
            %Main
            this.scrollMain = uicontrol(...
                'style', 'slider', ...
                'position', [530 285 20 512], ...
                'min', 1, ...
                'max', 512, ...
                'value', 1, ...
                'sliderstep', [.01, .10], ...
                'enable', 'off', ...
                'callback', {@(src, event) scrollMainCallback(this, src, event)});
            %Secondary
            this.scrollSec = uicontrol(...
                'style', 'slider', ...
                'position', [1320 285 20 512], ...
                'min', 1, ...
                'max', 512, ...
                'value', 1, ...
                'sliderstep', [.01 .10], ...
                'enable', 'off', ...
                'visible', 'on', ...
                'callback', {@(src, event) scrollSecCallback(this, src, event)});
        end
        
        %post: Create the rotation controls for modifiy in the data on the
        %      main side
        function addRotationControls(this)
            this.rotationPanel = uipanel(...
                'units', 'pixels', ...
                'position', [15 20 350 250]);
            this.rotateU = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.35 .8 .30 .15], ...
                'string', 'Rotate Up', ...
                'enable', 'off', ...
                'callback', {@(src, event) rotateUpCallback(this, src, event)});
            this.rotateD = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.35 .30 .30 .15], ...
                'string', 'Rotate Down', ...
                'enable', 'off', ...
                'callback', {@(src, event) rotateDownCallback(this, src, event)});
            this.rotateL = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.025 .55 .30 .15], ...
                'string', 'Rotate Left', ...
                'enable', 'off', ...
                'callback', {@(src, event) rotateLeftCallback(this, src, event)});
            this.rotateR = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.675 .55 .30 .15], ...
                'string', 'Rotate Right', ...
                'enable', 'off', ...
                'callback', {@(src, event) rotateRightCallback(this, src, event)});
            this.rotateCW = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.1 .05 .35 .15], ...
                'string', 'Rotate CW', ...
                'enable', 'off', ...
                'callback', {@(src, event) rotateCWCallback(this, src, event)});
            this.rotateCCW = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.55 .05 .35 .15], ...
                'string', 'Rotate CWW', ...
                'enable', 'off', ...
                'callback', {@(src, event) rotateCCWCallback(this, src, event)});
            this.resetRotation = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.rotationPanel, ...
                'units', 'normalized', ...
                'position', [.35 .55 .30 .15], ...
                'string', 'Reset', ...
                'enable', 'off', ...
                'callback', {@(src, event) resetRotationCallback(this, src, event)});
        end
        
        %post: Create the contrast text boxes to adjust the contrast of the
        %      images for both the main and secondary side
        function addContrastControls(this)
            %Main
            this.contrastPanelMain = uipanel(...
                'units', 'pixel', ...
                'position', [555 625, 240, 35]);
            mainContrastMinText = uicontrol('style', 'text');
            set(mainContrastMinText, ...
                'parent', this.contrastPanelMain, ...
                'units', 'pixel', ...
                'position', [5, 5, 30, 20], ...
                'fontsize', 10, ...
                'string', 'Min');
            mainContrastMaxText = uicontrol('style', 'text');
            set(mainContrastMaxText, ...
                'parent', this.contrastPanelMain, ...
                'units', 'pixel', ...
                'position', [115, 6, 30, 20], ...
                'fontsize', 10, ...
                'string', 'Max');
            this.contrastMinSetMain = uicontrol(...
                'style', 'edit', ...
                'parent', this.contrastPanelMain, ...
                'position', [45 6 60 20], ...
                'string', 0, ...
                'enable', 'off', ...
                'callback', {@(src, event) contrastMinSetMainCallback(this, src, event)});
            this.contrastMaxSetMain = uicontrol(...
                'style', 'edit', ...
                'parent', this.contrastPanelMain, ...
                'position', [155 6 60 20], ...
                'string', 2500, ...
                'enable', 'off', ...
                'callback', {@(src, event) contrastMaxSetMainCallback(this, src, event)});
            
            %Secondary
                this.contrastPanelSec = uipanel( ...
                    'units', 'pixel', ...
                    'position', [1345 625, 240, 35]);
                secondaryContrastMinText = uicontrol('style', 'text');
                set(secondaryContrastMinText, ...
                    'parent', this.contrastPanelSec, ...
                    'units', 'pixel', ...
                    'position', [5, 5, 30, 20], ...
                    'fontsize', 10, ...
                    'string', 'Min');
                secondaryContrastMaxText = uicontrol('style', 'text');
                set(secondaryContrastMaxText, ...
                    'parent', this.contrastPanelSec, ...
                    'units', 'pixel', ...
                    'position', [115, 6, 30, 20], ...
                    'fontsize', 10, ...
                    'string', 'Max');
                this.contrastMinSetSec = uicontrol(...
                    'style', 'edit', ...
                    'parent', this.contrastPanelSec, ...
                    'position', [45 6 60 20], ...
                    'string', 0, ...
                    'enable', 'off', ...
                    'callback', {@(src, event) contrastMinSetSecCallback(this, src, event)});
                this.contrastMaxSetSec = uicontrol(...
                    'style', 'edit', ...
                    'parent', this.contrastPanelSec, ...
                    'position', [155 6 60 20], ...
                    'string', 2500, ...
                    'enable', 'off', ...
                    'callback', {@(src, event) contrastMaxSetSecCallback(this, src, event)});


        end
        
        %post: Create the controls to modify the pixel spacing of the data
        %      on the main side
        function addPixelSpacingModControls(this)
            this.pixelSpacingPanel = uipanel(...
                'units', 'pixels', ...
                'position', [555, 460, 240, 85]);
            text = uicontrol('style', 'text');
            set(text, ...
                'parent', this.pixelSpacingPanel, ...
                'units', 'normalized', ...
                'position', [.25 .7 .5 .25], ...
                'fontsize', 9, ...
                'fontweight', 'bold', ...
                'string', 'Target Pixel Spacing');
            this.pixelSpacingInput = uicontrol(...
                'style', 'edit', ...
                'parent', this.pixelSpacingPanel, ...
                'units', 'normalized', ...
                'position', [.25 .45 .5 .25], ...
                'enable', 'off', ...
                'callback', {@(src, event) pixelSpacingInputCallback(this, src, event)});
            this.matchSecPixel = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.pixelSpacingPanel, ...
                'units', 'normalized', ...
                'position', [.025 .1 .47 .275], ...
                'enable', 'off', ...
                'string', 'Match Other Volume', ...
                'callback', {@(src, event) matchSecPixelCallback(this, src, event)});
            this.pixelExecuteButton = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.pixelSpacingPanel, ...
                'units', 'normalized', ...
                'position', [.505 .1 .47 .275], ...
                'enable', 'off', ...
                'string', 'Execute', ...
                'callback', {@(src, event)  pixelExecuteButtonCallback(this, src, event)});
        end
        
        %post: Create the other modification controls which include
        %      inversion, making the colume isometric and reseting all 
        %      changes for the data on the main side
        function addOtherModControls(this)
            this.modPanel = uipanel(...
                'units', 'pixel', ...
                'position', [555 375 240 80]);
            this.makeIsometric = uicontrol('style', 'pushButton', ...
                'parent', this.modPanel, ...
                'units', 'normalized', ...
                'position', [.1 .675 .8 .275], ...
                'string', 'Make Isometric', ...
                'enable', 'off', ...
                'callback', {@(src, event) makeIsometricCallback(this, src, event)});
            this.invertImage = uicontrol(...
                'style', 'togglebutton', ...
                'parent', this.modPanel, ...
                'units', 'normalized', ...
                'position', [.1 .3575 .8 .275], ...
                'string', 'Invert', ...
                'enable', 'off', ...
                'callback', {@(src, event) invertImageCallback(this, src, event)});
            this.reset = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.modPanel, ...
                'units', 'normalized', ...
                'position', [.1 .05 .8 .275], ...
                'string', 'Reset All Changes', ...
                'enable', 'off', ...
                'callback', {@(src, event) resetCallback(this, src, event)});
        end
        
        %post: Create the controls to compress the number of slice. These
        %      controls can be used to change the slicespacing also
        function addCompressionControls(this)
            this.compressPanel = uipanel(...
                'units', 'pixels', ...
                'position', [555 285 240 85]);
            this.compressButton = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.compressPanel, ...
                'units', 'normalized', ...
                'position', [.25 .1 .5 .275], ...
                'string', 'Compress Slices', ...
                'enable', 'off', ...
                'callback', {@(src, event) compressButtonCallback(this, src, event)});
            compressSliceText = uicontrol('style', 'text');
            set(compressSliceText, ...
                'parent', this.compressPanel, ...
                'units', 'normalized', ...
                'fontsize', 9, ...
                'fontweight', 'bold', ...
                'position', [.1 .75 .8 .2], ...
                'string', 'Target Slice Spacing');
            this.compressInput = uicontrol('style', 'edit');
            set(this.compressInput, ...
                'parent', this.compressPanel, ...
                'units', 'normalized', ...
                'enable', 'off', ...
                'position', [.25 .45 .5 .25], ...
                'callback', {@(src, event) compressInputCallback(this, src, event)});
        end
        
        %post: Create the output and writing the controls for the data in
        %      the main side
        function addOutputControls(this)
            this.writePanel = uipanel();
            set(this.writePanel, ...
                'units', 'pixel', ...
                'position', [375 20 240, 250]);

            this.writeButton = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.writePanel, ...
                'units', 'normalized', ...
                'position', [.1 .075 .8 .08], ...
                'string' , 'Write Files', ...
                'enable', 'off', ...
                'callback', @(src, event) writeButtonCallback(this, src, event));

            directoryText = uicontrol(...
                'style', 'text', ...
                'parent', this.writePanel, ...
                'units', 'normalized', ...
                'position', [.2 .85 .6 .1], ...
                'fontweight', 'bold', ...
                'fontsize', 9, ...
                'string', 'Output Directory');
            
            this.writeDirectory = uicontrol(...
                'style', 'text', ...
                'parent', this.writePanel, ...
                'units', 'normalized', ...
                'position', [.05 .6 .9 .25], ...
                'backgroundcolor', [1 1 1]);

            this.writeBrowser = uicontrol(...
                'style', 'pushbutton', ...
                'parent', this.writePanel, ...
                'units',' normalized', ...
                'position', [.1 .185 .8 .08], ...
                'string', 'Select Directory', ...
                'enable', 'off', ...
                'callback', {@(src, event) writeBrowserCallback(this, src, event)});
            
            this.filenameText = uicontrol(...
                'style', 'text', ...
                'parent', this.writePanel, ...
                'units', 'normalized', ...
                'position', [.2 .475 .6 .1], ...
                'fontweight', 'bold', ...
                'fontsize', 9, ...
                'string', 'Ouput Filename');
            
            this.filenameInput = uicontrol(...
                'style', 'edit', ...
                'parent', this.writePanel, ...
                'units', 'normalized', ...
                'position', [.2 .325 .6 .15], ...
                'enable', 'off', ...
                'string', this.model.getOutputFilename(), ...
                'background', [1 1 1], ...
                'callback', {@(src, event) filenameInputCallback(this, src, event)});
        end        
    end
    
    %Callback Functions
    methods
        %post: Launches a directory browser to choose the input directory
        %      for the main side
        function dirBrowserMainCallback(this, src, event)
            dir = this.model.getMainDirectory();
            if (~isempty(dir))
                if (isa(dir, 'char'))
                    inputDir = uigetdir(dir);
                else
                    inputDir = uigetdir();
                end
            else
                inputDir = uigetdir();
            end
            
            this.model.setMainDirectory(inputDir);
            set(this.loadMain, 'enable', 'on');
            this.view.updateMain();
        end
        
        %post: Launches a directory browser to choose the input directory
        %      for the secondary side
        function dirBrowserSecCallback(this, src, event)
            dir = this.model.getSecDirectory();
            if (~isempty(dir))
                if (isa(dir, 'char'))
                    inputDir = uigetdir(dir);
                else
                    inputDir = uigetdir();
                end
            else
                inputDir = uigetdir();
            end
            
            this.model.setSecDirectory(inputDir);
            set(this.loadSec, 'enable', 'on');
            this.view.updateSec();
        end
        
        %post: Load the data in the main input directory and active all the
        %      disble controls and updates the view
        function loadMainCallback(this, src, event)
            this.dialog.run();
%             pause(.25);
            this.model.loadMainData();
            if (this.model.isLoadMainSuccessful())
                this.activateMainControls();
                this.syncMainControls();
            end
            this.view.updateMainDisplay();
            this.view.updateMain();
            this.dialog.close();
        end
        
        %post: Load the data on to the secondary side using the secondary
        %      input directory that was chooses and enable any disable
        %      controls also updating the view
        function loadSecCallback(this, src, evet)
            this.dialog.run();
            this.model.loadSecData();
            if (this.model.isLoadSecSuccessful())
                this.activeSecControls();
                this.syncSecControls();
            end
            this.view.updateSecDisplay();
            this.view.updateSec();
            this.dialog.close();
        end
        
        %post: Update the slice that is being display in the main side to
        %      the slice specified by the slider
        function scrollMainCallback(this, src, event)
            sliderValue = get(src, 'value');
            this.model.setMainSliderValue(sliderValue);
            this.view.updateMainDisplay();
        end
        
        %post: Updates the slice that is being display in the secondary
        %      side to the slice specified by the slider
        function scrollSecCallback(this, src, event)
            sliderValue = get(src, 'value');
            this.model.setSecSliderValue(sliderValue);
            this.view.updateSecDisplay();
        end
        
        %post: Sets the min contrast value on the main side to the user
        %   input and then update the view to adjust the main image to the
        %   correct contrast level
        function contrastMinSetMainCallback(this, src, event)
            value = str2double(get(src, 'string'));
            if (~isempty(value))
                this.model.setMainContrastMin(value);
                this.view.updateMainDisplay();
            end
        end
        
        %post: Sets the max contrat value on the main side to the user
        %      input and then update the view to adjust the main image to 
        %      the correct contrast level
        function contrastMaxSetMainCallback(this, src, event)
            value = str2double(get(src, 'string'));
            if (~isempty(value))
                this.model.setMainContrastMax(value);
                this.view.updateMainDisplay();
            end
        end
        
        %post: Sets the min contrast value on the secondary side to the
        %      user input and then updates the view to adjust the secondary
        %      image to the correct contrast level
        function contrastMinSetSecCallback(this, src, event)
            value = str2double(get(src, 'string'));
            if (~isempty(value))
                this.model.setSecContrastMin(value);
                this.view.updateSecDisplay();
            end
        end
        
        %post: Set the max contrast value on the secondary side to the user
        %      input and then updates the view to adjust the secondary
        %      image to the correct contrast level
        function contrastMaxSetSecCallback(this, src, event)
            value = str2double(get(src, 'string'));
            if (~isempty(value))
                this.model.setSecContrastMax(value);
                this.view.updateSecDisplay();
            end
        end
        
        %post: Invert the 3D image on the main side
        function invertImageCallback(this, src, event)
            this.model.invert();
            set(this.invertImage, 'value', this.model.isInverted());
            this.model.logPush('Invert');
            this.view.updateMainDisplay();
        end
        
        %post: Makes the 3D image on the main side isometric. Also updating
        %      the scroll bars max level and setting the image back to
        %      slice 1.
        function makeIsometricCallback(this, src, event)
            this.dialog.run();
            if (~this.model.isIsometric())
                this.model.makeIsometric();
                set(this.scrollMain, 'value', this.model.getMainSliderValue());
                set(this.scrollMain, 'max', this.model.getMainSliderMax());
                this.view.updateMainDisplay();
                this.view.updateMain();
            end
            this.activeRotationControls()
            this.model.logPush('ISO');
            this.dialog.close();
        end
        
        %post: Reset all changes made to the 3D image on the main side and
        %      reset all the control values back to the original values
        function resetCallback(this, src, event)
            this.model.reset();
            set(this.scrollMain, 'value', this.model.getMainSliderValue());
            set(this.scrollMain, 'max', this.model.getMainSliderMax());
            this.view.updateMainDisplay();
            this.view.updateMain();
            set(this.invertImage, 'value', this.model.isInverted());
            this.model.logPush('Reset');
        end
        
        %post: Set the new pixel spacing for the main 3D image to the user
        %      input, enabling the execute button if the input is valid
        function pixelSpacingInputCallback(this, src, event)
            string = get(src, 'string');
            value = str2double(string);
            if (~isempty(value))
                this.model.setTargetPixelSpacing(value);
                set(this.pixelExecuteButton, 'enable', 'on');
            else
                set(this.pixelExecuteButton, 'enable', 'off');
            end
        end
        
        %post: Matches the new pixel spacing for the main 3D image to the
        %      pixel spacing of the 3D image on the secondary side 
        function matchSecPixelCallback(this, src, event)
            secPixelSpacing = this.model.getSecPixelSpacing;
            this.model.setTargetPixelSpacing(secPixelSpacing);
            set(this.pixelSpacingInput, 'string', num2str(secPixelSpacing));
            set(this.pixelExecuteButton, 'enable', 'on');
        end
        
        %post: Changes the pixel spacing of the 3D image on the main side
        %      to the new pixel spacing inputed by the user in the text box
        function pixelExecuteButtonCallback(this, src, event)
            this.model.changePixelSpacing();
            set(this.scrollMain, 'value', this.model.getMainSliderValue());
            set(this.scrollMain, 'max', this.model.getMainSliderMax());
            this.view.updateMain();
            this.view.updateMainDisplay();
            this.model.logPush('CPS');
        end
        
        %post: Reset all rotation made on the 3D image on the main side
        function resetRotationCallback(this, src, event)
            this.model.resetRotation();
            this.view.updateMainDisplay();
            this.model.logPush('resetRotation');
        end
        
        %post: Rotate the 3D image on the main side clockwise about the
        %      horizontal axis
        function rotateUpCallback(this, src, event)
            this.dialog.run();
            this.model.rotateUp();
            this.view.updateMainDisplay();
            this.model.logPush('upR');
            this.dialog.close();
        end
        
        %post: Rotate the 3D image on the main side counter clockwise about
        %      the horizontal axis
        function rotateDownCallback(this, src, event)
            this.dialog.run();
            this.model.rotateDown();
            this.view.updateMainDisplay();
            this.model.logPush('downR');
            this.dialog.close();
        end
        
        %post: Rotate the 3D image on the main side clockwise about the
        %      vertical axis
        function rotateLeftCallback(this, src, event)
            this.dialog.run();
            this.model.rotateLeft();
        	this.view.updateMainDisplay();
            this.model.logPush('leftR');
            this.dialog.close();
        end
        
        %post: Rotate the 3D image on the main side counter clockwise about
        %      the veritcal axis
        function rotateRightCallback(this, src, event)
            this.dialog.run();
            this.model.rotateRight();
            this.view.updateMainDisplay();
            this.model.logPush('rightR');
            this.dialog.close();
        end
        
        %post: Rotate the 3D image on the main side counter clockwise
        %      inplane
        function rotateCCWCallback(this, src, event)
            this.dialog.run();
            this.model.rotateCCW();
            this.view.updateMainDisplay();
            this.model.logPush('ccwR');
            this.dialog.close();
        end
        
        %post: Rotate the 3D image on the main side clockwise inplane
        function rotateCWCallback(this, src, event)
            this.dialog.run();
            this.model.rotateCW();
            this.view.updateMainDisplay();
            this.model.logPush('cwR');
            this.dialog.close();
        end
        
        %post: Set the desired slice spacing for compress. Expansion of the
        %      number of slice is also allowed
        function compressInputCallback(this, src, event)
            value = str2double(get(src, 'string'));
            if (~isempty(value))
                this.model.setCompressSliceSpacing(value);
                set(this.compressButton, 'enable', 'on');
            else
                set(this.compressButton, 'enable', 'off');
            end
        end
        
        %post: Compress the number slice using the input slice spacing
        %      specified by the user in the text box. This can also be used
        %      to expand the number of slices
        function compressButtonCallback(this, src, event)
            this.dialog.run();
            this.model.compress();
            set(this.scrollMain, 'value', this.model.getMainSliderValue());
            set(this.scrollMain, 'max', this.model.getMainSliderMax());
            this.view.updateMain();
            this.view.updateMainDisplay();
            this.model.logPush('Compress');
            this.dialog.close();
        end
        
        %post: Launches a browser to select the output or write directory
        %      of the 3D image on the main side
        function writeBrowserCallback(this, src, event)
            dir = this.model.writeDir();
            if (~isempty(dir))
                if (isa(dir, 'char'))
                    inputDir = uigetdir(dir);
                else
                    inputDir = uigetdir();
                end
            else
                inputDir = uigetdir();
            end
            this.model.setWriteDir(inputDir);
            set(this.writeButton, 'enable', 'on');
            this.model.printLog();
            set(this.writeDirectory, 'string', inputDir);
            
        end
        
        %post: Writes the 3D image on the main side to dicom files
        function writeButtonCallback(this, src, event)
            this.dialog.run();
            this.model.write();
            this.dialog.close();
        end 
        
        %post: Set the output filename inputed by the user.
        function filenameInputCallback(this, src, event)
            string = get(src, 'string');
            this.model.setOutputFilename(string);
        end
    end
    
    methods 
        %post: Activate certain controls when data is successfully load on
        %      the main side
        function activateMainControls(this)
            set(this.scrollMain, 'enable', 'on');
%             set(this.pixelExecuteButton, 'enable', 'on');
            set(this.makeIsometric, 'enable', 'on');
            set(this.invertImage, 'enable', 'on');
            set(this.reset, 'enable', 'on');
            set(this.pixelSpacingInput, 'enable', 'on');
            set(this.dirBrowserSec, 'enable', 'on');
            set(this.pixelSpacingInput, 'enable', 'on');
            set(this.writeBrowser, 'enable', 'on');
            set(this.filenameInput, 'enable', 'on');
            set(this.writeDirectory, 'enable', 'on');
            set(this.contrastMinSetMain, 'enable', 'on');
            set(this.contrastMaxSetMain, 'enable', 'on');
            set(this.compressInput, 'enable', 'on');
        end
        
        %post: Syncs the control values to values in the model
        function syncMainControls(this)
            set(this.scrollMain, 'value', this.model.getMainSliderValue());
            set(this.scrollMain, 'max', this.model.getMainSliderMax());
            set(this.invertImage, 'value', this.model.isInverted());
            set(this.filenameInput, 'string', this.model.getOutputFilename());
        end
        
        %post: Activate certian controls on the seoncdary side when data is
        %      successfully load on the secondary side
        function activeSecControls(this)
            set(this.loadSec, 'enable', 'on');
            set(this.scrollSec, 'enable', 'on');
            set(this.matchSecPixel, 'enable', 'on');
            set(this.contrastMinSetSec, 'enable', 'on');
            set(this.contrastMaxSetSec, 'enable', 'on');
        end
        
        %post: Sync the controls on the secondary side to the model
        function syncSecControls(this)
            set(this.scrollSec, 'max', this.model.getSecSliderMax());
        end
        
        %post: Actives the rotation controls after th volume is isometric
        function activeRotationControls(this)
            set(this.rotateU, 'enable', 'on');
            set(this.rotateD, 'enable', 'on');
            set(this.rotateR, 'enable', 'on');
            set(this.rotateL, 'enable', 'on');
            set(this.rotateCW, 'enable', 'on');
            set(this.rotateCCW, 'enable', 'on');
            set(this.resetRotation, 'enable', 'on');
        end
        
        %post: Deactivate the rotation controls when the volume is not
        %      isometric anymore
        function deactivateControls(this)
            set(this.rotateU, 'enable', 'off');
            set(this.rotateD, 'enable', 'off');
            set(this.rotateR, 'enable', 'off');
            set(this.rotateL, 'enable', 'off');
            set(this.rotateCW, 'enable', 'off');
            set(this.rotateCCW, 'enable', 'off');
            set(this.resetRotation, 'enable', 'off');
        end
    end
    
end
%% END DEFINITION

