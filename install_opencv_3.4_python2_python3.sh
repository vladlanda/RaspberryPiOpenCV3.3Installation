#!/bin/bash

OPENCV_VERSION=3.3.0
INSTALL_DIR=/usr/local
# Download the opencv_extras repository
# If you are installing the opencv testdata, ie
#  OPENCV_TEST_DATA_PATH=../opencv_extra/testdata
# Make sure that you set this to YES
# Value should be YES or NO
DOWNLOAD_OPENCV_EXTRAS=NO
DOWNLOAD_OPENCV_CONTRIBUTES=YES
# Source code directory
OPENCV_SOURCE_DIR=$HOME
WHEREAMI=$PWD

CLEANUP=true

CMAKE_INSTALL_PREFIX=$INSTALL_DIR

# Print out the current configuration
echo "Build configuration: "
echo " OpenCV binaries will be installed in: $CMAKE_INSTALL_PREFIX"
echo " OpenCV Source will be installed in: $OPENCV_SOURCE_DIR"

if [ $DOWNLOAD_OPENCV_EXTRAS == "YES" ]
then
 echo "Also installing opencv_extras"
else
 echo "No opencv_extras"
fi


if [ $CLEANUP ] ; then
 echo "Clean up space(wolfram-engine,libreoffice)"
 sudo apt-get purge wolfram-engine
 sudo apt-get purge libreoffice*
 sudo apt-get clean
 sudo apt-get autoremove
fi

# update upgrade
echo "Updating & Upgrading"
sudo apt-get update && sudo apt-get upgrade

# Download dependencies for the desired configuration
echo "Download dependencies"
cd $WHEREAMI
sudo apt-get install -y build-essential cmake pkg-config
sudo apt-get install -y libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev
sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt-get install -y libxvidcore-dev libx264-dev
sudo apt-get install -y libgtk2.0-dev libgtk-3-dev
sudo apt-get install -y libatlas-base-dev gfortran
sudo apt-get install -y python2.7-dev python3-dev

echo "Download Opencv"
cd $OPENCV_SOURCE_DIR
if [ -f "opencv.zip" ]
then
	echo "opencv.zip exist"
else
	wget -O opencv.zip https://github.com/Itseez/opencv/archive/$OPENCV_VERSION.zip
fi

if [ ! -d "opencv-"$OPENCV_VERSION ] ; then
	unzip opencv.zip
fi

if [ $DOWNLOAD_OPENCV_CONTRIBUTES == "YES" ]
then
 echo "Download opencv_contrib"
 # This is for the test data
 cd $OPENCV_SOURCE_DIR
 if [ -f "opencv_contrib.zip" ]
 then
	echo "opencv_contrib.zip exist"
 else
	wget -O opencv_contrib.zip https://github.com/Itseez/opencv_contrib/archive/$OPENCV_VERSION.zip
	
 fi
 if [ ! -d "opencv_contrib-"$OPENCV_VERSION ] ; then
	unzip opencv_contrib.zip
fi
fi



cd $HOME
if [ -f "get-pip.py" ]
then
	echo "get-pip.py exist"
else
	wget https://bootstrap.pypa.io/get-pip.py
fi

sudo python get-pip.py
sudo python3 get-pip.py

sudo pip install numpy
sudo pip3 install numpy



cd $OPENCV_SOURCE_DIR/opencv-$OPENCV_VERSION
mkdir build
cd build


time cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
	  -D INSTALL_PYTHON_EXAMPLES=ON \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib-$OPENCV_VERSION/modules \
      ../
read -p "BUILD INFORMATION - wait for key"
if [ $? -eq 0 ] ; then
  echo "CMake configuration make successful"
else
  # Try to make again
  echo "CMake issues " >&2
  echo "Please check the configuration being used"
  exit 1
fi

# Consider $ sudo nvpmodel -m 2 or $ sudo nvpmodel -m 0
read -p "Wait for key to PERFORME make -j4"
NUM_CPU=$(nproc)
time make -j$(($NUM_CPU - 1))
if [ $? -eq 0 ] ; then
  echo "OpenCV make successful"
else
  # Try to make again; Sometimes there are issues with the build
  # because of lack of resources or concurrency issues
  echo "Make did not build " >&2
  echo "Retrying ... "
  # Single thread this time
  make
  if [ $? -eq 0 ] ; then
    echo "OpenCV make successful"
  else
    # Try to make again
    echo "Make did not successfully build" >&2
    echo "Please fix issues and retry build"
    exit 1
  fi
fi

echo "Installing ... "
sudo make install
if [ $? -eq 0 ] ; then
   echo "OpenCV installed in: $CMAKE_INSTALL_PREFIX"
else
   echo "There was an issue with the final installation"
   exit 1
fi

sudo ldconfig

# check installation
IMPORT_CHECK="$(python -c "import cv2 ; print cv2.__version__")"
if [[ $IMPORT_CHECK != *$OPENCV_VERSION* ]]; then
  echo "There was an error loading OpenCV in the Python sanity test."
  echo "The loaded version does not match the version built here."
  echo "Please check the installation."
  echo "The first check should be the PYTHONPATH environment variable."
fi

# check installation
IMPORT_CHECK="$(python3 -c "import cv2 ; print cv2.__version__")"
if [[ $IMPORT_CHECK != *$OPENCV_VERSION* ]]; then
  echo "There was an error loading OpenCV in the Python sanity test."
  echo "The loaded version does not match the version built here."
  echo "Please check the installation."
  echo "The first check should be the PYTHONPATH environment variable."
fi
