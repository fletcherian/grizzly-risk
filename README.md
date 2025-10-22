# The public overestimates and prefers greater tolerance for grizzly bear encounters than defined by the United States management guidelines

## Abstract
Large predators are returning to landscapes where they have been absent for centuries, but human preferences complicate their recovery. Communities often resist predator recovery because of perceived risks, limiting what managers call social carrying capacity, or the level of human tolerance for coexisting with wildlife. Yet practical methods for measuring and integrating social carrying capacity into management decisions remain limited. To address this, we combine geospatial and survey data to model individual tolerance for the frequency and severity of grizzly bear encounters. The resulting estimates predict and map zip code–level tolerance across the region. Findings show that people tend to overestimate management’s tolerance of encounters than current federal guidelines. This approach provides a pragmatic tool to incorporate social carrying capacity into decisions about predator recovery and reintroduction, helping balance ecological goals with public acceptance.

## Table of Contents
1. bears.bib - BibTex file used for citations in the TeX file
2. Bears_survey.pdf - Full survey instrument (identical to the one at the bottom of Bears_Manuscript.pdf) used to generate primary data
3. total_success_gis.csv - Full data file including primary survey data and secondary mapping data
4. mapping.do - STATA code to generate mapping analysis
5. plotting.mlx - MATLAB code to generate mean comparison analysis

## How to Replicate Results
1. Run mapping.do code to generate coefficients used for predictive mapping and upload to ARCGiS to generate the predictive maps
2. Run the plotting.mlx to generate mean comparison results - means and confidence intervals are calculated from the STATA file and manually input into the MATLAB file
