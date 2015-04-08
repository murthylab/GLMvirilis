function B = getNx1DLaplacianPyramidBasis(width, nBas, levels, step, FWHM)
% modified from Barthelme's sparse glm toolbox
% returns a concatenation of nBas 1D bases of length width
% ORIGINAL HELP:
%function [B] = get1DLaplacianPyramidBasis(width, nBas, height, levels, step,
%FWHM)
%
%Get a 1d Laplacian pyramid basis matrix of given number of levels for
%vectors of given length. step indicates the spacing of levels (1
%= regular Laplacian pyramid, 0.5 = Laplacian pyramid with
%half-levels). FWHM is full width at half-max for the Gaussians at
%level 1 (the finest level).

% create a base for each covariate
Bsingle = get1DLaplacianPyramidBasis(width, levels, step, FWHM);
% assemble the bases into one huge base
[w, h] = size(Bsingle);
B = zeros(nBas*w, nBas*h);
for i = 1:nBas
   B((i-1)*w+(1:w), (i-1)*h+(1:h)) = Bsingle; 
end

