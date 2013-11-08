%% CLASS HEADER INFORMATION
%By: QuocBao Vu
%Created: Dec, 28, 2012
%Modified: Dec. 28, 2012
%Version: 1
%
%This class is a dialog window for the dicom reslicing program. It will
%notify when the gui is processing the data and tell the user to wait for
%the process to be finish. Once the process is finish the dialog window
%will be closed.

%% CLASS DEFINITION
classdef ProcessingDialog < handle
    
    properties
        frame;          %The dialog window
        text;           %The dialog message to display
    end
    
    methods
        %Post: Constructs the Dialog window. The window initial visibility
        %is set to off meaning the user cannot see it on display. To open
        %the dialog window the visibility is set to on.
        function this = ProcessingDialog()
            if (~isempty(findobj('name', 'Dialog')))
                close(findobj('name', 'Dialog'))
            end
            this.frame = figure;
            set(this.frame, 'visible', 'off')
            set(this.frame, 'Name', 'Dialog');
            set(this.frame, 'position', [0, 0, 350, 75]);
            set(this.frame, 'resize', 'off');
            set(this.frame, 'menubar', 'none');
            set(this.frame, 'Color', [.85 .85 .85]);
            movegui(this.frame, 'center');
            
            this.text = uicontrol(...
                'style', 'text', ...
                'background', [.85 .85 .85], ...
                'parent', this.frame, ...
                'units', 'normalized', ...
                'fontsize', 9, ...
                'fontweight', 'bold', ...
                'position', [.2 .25 .6 .4], ...
                'string', 'Operation in Progress... Please Wait');
        end
        
        %post: Open the dialog window by setting is visiblity on
        function run(this)
            movegui(this.frame, 'center');
            set(this.frame, 'visible', 'on');
            pause(.25);
        end
        
        %post: Close the dialog window by setting the visibility off
        function close(this)
            set(this.frame, 'visible', 'off');
        end
        
    end
end

%% END CLASS DEFINITION