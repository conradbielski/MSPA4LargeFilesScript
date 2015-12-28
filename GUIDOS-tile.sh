#!/bin/bash

# Copyright EOXPLORE UG - July 2015 - Conrad BIELSKI

# This script is used to cut a large input image into pieces
# that can be processed with the GUIDOS Toolbox.

# need the input image
GTBinput=$1

# create the MSPA output directory
mkdir MSPA-output

# get the details about the image
SizeIs=$( gdalinfo -listmdd ${GTBinput} | grep 'Size is' )
sizeY=$( echo ${SizeIs} | awk '{ print $4}' )
sizeX=$( echo ${SizeIs} | cut -d',' -f1 | awk '{print $3}' )
echo "DIMS: ${sizeX}, ${sizeY}"

# the suggestion is 10K X 10K file sizes

# check how many tiles need to be produced and ask whether to continue

# start processing
# The algorithm goes X then Y - in other words, process a full line before doing the next one.
# The reason for this is that the overlap in Y will not be taken into account until after 
# all X overlaps are taken care of.
# 

# Explain code later
#currentTileX
#nextTileX
#-srcwin xoff yoff xsize ysize

# LINES of a tiled image will be stored in a directory
for (( tY=0; tY<${sizeY}; ))
#for (( tY=154000; tY<${sizeY}; )) # Use when having to start on specific line
do
  echo "Running Y -> ${tY} =========================="
  yoff=${tY}
  ysize=10000

  if [ ${yoff} -ne 0 ]; then # check overlap
    yoff=$((yoff - 2000))
  fi
  if [ $((yoff + ysize)) -gt ${sizeY} ]; then # end of column
    ysize=$((sizeY - yoff))
  fi

# keep each line process in a new directory
lineDir=GTBtile_${yoff}
echo "Creating output directory ${lineDir}"
if [ -d ${lineDir} ]; then # if output directory exists, remove
  rm -rf ${lineDir}
fi
mkdir ${lineDir}

####################
  for (( tX=0; tX<${sizeX}; ))
  do
    echo "Running X -> ${tX} --------------------------"
    xoff=${tX}
    xsize=10000

 # prepare the tile parameters
    if [ ${xoff} -ne 0 ]; then # check overlap
      xoff=$((xoff - 2000))
    fi
    if [ $((xoff + xsize)) -gt ${sizeX} ]; then # end of line
      xsize=$((sizeX - xoff))
    fi
    echo "srcwin: ${xoff} ${yoff} ${xsize} ${ysize}"
 # extract the tile
    currentTile="tileX${xoff}Y${yoff}.tif"
    gdal_translate -co COMPRESS=LZW -srcwin ${xoff} ${yoff} ${xsize} ${ysize} ${GTBinput} ${lineDir}/${currentTile}

 # check stats for processing
    currentTileStats=$( echo ${currentTile} | sed 's/.tif/.txt/g' )
    gdalinfo -stats -hist ${lineDir}/${currentTile} > ${lineDir}/${currentTileStats}

 # run GTB?
    runTest=$( grep STATISTICS_MAXIMUM ${lineDir}/${currentTileStats} | cut -d'=' -f2 )
    echo ${runTest}
    if [ ${runTest} -gt 1 ]; then # i.e. foreground pixel must be present
     echo "RUN GTB!"
     currentTileMSPA=$( echo ${currentTile} | sed 's/.tif/-MSPA.tif/g' )
     /home/ec2-user/GUIDOS/GuidosToolbox/idl84/save_add/MSPAstandalone/mspa_lin64 -v -i ${lineDir}/${currentTile} -o ${currentTileMSPA} -eew 5.0 -odir ${lineDir}/
     # due to loss of coordinate information run libtiff
     /home/ec2-user/DEV/tools/libgeotiff-1.4.0/bin/listgeo ${lineDir}/${currentTile} > ${lineDir}/${currentTile}.prj
     currentTileMSPAgeo=$( echo ${currentTile} | sed 's/.tif/-MSPA-geo.tif/g' )
     /home/ec2-user/DEV/tools/libgeotiff-1.4.0/bin/geotifcp -g ${lineDir}/${currentTile}.prj ${lineDir}/${currentTileMSPA} ${lineDir}/${currentTileMSPAgeo}
     # remove the MSPA result?

     # extract the wanted region - extracting from tile, so use new local coordinates
     # need to get new tile dimensions
     tileSizeIs=$( gdalinfo -listmdd ${lineDir}/${currentTileMSPAgeo} | grep 'Size is' )
     tileSizeY=$( echo ${tileSizeIs} | awk '{ print $4}' )
     tileSizeX=$( echo ${tileSizeIs} | cut -d',' -f1 | awk '{print $3}' )
     echo "tile DIMS: ${tileSizeX}, ${tileSizeY}"
     tileXoff=${xoff}; tileYoff=${yoff}
     tileXsize=8000; tileYsize=8000
     if [ ${tileXoff} -ne 0 ]; then # test X
       tileXoff=1000
     else
       tileXsize=9000
     fi
     if [ ${tileYoff} -ne 0 ]; then # test Y
       tileYoff=1000
     else
       tileYsize=9000
     fi
     if [ $((tileXoff + tileXsize)) -gt ${tileSizeX} ]; then # end of line
      tileXsize=$((tileSizeX - tileXoff))
     fi
     if [ $((tileYoff + tileYsize)) -gt ${tileSizeY} ]; then # end of column
      tileYsize=$((tileSizeY - tileYoff))
     fi
     echo "tile srcwin: ${tileXoff} ${tileYoff} ${tileXsize} ${tileYsize}"
     # extract the buffered tile
     bufferedTileMSPA=$( echo ${currentTile} | sed 's/.tif/-buff.tif/g' )
     gdal_translate -co COMPRESS=LZW -srcwin ${tileXoff} ${tileYoff} ${tileXsize} ${tileYsize} ${lineDir}/${currentTileMSPAgeo} ${lineDir}/${bufferedTileMSPA}
     
    ####################### 
    else
     echo "No values in image" # file does not need to be processed
    fi

    tX=$((xoff + xsize)) # update the X loop counter

  done # X line loop

  tY=$((yoff + ysize)) # update the Y loop counter

  # go into the MSPA-output directory and produce the current line
  cd MSPA-output
  gdalbuildvrt lineX${xoff}Y${yoff}.vrt ../${lineDir}/*-buff.tif
  cd ..

done # Y column loop

# Stich all lines together and produce final mosaic
cd MSPA-output
# output file name?
gdalbuildvrt mspa.vrt line*.vrt

gdal_translate -co COMPRESS=LZW mspa.vrt mspa-result.tif

