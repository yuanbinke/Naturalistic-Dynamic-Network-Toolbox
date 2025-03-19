function NullMdlData = NDN_generateNullMldData(TC, params)
%FORMAT NullMdlData = NDN_generateNullMldData(TC, params)
%
%INPUT:
% TC                - A time series of all subjects for a run, with the
%                     shape (nT * nR * nSub).Where nT represents the number
%                     of time points, nR represents the number of ROIs
%                     (Regions of Interest), and nSub represents the number
%                     of subjects.
% params            - A structure containing relevant parameters of ISSWFC
%   nullMdl         - An Attribute, using an empty model to
%                     generate data, its values can be either 'ar' or 'pr'.
%                     It will call the Phase Randomized or Multivariate ARR
%                     model to generate additional data, and optionally
%                     return the DFC result of the data.
% Output
% 'NullMdlData'     - Matrix with the shape (nT * nR * nSub)

if ~isfield(params, 'nullMdl')
    error("params.nullMdl should not be empty, it must be assgind ")
end
nullMdl = char(params.nullMdl);

if ~isequal(nullMdl, 'pr') && ~isequal(nullMdl, 'ar')
    error("params.nullMdl isn't valid, its values can be either 'ar' or 'pr'. ")
end

nSub = size(TC, 3);
for i = 1:nSub
    data = squeeze(TC(:, :, i));
    if isequal(nullMdl, 'ar')
        NullMdlData(:, :, i) = CBIG_RL2017_get_AR_surrogate(data, 1, 1);
    elseif isequal(nullMdl, 'pr')
        NullMdlData(:, :, i) = CBIG_RL2017_get_PR_surrogate(data, 1);
    end
end
end