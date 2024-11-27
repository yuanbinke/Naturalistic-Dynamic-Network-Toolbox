function ISCAP(inputDir, prefix, grayMatterMask, savedDir, params, app)
%FORMAT ISCAP(inputDir,prefix, grayMatterMask, savedDir, params, app)
%ISCAP evaluate intersubject coactivation pattern analysis (ISCAP) among
% one group of subjects.This is an improved approach based on co-activation
% pattern analysis (CAP), which can accomplish a higher spatiotemporal
% consistency.
%INPUT:
% inputDir          - a directory which  contains all the subject data，every
%                     subject 4D—nii file and its head motion file(.txt) is
%                     put in a subdirectory like inputdir/sub001/data_sub001.nii + xxx.txt
%                     if you don't have a head motion file, only 4D—nii
%                     file in the subdirectory is acceptable.
% prefix            - a String whose contents are decided by the target
%                     subdirectorys in inputdir
% grayMatterMask    - the address of the gray matter mask file
% savedDir          - Path for saved
%
% params            - a structure containing relevant parameters of ISCAP
%   The elements in the structure are:
%   params.runName  - A string representing the current group, which can be
%                   used as part of the generated result's filename.
%   params.TR       - An optinal field, represent the time repitition of
%                   the current group. When params.TR is not exist, ISCAP
%                   will automatically read the first subject's nii file
%                   header to acquire the TR.
%   params.Tmot     - A head movement threshold, double type field,is used 
%                   to exclude frames that do not meet this threshold 
%   params.K        - K is used to specify the number of clusters should
%                   eventually form in the current run.
%   params.Pp
%   params.Pn
%   params.method  - a string for choose which method to perform,
%                   specified as one of the following strings:
%                       - 'ISCAP': intersubject co-activation pattern.
%                       - 'CAP': co-activation pattern.
%
% app               - a optional argument, is a uiobject
%

% References:
% Co-activation pattern analysis (CAP) toolbox implemented and written
% by Thomas A. W. Bolton, from the Medical Image Processing Laboratory
% (MIP:Lab), EPFL, Switzerland



%% parameters  Editing of all the CAP generation parameters
% params.Pp = str2double(params.Pp);
% params.Pn = str2double(params.Pn);
% params.Tmot = str2double(params.Tmot);
% params.K = str2double(params.K);

if params.K > 12 || params.K < 0
    error("The range of k should be within (0, 12].")
end
if params.Pp > 100 || params.Pp < 0
    error("The range of params.Pp should be within (0, 100].")
end
if params.Pn > 100 || params.Pn < 0
    error("The range of params.Pn should be within (0, 100].")
end
if params.Tmot < 0
    error("The minimum value of params.Tmot should be greater than 0.")
end



if isequal(params.method, 'ISCAP')
    dataType = 'task';

    if nargin == 6
        generateTaskResting(inputDir, prefix, dataType, grayMatterMask, app)
    else
        generateTaskResting(inputDir, prefix, dataType, grayMatterMask)
    end

    workingDir = [inputDir filesep 'LOO_ResReg\Task'];
else
    workingDir = inputDir;
end
cd(workingDir)
subList = getSublistByPrefixed(workingDir, prefix);

if ~exist(savedDir, 'dir')
    mkdir(savedDir)
end

runName = params.runName;

if isfield(params, "TR")
    params.TR = str2double(params.TR);
    TR = params.TR;
else
    cd([workingDir filesep subList(1).name])
    firstNIIFile = dir('*nii');
    [~, h] = yjj_Read([workingDir filesep subList(1).name filesep firstNIIFile(1).name], 1);
    if size(h.PixelDimensions, 2) == 4
        TR = h.PixelDimensions(1, 4);
    else
        error("You must input an accurate params." + ...
            "TR because the header of the 4D nii file does not provide this information.")
    end

end

if TR < 0
    error("Invalid input! you should enter a number greater than 0 for params.TR")
end
    
   
Tmot = params.Tmot; % 0.5
K = params.K;
Pp = params.Pp;
Pn = params.Pn;
% Resets the CAP parameters (CAPs, standard deviation within CAPs and
% indices of the CAPs to which all retained frames were assigned)
CAP = [];
STDCAP = [];

n_rep = 20;
%% loading hrd
cd([workingDir filesep subList(1).name])
firstNIIFile = dir('*.nii');

allHead = spm_vol([workingDir filesep subList(1).name filesep firstNIIFile(1).name]);
brain_info = {};
brain_info{1}=allHead(1);


% loading mask
[pathstr, name, ext]=fileparts(which('CAP_TB.m'));
a = spm_vol(fullfile(pathstr,'DefaultData','Default_mask.nii'));
b = spm_read_vols(a);
b(b < 0.9) = 0;
b(b >= 0.9) = 1;
maskf = CAP_V2V(b,a.dim,a.mat,brain_info{1}.dim,brain_info{1}.mat);
mask = {};
mask{1} = logical(maskf(:));

%% loading subject and FD
TC = {};
FD = {};
if nargin == 6
    app.ax.Title.String = 'Loading subjects...';
    patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);

    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end

for i = 1:size(subList,1)

    disp(['Currently loading subject ',num2str(i),'...']);
    cd([workingDir filesep subList(i).name])
    NIIFile = dir('*.nii');

    tmp_data = [];
    [d, ~]=y_Read(NIIFile(1).name);
    [s1,s2,s3,s4]=size(d);
    temp=reshape(d,[s1*s2*s3,s4]);
    tmp_data=temp(mask{1},:)';

    % Z-scoring is performed within the toolbox
    % tmp_data = detrend(tmp_data);
    % tmp_data = zscore(tmp_data);
    tmp_data = (tmp_data-repmat(mean(tmp_data),size(tmp_data,1),1)) ./ repmat(std(tmp_data),size(tmp_data,1),1);
    tmp_data(isnan(tmp_data)) = 0;

    % The ready-to-analyse data is put in TC

    TC{1}{i} = tmp_data;
    TXTFile = dir('*.txt');

    if size(TXTFile, 1) == 0
        FD{1}(:,i) = zeros(size(tmp_data, 1),1);
        disp(['Could not process motion text file of ' subList(i).name '; assuming zero movement...']);
    else
        FD{1}(:,i) = CAP_ComputeFD(TXTFile(1).name);
    end


    if nargin == 6
        subNum = i;
        Nsub = size(subList,1);
        ph.XData = [0, subNum / Nsub, subNum / Nsub, 0];
        jindu = sprintf('%.2f',subNum / Nsub * 100);
        app.ax.Title.String =[ 'loading subject nii file ' jindu '%...'];
        drawnow
    end
end

SubjSize = {};
SubjSize.VOX = size(TC{1}{1},2);
SubjSize.TP = size(TC{1}{1},1);
%         % Sets the text label about data dimensions
%         set(Dimensionality_Text, 'String', [num2str(SubjSize.TP),...
%             ' frames x ',num2str(SubjSize.VOX),' voxels (',...
%             strjoin(arrayfun(@(x) num2str(x),cell2mat(n_subjects),...
%             'UniformOutput',false),'+'),')']);
%     Underlay_info = {};
brain = importdata('brain.mat');
Underlay = load_nii('Underlay.nii');

Underlay_dim=[];Underlay_mat=[];Underlay_info=[];

Underlay_mat = [Underlay.hdr.hist.srow_x; Underlay.hdr.hist.srow_y; Underlay.hdr.hist.srow_z; 0 0 0 1];
Underlay_dim = Underlay.hdr.dime.dim;
Underlay_dim = Underlay_dim(2:4);
Underlay_info.dim = Underlay_dim;
Underlay_info.mat = Underlay_mat;
brain = CAP_V2V(brain,Underlay_info.dim,...
    Underlay_info.mat,brain_info{1}.dim,brain_info{1}.mat);

%% Seed-free analysis
% Performs the analysis to extract frames of activity
% Xonp and Xonn contain the frames (deactivation frames have been
% switched in sign, so that deactivation is positive)
% Xonp 保存剩下的帧，大小为 1 * nsub的cell数组，每个cell里面是剩下的TR * nvoxel
% p�?3*nsub的double，第�?第二行是相同的，提剔除的时间帧占�?
% 第三�? = 1-第一�?
% Indices 1*1的结构体�?3个字段�?? 其中srubbed是nt * nsub  的logic，记录某个人被剔除的
% 的时间点,Indices.scrubbed==Indices.scrubbedandactive
% Indices.kept.active = ~Indices.scrubbed
Xonp = {};
[Xonp{1},p,Indices] = CAP_find_activity_SeedFree(TC{1},...
    FD{1},Tmot);

% Percentage of retained frames across subjects
RetainedPercentage = {};
RetainedPercentage{1} = p(3,:);

% Indices of the frames that have been retained (used later for metrics
% computations)
FrameIndices = {};
FrameIndices{1} = Indices;
%% running cluster

% Indices of the CAP to which frames from the reference population and from
% the other populations are assigned
if nargin == 6
    app.ax.Title.String = ['Computing ' params.method ' , it will will take a long time...'];
    patch(app.ax,[0, 1, 1, 0], [0, 0, 1, 1], [1, 1, 1]);

    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
    drawnow
end

idx = {};
[CAP,Disp,STDCAP,idx{1},...
    CorrDist,sfrac] = Run_Clustering(cell2mat(Xonp{1}),K,mask{1},brain_info{1},...
    Pp,Pn,n_rep,1,'SeedFree');

%% computeMetric
TPM = {};
Counts = {}; Number = {}; Avg_Duration = {}; Duration = {}; TM={};
From_Baseline = {}; To_Baseline = {}; Baseline_resilience = {};Resilience={};
Betweenness = {}; kin = {}; kout = {}; SubjectEntries = {};
[TPM{1},Counts{1},Number{1},Avg_Duration{1},...
    Duration{1},TM{1},From_Baseline{1},To_Baseline{1},...
    Baseline_resilience{1},Resilience{1},...
    Betweenness{1},kin{1},kout{1},SubjectEntries{1}] =...
    Compute_Metrics_simpler(idx{1},FrameIndices{1}.kept.active,...
    FrameIndices{1}.scrubbedandactive,...
    K,TR);

    if nargin == 6
        ph.XData = [0, 1, 1, 0];
        jindu = sprintf('%.2f',0.99 * 100);
        app.ax.Title.String =[ 'Computing ' params.method  jindu '%...'];
        drawnow
    end

%% generate CAPs transition matrix tif
tmp_toplot = [];
tmp_toplot = [tmp_toplot; TPM{1}; 0*ones(5,SubjSize.TP)];
tmp_toplot = tmp_toplot(1:end-5,:);


figure(1)
imagesc(tmp_toplot);
custom_cm = cbrewer('qual','Set1',K);
custom_cm = [0.05,0.05,0.05;1,1,1;custom_cm];
colormap((custom_cm));
set(gca, 'FontName','Arial','FontSize',25,'LineWidth', 1.5);
xlim([0 size(tmp_toplot, 2)])
xlabel(gca,'Time [s]','FontSize',36);
ylabel(gca,'Subjects','FontSize',36);
try 
    clim([-1,K+1]);
catch
    caxis([-1,K+1]);
end
set(gcf,'Position',[100 100 1920*0.6 1080*0.4]);

jianju = floor((size(tmp_toplot, 2) / 4));
xticks([0:jianju:(size(tmp_toplot, 2)  - jianju), floor(size(tmp_toplot, 2))])
xticklabels(floor([0:jianju:(size(tmp_toplot, 2)  - jianju), floor(size(tmp_toplot, 2))].*TR));


if size(tmp_toplot, 1) < 4
    yticks(0:1:size(tmp_toplot, 1));
end

set(gca,'tickdir','in');

filename=[savedDir filesep runName '_stateTransition'];
print(1,'-dtiff','-r300',filename);
close(1)
cd(savedDir)
save([savedDir filesep runName '_StateTransition.mat'], "tmp_toplot");

%%
% Saves NIFTI files storing the CAPs in MNI space
CAPToNIFTI(CAP,...
    mask{1},brain_info{1},...
    savedDir,['CAP_NIFTI_',runName]);

CAPToNIFTI(CAP_Zscore(CAP),...
    mask{1},brain_info{1},...
    savedDir,['CAP_NIFTI_ZScored_',runName]);
%% brainnet viewer
yjj_batch_generate_3dnii_2_tif(savedDir)


end