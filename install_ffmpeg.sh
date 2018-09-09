#!/bin/bash

#https://www.jeffreythompson.org/blog/2014/11/13/installing-ffmpeg-for-raspberry-pi/

INSTALL_DIR=/usr/local
SOURCE_DIR=$HOME
X264_FOLDER=x264
FFMPEG_FOLDER=ffmpeg
CMAKE_INSTALL_PREFIX=$INSTALL_DIR

cd $SOURCE_DIR
if [ ! -d $X264_FOLDER ] ; then
	echo "Cloning "$X264_FOLDER" project ..."
	git clone git://git.videolan.org/$X264_FOLDER
fi

cd $SOURCE_DIR/$X264_FOLDER
echo "Configuring installation ..."
./configure --host=arm-unknown-linux-gnueabi --enable-static --disable-opencl
	  
echo "Run make ..."
make 
sudo make install


cd $SOURCE_DIR
if [ ! -d $FFMPEG_FOLDER ] ; then
	echo "Cloning "$FFMPEG_FOLDER" project ..."
	git clone git://source.ffmpeg.org/$FFMPEG_FOLDER.git
fi

cd $SOURCE_DIR/$FFMPEG_FOLDER
echo "Configuring installation ..."
sudo ./configure --arch=armel --target-os=linux --enable-gpl --enable-libx264 --enable-nonfree
	  
echo "Run make ..."
make 
sudo make install

