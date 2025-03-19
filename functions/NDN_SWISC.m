function NDN_SWISC(inputdir, prefix, grayMatterMask, params, savedDir, app)
%FORMAT: NDN_SWISC(inputdir, prefix, grayMatterMask, params, savedDir, app)
% NDN_SWISC computes the Sliding-Window Intersubject Correlation (SWISC) 
% for gray matter voxels across multiple subjects.
%
% INPUT:
%   inputdir        - A directory containing all subject data. Each subject's 
%                     data is stored in a separate subdirectory. The expected 
%                     structure is:
%                     - sub001/func/data_sub001.nii(.gz), recommended or
%                     - sub001/data_sub001.nii(.gz).
%
%   prefix          - A string used to identify the target subdirectories 
%                     or files within the inputdir. For example, if the 
%                     subject directories are named 'sub001', 'sub002', etc., 
%                     the prefix could be 'sub'.
%
%   grayMatterMask  - The file path to a gray matter mask file. This mask is 
%                     used to extract time course data from the gray matter 
%                     region of the functional images.
%
%   params          - A structure containing parameters for the SWISC computation:
%       - wsize    : The size of the sliding window.
%       - sigma    : Parameters affecting the shape of the sliding window. 
%                    The default value is 3.
%
%   savedDir        - (Optional) The directory path where the SWISC results 
%                     will be saved. If not provided, the default path is 
%                     [inputdir filesep 'SWISC-Result']. The results include:
%                     - MAT files stored in the 'mat' subfolder.
%                     - 4D .nii files stored in the 'nii' subfolder.
%                     - Time-averaged 4D SWISC results stored in the 'niiMean' 
%                       subfolder.
%
%   app             - (Optional) A UI object (e.g., a progress bar or 
%                     message display) for providing feedback during the 
%                     execution of the function.


if ~isfield(params, "wsize")
    error("params.wsize should not be empty, it must be assgind ")
else
    wsize = params.wsize;
end

if ~isfield(params, "sigma")
    error("params.sigma should not be empty, it must be assgind ")
else
    sigma = params.sigma;
end

if nargin == 4
    savedDir = fullfile(inputdir, 'SWISC-Result');
end

% altas 3D => 1D
[datlas, ~] = NDN_Read(grayMatterMask);
datlasR = reshape(datlas, [size(datlas,1) * size(datlas,2) * size(datlas,3), 1]);

savepath_mat = [savedDir, '/mat'];
savepath_nii = [savedDir, '/nii'];
savepath_meanNii = [savedDir, '/niiMean'];
savepath_variabilityNii = [savedDir, '/niiVariability'];

if exist(savepath_mat, 'dir') == 0
    mkdir(savepath_mat);
end
if  exist(savepath_nii, 'dir') == 0 
    mkdir(savepath_nii);
end
if  exist(savepath_meanNii, 'dir') == 0 
    mkdir(savepath_meanNii);
end
if  exist(savepath_variabilityNii, 'dir') == 0 
    mkdir(savepath_variabilityNii);
end


%% 1. load all subjects in BOLD(nVoxel, nT, nSub)

% get BOLD
if nargin == 6
    [BOLD, ~, ~] = getTimeCourse(inputdir, prefix, grayMatterMask, app);
else
    [BOLD, ~, ~] = getTimeCourse(inputdir, prefix, grayMatterMask);
end
% get nT nSub nR h
sublist = getSublistByPrefixed(inputdir, prefix);
if ~exist([inputdir filesep sublist(1).name filesep 'func'])
    mkdir([inputdir filesep sublist(1).name filesep 'func'])
end 
cd([inputdir filesep sublist(1).name filesep 'func'])
sub01nii = dir('*.nii');
if size(sub01nii, 1) == 0
    sub01nii = dir('*.nii.gz');
end
if size(sub01nii, 1) == 0
    cd('..')
    sub01nii = dir('*.nii');
    if size(sub01nii, 1) == 0
        sub01nii = dir('*.nii.gz');
    end
end

[~, h] = NDN_Read(sub01nii.name);
[nR, nT ,nSub] = size(BOLD);

if nargin == 6
    app.ax.Title.String = 'Calculating SWISC...';
    ph = patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
    drawnow
end

%% 2. save LOO mean TC in LOO_Mean_BOLD(nVoxel, nT, nSub)
% parfor subNum = 1:numel(sublist)
%     tmp = BOLD;
%     tmp(:, :, subNum) = [];
%     meanTmp=mean(tmp, 3);
%     LOO_Mean_BOLD(:, :, subNum) = meanTmp;
% end
% clear("meanTmp") % for saving storage
% clear("tmp")

%% 3. compute sliding window
disp('Create sliding window time series');

if mod(nT,2) ~= 0
    % if nT is odd
    m = ceil(nT/2);
    x = 0:nT;
else
    % if nT is even
    m = nT/2;
    x = 0:nT-1;
end
w = round(wsize/2);% half of sliding window size
gw = exp(- ((x-m).^2) / (2*sigma*sigma))';
b = zeros(nT,1); b((m-w+1):(m+w)) = 1;
c = conv(gw, b);
c = c/max(c);
c = c(m+1:end-m+1);

c = c(1:nT); %  remember that c is a standard window
A = repmat(c,1,nR);% remember that A is nR standard window
Nwin = nT - wsize; % the length of swisc result
%% 4. Load all subjects' sliding windowed time series

for suba = 1:numel(sublist)
    %% Normalize within region, then divide it by the total stddev.

    % 4.1. get suba data，transpose, standardization
    ats = squeeze(BOLD(:, :, suba));
    % now the shape of ats: nt*nr，each column is the TC of a voxel/ROI
    ats = ats'; 
    % standardization of the TC of a voxel/ROI 
    temp_ats = ats;
    temp_ats = temp_ats - repmat(mean(temp_ats), size(temp_ats, 1), 1); 
    temp_ats = temp_ats / std(temp_ats(:)); 
    ats = temp_ats;

    % 4.2 get the corresponding LOO_Mean_BOLD data of suba, do the same as
    % the above
%     BOLD(:, :, subNum) = [];
%     meanTmp=mean(BOLD, 3);
%     LOO_Mean_BOLD(:, :, subNum) = meanTmp;
%     bts = squeeze(LOO_Mean_BOLD(:,:, suba));

    if suba == 1
        bts = mean(BOLD(:, :, 2:numel(sublist)), 3);
    elseif suba == numel(sublist)
        bts = mean(BOLD(:, :, 1:end - 1), 3);
    else
        bts = mean(BOLD(:, :, [1:suba-1, suba + 1:numel(sublist)]), 3);
    end

    bts = bts';
    temp_bts = bts;
    temp_bts = temp_bts - repmat(mean(temp_bts), size(temp_bts, 1), 1); 
    temp_bts = temp_bts / std(temp_bts(:)); 
    bts = temp_bts;

    % 4.3 Apply cyclic shift to sliding window sequences, so that each time
    % point has its own specific window
    swiscResult = [];
    for t = 1:Nwin 
        % Translate the matrix so that the midpoints of Nwin sliding
        % windows are evenly distributed within this range
        % [1+wsize/2, nT_Subj-wsize/2]
        Ashift = circshift(A, round(-nT/2) + round(wsize/2) + t);
        %The part of the code with If elseif end trims the sliding window
        % that exceeds the boundary and makes corresponding adjustments.
        % The center of the window is aligned to the left,
        % and it overflows to the right.
        if t<floor(Nwin/2) & Ashift(end,1)~=0 
            % the overflowing part needs to be removed, and the
            % corresponding multiple should be compensated.
            Ashift(ceil(Nwin/2):end,:) = 0;
            Ashift = Ashift.*(sum(A(:,1))/sum(Ashift(1:floor(Nwin/2),1)));
        elseif t>floor(Nwin/2) & Ashift(1,1)~=0 % right part
            Ashift(1:floor(Nwin/2),:) = 0;
            Ashift = Ashift.*(sum(A(:,1))/sum(Ashift(ceil(Nwin/2):end,1)));
        end

        % apply gaussian weighted sliding window of the timeseries
        processed_ats=ats.*Ashift;% processed_ats nt*nr
        processed_bts=bts.*Ashift;% processed_bts nt*nr

        % 4.4 the core operation
        % regionCorr_slide for saving as the computation result of suba and corresponding LOO_Mean
        regionCorr_slide = zeros(nR, 1);
        parfor region = 1:nR  
            regionCorr_slide(region, 1) = atanh(corr(processed_ats(:,region),processed_bts(:,region),'rows','complete'));
        end
        
        swiscResult = [swiscResult, regionCorr_slide];
    end
    swiscResult = swiscResult';% (Nwin*nr)
    [path, filename, ext] = fileparts(sublist(suba).name);
    %% 5. saving result
    % 5.1 save as mat file
    save([savepath_mat '/swisc_' filename '.mat'], 'swiscResult', '-v7.3');

    % 5.2 save as nii file
    niiData=zeros([size(swiscResult,1), size(datlas,1) * size(datlas,2) * size(datlas,3)]);
    niiData(:, datlasR == 1) = swiscResult;
    if  exist(savepath_nii)==0
        mkdir(savepath_nii);
    end
    niiname = [savepath_nii '/swisc_' filename '.nii'];

    niiData = niiData';
    niiData = reshape(niiData,[size(datlas,1), size(datlas,2), size(datlas,3), size(swiscResult,1)]);
    NDN_Write(niiData, niiname, h);

    % 5.3 save mean nii file
    meanNiiName = [savepath_meanNii  '/swisc_meanNii_' filename '.nii'];
    NDN_Write(mean(niiData, 4), meanNiiName, h);

    % 5.4 save variability nii file
    variabilityNiiName = [savepath_variabilityNii  '/swisc_variabilityNii_' filename '.nii'];
    NDN_Write(std(niiData, 0, 4), variabilityNiiName, h);

    if nargin == 6
        ph.XData = [0, suba / nSub, suba / nSub, 0];
        jindu = sprintf('%.2f', suba / nSub * 100);
        app.ax.Title.String =[ 'Calculating SWISC ' jindu '%...'];
        drawnow
    end
end


