%% CLASS HEADER INFORMATION
%By: QuocBao Vu
%Created: 12/28/2012
%Modified: 1/29/2012
%
%Description:
%
%This class is exactly the same as Dicom3D by instead of sorting by file
%number the files will be sorted by the filename. This class has all the
%same methods as Dicom3D and is used in the secondary window in the viewer

%% CLASS DEFINITION
classdef Dicom3DFilename < Dicom3D
    %DICOM3DFILENAME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        %Post: Creates a Dicom3DFilename Object by classing its super class
        function this = Dicom3DFilename(directory)
            this = this@Dicom3D(directory);
        end
    end
    
    methods (Access = protected)
        %post: Returns the image files sorted by filename
        function fileOrder = getFileOrder(this)
            fileOrder = this.fileset;
        end
    end
    
end
%% CLASS DEFINITION

