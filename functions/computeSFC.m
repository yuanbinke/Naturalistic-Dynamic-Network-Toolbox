function [flag,errorsub] = computeSFC(inputdir, prefix, ROIMask, app)
%FORMAT [flag,errorsub] = computeSFC(inputdir, prefix, ROIMask, app)
% computeSFC computes the Static Functional Connectivity (SFC) for n (n >= 1) 
% subjects using their ROI time course data.
%
% INPUT:
%   inputdir        - A directory containing all subject data. Each subject's 
%                     data is stored in a separate subdirectory. The expected 
%                     structure is:
%                     - sub001/func/data_sub001.nii(.gz), recommended or
%                     - sub001/data_sub001.nii(.gz).
%
%   prefix          - A string used to identify the target subdirectories 
%                     within the inputdir. For example, if the subject 
%                     directories are named 'sub001', 'sub002', etc., the 
%                     prefix could be 'sub'.
%
%   ROIMask         - The file path to a mask file defining the regions of 
%                     interest (ROIs). This mask is used to extract time 
%                     course data from the specified ROIs.
%
%   app             - (Optional) A UI object (e.g., a progress bar or 
%                     message display) for providing feedback during the 
%                     execution of the function.
%
% OUTPUT:
%   The results of the SFC computation are saved in the directory 
%   inputdir/SFC_Result.
%
%   flag            - A status flag indicating the outcome of the function:
%                     - -1: Indicates that the subject (specified by errorsub) 
%                           has no .nii or .nii.gz file.
%                     -  0: Indicates that the provided prefix is incorrect 
%                           (no matching subdirectories or files were found).
%                     -  1: Indicates that the function completed successfully.
%
%   errorsub        - The index of the subject that has no .nii or .nii.gz 
%                     file. If no errors are found, this value is set to 0.
%


desdir=[inputdir filesep 'SFC_Result'];
if ~exist(desdir)
    mkdir(desdir)
end

if nargin == 4
    [ROI_TC, flag, errorsub] = getROITimeCourse(inputdir, prefix, ROIMask, app);
else
    [ROI_TC, flag, errorsub] = getROITimeCourse(inputdir, prefix, ROIMask);
end
disp('loading done!!! \n')
%% static FC
fprintf('Calculating SFC...')
sublist = getSublistByPrefixed(inputdir, prefix);

if nargin == 4
    app.ax.Title.String = 'Calculating SFC...';
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
    drawnow
end
Nsub = length(sublist);
for subNum = 1:size(sublist, 1)
    fprintf('..')
    subtc = squeeze(ROI_TC(:, :, subNum));%time * ROI
    corr_matrix = corr(subtc, subtc);
    SFC = 0.5 * log((1 + corr_matrix) ./ (1 - corr_matrix));

    resultName = [desdir filesep sublist(subNum).name '.mat'];
    save(resultName, "SFC");
    
    if nargin == 4
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'Calculating ISC ' jindu '%...'];
        drawnow
    end

end
disp('Done !')

end




