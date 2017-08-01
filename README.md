# Incucyte-analysis-toolbox

This is a toolbox for tracking and analyzing cell motility based on live-cell phase-contrast images acquired on an Essen Bioscience Incucyte Imager. ## Dependencies
MATLAB (required to run scripts)
Imaris (for cell tracking)
[MSD analyzer tool for MATLAB](https://github.com/tinevez/msdanalyzer)**Optional:**
[Ilastik](http://ilastik.org/) (for cell segmentation and spot detection)## Workflow
-Export data from Incucyte as individual tiff files for each image-Run tiff_to_series.m to convert data to tiff stacks-Perform cell segmentation in ilastik (I use 2-stage autocontext, followed by object 
classification to further refine segmentation if necessary)-Export final segmentation as binary image-Run ilastik_spots_segmented.m to detect spots based on segmentation image-Open original tiff stack in Imaris and run ImportSpots.m with corresponding ‘spots’ .mat file to import spots-Verify that spots match the cells… may need to adjust the scale if it does not match-Track spots in Imaris (I use ‘Autoregressive Motion’)-Manually verify tracks and correct if necessary-Export track statistics to csv files (make sure to select statistics of interest in Imaris preferences)-To calculate arrest coefficient, run csv_arrest_coefficient.m-Run csv_position_imaris.m to convert tracks to a format that @msdanalyzer will recognize-Run tmap.m to classify transient periods in tracks as directed, constrained, or random motion.

## Acknowledgements
Many of these scripts were originally written by Alexander Carisey and adapted for this work.## References
-Khorshidi, M. A., Vanherberghen, B., Kowalewski, J. M., Garrod, K. R., Lindstrom, S., Andersson-Svahn, H., . . . Onfelt, B. (2011). Analysis of transient migration behavior of natural killer cells imaged in situ and in vitro. Integr Biol (Camb), 3(7), 770-778. doi:10.1039/c1ib00007a-Sommer, C., Straehle, C., Köthe, U., & Hamprecht, F. A. (2011, March 30 2011-April 2 2011). Ilastik: Interactive learning and segmentation toolkit. Paper presented at the 2011 IEEE International Symposium on Biomedical Imaging: From Nano to Macro.-Tarantino, N., Tinevez, J.-Y., Crowell, E. F., Boisson, B., Henriques, R., Mhlanga, M., . . . Laplantine, E. (2014). TNF and IL-1 exhibit distinct ubiquitin requirements for inducing NEMO–IKK supramolecular structures. The Journal of Cell Biology, 204(2), 231. 