# MSPA4LargeFilesScript
BASH script used to cut large image inputs into manageable pieces that can be processed with the GUIDOS Toolbox.

## Background
This script was produced as part of a contract with the European Environment Agency ([EEA](http://www.eea.europa.eu/)) and [Terranea](http://www.terranea.de/), [EOXPLORE](http://www.eoxplore.com/), and [Dr. K. Ostapowicz](https://www.researchgate.net/profile/Katarzyna_Ostapowicz2) to produce the Morphological Spatial Pattern Analysis (MSPA) output based on the Copernicus High Resolution Layer (HRL) [Forests](http://land.copernicus.eu/pan-european/high-resolution-layers/forests) product. The MSPA is computed using the [GuidosToolbox](http://forest.jrc.ec.europa.eu/download/software/guidos/).

Due to the memory requirements of the GuidosToolbox to process large images, it was necessary to cut the input images into smaller pieces.

## Description
The script is written in BASH and calls the GuidosToolbox command line function mspa_lin64. This initial version is based on a pre-set buffer area that in future iterations can be set by the user via command line options.

## Requirements
In order to run this script, a OS running BASH is required (e.g. Linux, OSX). The script also requires two other programs:
1. The GuidosToolbox command line executable mspa_lin64;
2. The GDAL library.
The GuidosToolbox can be downloaded from here: http://forest.jrc.ec.europa.eu/download/software/guidos/. The documentation on the functionality and where to find the command line function are found in the software help pages.

GDAL - the Geospatial Data Abstraction Library can be found here: http://www.gdal.org/

## Suggestions
Please familiarise yourself with the GuidosToolbox first before trying to run this particular script.
The script at the moment only has a single command line parameter required to start the processing: the filename (including path). Therefore, any change to script parameters need to be made directly in the code.

## File List
GUIDOS-tile.sh - bash script file

## Acknowledgements
We would like to thank Peter Vogt from the JRC for his suggestions when developing this script.
