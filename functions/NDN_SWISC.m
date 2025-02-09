function NDN_SWISC(inputdir, prefix, grayMatterMask, params, savedDir, app)
%FORMAT NDN_SWISC(inputdir, prefix, grayMatterMask, params, savedDir, app)
% INPUT:
% inputdir          - a directory which contains all the subject data. Each
%                       subject 4D nii file is put in a subdirectory like
%                       sub001/data_sub001.nii
%
% prefix            - a String whose contents are decided by the target 
%                     subdirectorys or files in inputdir
%
% grayMatterMask    - the address of the grayMatter file
% params            - A structure containing relevant parameters of ISSWFC
%   wsize        - The size of the sliding-window
%                     
%   sigma        - Parameters affecting the shape of the sliding window. 
%                  Default value is 3. 
% savedDir          - Path for saved, optional argument, default content is
%                     [inputdir filesep 'SWISC-Result']. The results of 
%                     SWISC for gray matter voxels will be saved in the
%                     'mat' subfolder as MAT files.Additionally, the result
%                     matrices will be converted into 4D format and stored
%                     as .nii files in the 'nii' subfolder. Finally, the 4D   
%                     SWISC results for each subject will be averaged over
%                     the time dimension and stored in the 'niiMean' folder
% app               - a optional argument, is a uiobject


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

% get nT nSub nR
sublist = getSublistByPrefixed(inputdir, prefix);
cd([inputdir filesep sublist(1).name])
sub01nii = dir('*.nii');
sub_h = spm_vol(sub01nii.name);

nT = size(sub_h, 1);
nSub = size(sublist, 1);
nR = sum(datlasR);

savepath_mat = [savedDir, '/mat/win_', num2str(wsize) '_sigma_' num2str(sigma)];
savepath_nii = [savedDir, '/nii/win_', num2str(wsize) '_sigma_' num2str(sigma)];
savepath_meanNii = [savedDir, '/niiMean/win_', num2str(wsize) '_sigma_' num2str(sigma)];


if exist(savepath_mat, 'dir') == 0
    mkdir(savepath_mat);
end
if  exist(savepath_nii, 'dir') == 0 
    mkdir(savepath_nii);
end
if  exist(savepath_meanNii, 'dir') == 0 
    mkdir(savepath_meanNii);
end
%% 1. load all subjects in BOLD(nSub*volume*tr)

if nargin == 6
    app.ax.Visible = 'on';
    app.ax.Title.String = 'Loading Subjects...';
    ph = patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.9375, 0.9375, 0.3375]);
    drawnow
end

for subNum = 1:numel(sublist)
    fprintf('loading subject %d ... \n',subNum);
    cd([inputdir filesep sublist(subNum).name])
    dfile=dir('*.nii');
    [d, h] = NDN_Read([inputdir filesep sublist(subNum).name filesep dfile(1).name]);
    a_image = reshape(d,[size(d,1)*size(d,2)*size(d,3),size(d,4)]);
    BOLD(subNum,:,:) = a_image(find(datlasR),:);

    if nargin == 6
        ph.XData = [0, subNum / nSub, subNum / nSub, 0];
        jindu = sprintf('%.2f',subNum / nSub * 100);
        app.ax.Title.String =[ 'loading subject nii file ' jindu '%...'];
        drawnow
    end
end

if nargin == 6
    app.ax.Title.String = 'Calculating SWISC...';
    ph = patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
    drawnow
end

%% 2. save LOO mean TC in LOO_Mean_BOLD(nSub*volume*nT)
parfor subNum = 1:numel(sublist)
    tmp = BOLD;
    tmp(subNum, :, :)=[];
    meanTmp=mean(tmp,1);
    LOO_Mean_BOLD(subNum, :, :)=meanTmp;
end
clear("meanTmp") % for saving storage

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
    ats = squeeze(BOLD(suba,:,:));
    % now the shape of ats: nt*nr，each column is the TC of a voxel/ROI
    ats = ats'; 
    % standardization of the TC of a voxel/ROI 
    temp_ats = ats;
    temp_ats = temp_ats - repmat(mean(temp_ats), size(temp_ats, 1), 1); 
    temp_ats = temp_ats / std(temp_ats(:)); 
    ats = temp_ats;

    % 4.2 get the corresponding LOO_Mean_BOLD data of suba, do the same as
    % the above
    bts = squeeze(LOO_Mean_BOLD(suba,:,:));
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
    ssuba=sprintf('%02s',num2str(suba));
    %% 5. saving result
    % 5.1 save as mat file
    save([savepath_mat,'/swisc_' filename '.mat'], 'swiscResult', '-v7.3');

    % 5.2 save as nii file
    niiData=zeros([size(swiscResult,1), size(datlas,1) * size(datlas,2) * size(datlas,3)]);
    niiData(:, datlasR == 1) = swiscResult;
    if  exist(savepath_nii)==0
        mkdir(savepath_nii);
    end
    niiname = [savepath_nii filesep  '/swisc_' filename '.nii'];

    niiData = niiData';
    niiData = reshape(niiData,[size(datlas,1), size(datlas,2), size(datlas,3), size(swiscResult,1)]);
    NDN_Write(niiData, niiname, h);

    % 5.3 save mean nii file
    meanNiiName = [savepath_meanNii filesep  '/swisc_meanNii_' filename '.nii'];
    NDN_Write(mean(niiData, 4), meanNiiName, h);



    if nargin == 6
        ph.XData = [0, suba / nSub, suba / nSub, 0];
        jindu = sprintf('%.2f', suba / nSub * 100);
        app.ax.Title.String =[ 'Calculating SWISC ' jindu '%...'];
        drawnow
    end
end


