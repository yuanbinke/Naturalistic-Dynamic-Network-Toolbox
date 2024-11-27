function computeSFCByMat(inputdir, saveDir, app)
% computeSFC() can compute n(n>=1) subject's static function connectivity by their ROI time course  
% INPUT:
% inputdir    - is the directory which contains all the subjects' ROI time
% course mat rerult. Every subject has a corresponding mat file(The mat matrix's
% shape like nT * nROI).
% saveDir     - a path which contain the results of SFC
% app         - a optional argument, is a uiobject
%
% The output is the results of SFC which will be save saveDir
%


desdir = saveDir;
if ~exist(desdir)
    mkdir(desdir)
end

ROI_TC = read_2Dmat_2_3DmatrixROITC(inputdir);
disp('loading done!!! \n')
%% static FC
fprintf('Calculating SFC...')
fileList = dir('*.mat');
if size(fileList, 1) == 0
    fileList = dir('*.txt');
end

if nargin == 3
    app.ax.Title.String = 'Calculating SFC...';
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end

Nsub = length(fileList);
for subNum = 1:size(fileList, 1)
    fprintf('..')
    subtc = squeeze(ROI_TC(:, :, subNum));%time * ROI
    corr_matrix = corr(subtc, subtc);
    SFC = 0.5 * log((1 + corr_matrix) ./ (1 - corr_matrix));
    SFC(logical(eye(size(SFC)))) = 0;% set diagonal to 0

    [~, name, ~] = fileparts(fileList(subNum).name);
    resultName = fullfile(desdir, [name '.mat']);
    save(resultName, "SFC");
    
    if nargin == 3
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'Calculating SFC ' jindu '%...'];
        drawnow
    end

end
disp('Done !')

end




