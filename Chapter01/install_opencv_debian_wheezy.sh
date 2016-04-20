#!/bin/bash

WITH_QT=0
if [ $WITH_QT -ne 0 ]; then
  echo "Qt will be used as HighGUI's back-end"
else
  echo "Gtk will be used as HighGUI's back-end"
fi

arch=$(uname -m)
if [ "$arch" == "i686" -o "$arch" == "i386" -o "$arch" == "i486" -o "$arch" == "i586" ]; then
    is_x86=1
    is_x86_64=0
elif [ "$arch" == "x86_64" -o "$arch" == "amd64" ]; then
    is_x86=1
    is_x86_64=1
else
    is_x86=0
    is_x86_64=0
fi

echo "Updating and upgrading"
sudo apt-get -y update
sudo apt-get -y upgrade

echo "Installing build tools"
sudo apt-get -y install build-essential cmake pkg-config

echo "Installing GUI libraries and OpenGL extensions"
if [ $WITH_QT -ne 0 ]; then
  sudo apt-get -y install libqt4-dev
  sudo apt-get -y install libqt4-opengl-dev
else
  sudo apt-get -y install libgtk2.0-dev
  sudo apt-get -y install libgtkglext1 libgtkglext1-dev
fi

echo "Installing Python libraries"
sudo apt-get -y install python-dev python-numpy
sudo apt-get -y install python-scipy

echo "Installing media I/O libraries"
sudo apt-get -y install libpng12-0 libpng12-dev libpng++-dev libpng3
sudo apt-get -y install libpnglite-dev libpngwriter0-dev libpngwriter0c2
sudo apt-get -y install zlib1g zlib1g-dbg zlib1g-dev
sudo apt-get -y install pngtools
sudo apt-get -y install libjasper1 libjasper-dev libjasper-runtime
sudo apt-get -y install libjpeg8 libjpeg8-dbg libjpeg8-dev libjpeg-progs
sudo apt-get -y install libtiff4-dev libtiff4 libtiffxx0c2 libtiff-tools
sudo apt-get -y install openexr libopenexr-dev libopenexr6

echo "Installing video I/O libraries"
sudo apt-get -y install libavcodec53 libavcodec-dev libavformat53 libavformat-dev libavutil51 libavutil-dev
sudo apt-get -y install libswscale2 libswscale-dev
sudo apt-get -y install libgstreamer0.10-0-dbg libgstreamer0.10-0 libgstreamer0.10-dev
sudo apt-get -y install libxine1-ffmpeg libxine-dev libxine1-bin
sudo apt-get -y install libunicap2 libunicap2-dev
sudo apt-get -y install libdc1394-22 libdc1394-22-dev libdc1394-utils

echo "Installing codecs"
sudo apt-get -y install libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev
sudo apt-get -y install ffmpeg x264 libx264-dev libv4l-0 libv4l v4l-utils

echo "Installing multiprocessing libraries"
sudo apt-get -y install libtbb-dev

echo "Preparing to install OpenNI 1.5.4.0 (unstable), SensorKinect 0.93, OpenCV 2.4.10 and dependencies"
mkdir opencv
cd opencv

echo "Installing dependencies of OpenNI"
sudo apt-get -y install libusb-1.0-0-dev freeglut3-dev

if [ $is_x86 -ne 0 ]; then
    echo "Downloading OpenNI"
    if [ $is_x86_64 -eq 0 ]; then
        wget http://www.nummist.com/opencv/OpenNI-Bin-Dev-Linux-x86-v1.5.4.0.zip
        unzip OpenNI-Bin-Dev-Linux-x86-v1.5.4.0.zip
        cd OpenNI-Bin-Dev-Linux-x86-v1.5.4.0
    else
        wget http://www.nummist.com/opencv/OpenNI-Bin-Dev-Linux-x64-v1.5.4.0.zip
        unzip OpenNI-Bin-Dev-Linux-x64-v1.5.4.0.zip
        cd OpenNI-Bin-Dev-Linux-x64-v1.5.4.0
    fi
    echo "Installing OpenNI"
    sudo chmod a+x install.sh
    sudo ./install.sh | tee install.log
    cd ..
fi

if [ $is_x86 -ne 0 ]; then
    echo "Downloading SensorKinect"
    if [ $is_x86_64 -eq 0 ]; then
        wget --no-check-certificate https://github.com/avin2/SensorKinect/blob/unstable/Bin/SensorKinect093-Bin-Linux-x86-v5.1.2.1.tar.bz2?raw=true
        tar -xvf SensorKinect093-Bin-Linux-x86-v5.1.2.1.tar.bz2?raw=true
        cd Sensor-Bin-Linux-x86-v5.1.2.1
    else
        wget --no-check-certificate https://github.com/avin2/SensorKinect/blob/unstable/Bin/SensorKinect093-Bin-Linux-x64-v5.1.2.1.tar.bz2?raw=true
        tar -xvf SensorKinect093-Bin-Linux-x64-v5.1.2.1.tar.bz2?raw=true
        cd Sensor-Bin-Linux-x64-v5.1.2.1
    fi
    echo "Installing SensorKinect"
    sudo chmod a+x install.sh
    sudo ./install.sh | tee install.log
    cd ..
fi

echo "Downloading OpenCV"
wget -O opencv-2.4.10.zip http://downloads.sourceforge.net/project/opencvlibrary/opencv-unix/2.4.10/opencv-2.4.10.zip
echo "Installing OpenCV"
unzip opencv-2.4.10.zip
cd opencv-2.4.10
mkdir build
cd build
if [ ! -f /usr/include/libv4l1-videodev.h ]; then
  sudo ln -s /usr/local/include/libv4l1-videodev.h /usr/include/libv4l1-videodev.h
fi
OPTIONS="-D CMAKE_BUILD_TYPE=RELEASE -D WITH_XINE=ON"
if [ $is_x86 -ne 0 ]; then
  OPTIONS="$OPTIONS -D WITH_OPENGL=ON -D WITH_OPENNI=ON -D WITH_TBB=ON"
fi
if [ $WITH_QT -ne 0 ]; then
  OPTIONS="$OPTIONS -D WITH_QT=ON"
fi
cmake $OPTIONS .. | tee cmake.log
make | tee make.log
sudo make install | tee install.log
echo "OpenCV is installed to /usr/local/lib"
echo "Appending \"/usr/local/lib\" to /etc/ld.so.conf"
echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf
sudo ldconfig
echo "OpenCV is ready to be used"
