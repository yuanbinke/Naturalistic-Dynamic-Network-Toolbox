function NDN_ISFC(inputdir, method, saveDir, app)
%NDN_ISFC Compute Static or Inter-Subject Functional Connectivity
%NDN_ISFC(INPUTDIR, METHOD, SAVEDIR, APP) calculates either Static 
%Functional Connectivity (SFC) or Inter-Subject Functional Connectivity 
%(ISFC) based on the specified method.
% 
% INPUT:
%     INPUTDIR  - Path to directory containing subjects' ROI time course 
%                 data. Each subject should have a MAT file with matrix 
%                 dimensions [nT x nROI], where:
%                 nT   = Number of time points
%                 nROI = Number of regions of interest
%     METHOD    - Connectivity calculation method: 
%                 'SFC'  (Static Functional Connectivity) or 
%                 'ISFC' (Inter-Subject Functional Connectivity)
%     SAVEDIR   - Output directory for saving connectivity results
%     APP       - (Optional) UI object for progress display
% 
% Output:
%     Results are saved as MAT and TIF files in SAVEDIR per subject
% 
% Example:
%     NDN_ISFC('./data/ROI_timeseries', 'ISFC', './results/connectivity', app)


%% loading data
method = char(upper(method));

desdir = saveDir;
if ~exist(desdir)
    mkdir(desdir)
end

[ROI_TC, fileList] = read_2Dmat_2_3DmatrixROITC(inputdir);
disp('loading done!!! \n')

%% FC

if nargin == 4
    app.ax.Title.String = ['Calculating method...'];
    patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end

for subNum = 1:numel(fileList)
    tmp = ROI_TC;
    tmp(:, :, subNum) = [];
    meanTmp = mean(tmp, 3);
    LOO_Mean_BOLD(:, :, subNum) = meanTmp;
end

Nsub = length(fileList);
for subNum = 1:size(fileList, 1)
    fprintf('..')

    % get sub data
    subtc = squeeze(ROI_TC(:, :, subNum)); % time * ROI
    subtc_LOO = squeeze(LOO_Mean_BOLD(:, :, subNum)); % time * ROI

    % perform
    if isequal(method, 'ISFC')
        corr_matrix = corr(subtc, subtc_LOO);
    else
        corr_matrix = corr(subtc);
    end

    % fisher z
    ISFC = 0.5 * log((1 + corr_matrix) ./ (1 - corr_matrix));
    
    % fig
    fig = figure('Visible', 'off');
    imagesc(ISFC);
    colormap(jet);
    caxis([-1 1]);
    colorbar;
    title(method);
    set(gca, 'FontName','Arial','FontSize', 12);
    
    % save as mat
    [~, name, ~] = fileparts(fileList(subNum).name);
    matName = fullfile(desdir, [name '_' method '_.mat']);
    save(matName, "ISFC");
    
    % save as tif
    tifName = fullfile(desdir, [name '_' method '_.tif']);
    print(fig, '-dtiff', '-r300', tifName);
    close(fig)
    
    if nargin == 4
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f', subNum / Nsub * 100);
        app.ax.Title.String = ['Calculating ' method ' ' jindu '%...'];
        drawnow
    end
    
end
disp('Done !')

end




