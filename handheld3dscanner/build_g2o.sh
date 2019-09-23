#!/bin/bash -e

# https://github.com/introlab/rtabmap/wiki/Installation#raspberrypi

BASEDIR=$(cd $(dirname "$0"); pwd)

pkgname="g2o"
gitname="g2o"
gittag="e7b5b7a1143bcbb6d57faab4bff8b2ab3ccd17a6"

cd ${BASEDIR}

if [ ! -f ${BASEDIR}/${gitname}/build/Makefile ]; then

if [ -d ${BASEDIR}/${gitname} ]; then
	cd ${gitname}
	git reset --hard HEAD
else
	git clone https://github.com/RainerKuemmerle/g2o.git
	cd ${gitname}
fi

git checkout -f ${gittag}

# https://github.com/RainerKuemmerle/g2o/issues/53#issuecomment-455067781
sudo apt-get install -y libsuitesparse-dev
sudo cp ${BASEDIR}/FindCSparse.cmake /usr/share/cmake-*/Modules/

# it is of utmost importance that -march=native is on for the g2o build
# in fact, all dependancies of rtabmap should be built with -march=native

mkdir -p build && cd build
sudo rm -rf ./*
cmake -DBUILD_WITH_MARCH_NATIVE=ON -DG2O_BUILD_APPS=OFF -DG2O_BUILD_EXAMPLES=OFF -DG2O_USE_OPENGL=OFF .. 2>&1 | tee cmake_outputlog.txt
[ ${PIPESTATUS[0]} -ne 0 ] && exit 1
restarted=0

else
cd ${BASEDIR}/${gitname}/build
restarted=1
fi

n=0
until [ $n -ge 10 ]
do
	echo "make attempt on $(date)" | tee -a make_outputlog.txt
	make -j4 2>&1 | tee -a make_outputlog.txt
	if [ ${PIPESTATUS[0]} -eq 0 ]; then
		break
	else
		if [ $restarted -eq 0 ]; then
			echo "removing possibly corrupted object files"
			find . -type f -size 0 -name *.cpp.o
			find . -type f -size 0 -name *.c.o
		fi
	fi
	n=$[$n+1]
done
[ ${PIPESTATUS[0]} -ne 0 ] && exit 1

sudo make install
sudo ldconfig

touch ${BASEDIR}/build_${pkgname}.done