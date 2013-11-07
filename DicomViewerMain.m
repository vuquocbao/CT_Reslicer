clear all
close all
clc

model = DicomViewerModel();
view = DicomViewerView(model);
controller = DicomViewerController(model, view);