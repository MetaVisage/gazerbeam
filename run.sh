#!/bin/bash -eu

libs=''
for lib in \
	lib/libopencv_calib3d.so.3.2 \
	lib/libopencv_core.so.3.2 \
	lib/libopencv_features2d.so.3.2 \
	lib/libopencv_highgui.so.3.2
do
	libs="$libs:$PWD$lib"
done

LD_PRELOAD="$libs" GLOG_logtostderr=1 ./bin/iris_tracking_gpu
