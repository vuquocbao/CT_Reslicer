%% FILE INFORMATION
%By: QuocBao Vu
%Last Modification: 11/7/2013
%
%This scripts initializes the GUI and software to reslice CT dicom image
%stacks

%% EXECUTION CODE
clear all
close all
clc

%Create the model, view, and controller for the gui and run the program
model = DicomViewerModel();
view = DicomViewerView(model);
controller = DicomViewerController(model, view);

%% END PROGRAM