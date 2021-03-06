# GLM
Code and data for calculating behavioral filters.

## instructions
1. run `fitFilters.m` to do cross-validated fit of filters (results saved in `res/`). 
2. `plotFilters.m` plots the results. 

`minimalExample.m` contains a minimal example... 

## contents
- `dat/` - data directory, contains annotated male-female (`dat/MFcorr.mat`) and male-male (`dat/MMcorr.mat`) courtship data
- `fig/` - where `plotFilters.m` saves figures to
- `res/` - where `fitFilters.m` saves results to
- `sparseglm/` - code for fitting sparse GLMs from [Mineault et al. (2009)](http://www.journalofvision.org/content/9/10/17.full) downloaded from [Pack lab website](http://packlab.mcgill.ca)
- `src/` - miscellaneous helper functions
