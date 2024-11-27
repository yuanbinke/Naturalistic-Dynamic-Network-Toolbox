function [flag,errorsub] = computeSFC(inputdir, prefix, ROIMask, app)
% computeSFC() can compute n(n>=1) subject's static function connectivity by their ROI time course  
% inputdir is the directory which  contains all the subject data，every
%   subject 4D—nii file is put in a subdirectory like
%   inputdir/sub001/data_sub001.nii or directly put in inputdir like inputdir/data_sub001.nii
% prefix is decided by the target subdirectorys in inputdir
% ROIMask is the address of the ROIMaks file
% app, a optional argument, is a uiobject

% the output is the results of SFC which will be save inputdir/SFC_Result
% flag : -1 means the subject(errorsub) has no nii file
%        0 means a incorrect prefix
%        1 means finishing successfully
% errorsub:represent the num of the subject(errorsub) which has no nii file


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




