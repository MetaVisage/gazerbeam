#!/bin/bash -eu

libs=''
for so in \
	libopencv_calib3d.so.3.2 \
	libopencv_core.so.3.2 \
	libopencv_features2d.so.3.2 \
	libopencv_flann.so.3.2 \
	libopencv_highgui.so.3.2 \
	libopencv_imgcodecs.so.3.2 \
	libopencv_imgproc.so.3.2 \
	libopencv_video.so.3.2 \
	libopencv_videoio.so.3.2 \
	libgdcmMSFF.so.2.8 \
	libIlmImf-2_2.so.22 \
	libHalf.so.12 \
	libgdal.so.20 \
	libgdcmDSED.so.2.8 \
	libdc1394.so.22 \
	libavcodec.so.57 \
	libavformat.so.57 \
	libavutil.so.55 \
	libswscale.so.4 \
	libgdcmIOD.so.2.8 \
	libgdcmDICT.so.2.8 \
	libgdcmjpeg8.so.2.8 \
	libgdcmjpeg12.so.2.8 \
	libgdcmjpeg16.so.2.8 \
	libCharLS.so.1 \
	libjson-c.so.3 \
	libgdcmCommon.so.2.8 \
	libIex-2_2.so.12 \
	libIlmThread-2_2.so.12 \
	libarmadillo.so.8 \
	libproj.so.12 \
	libpoppler.so.73 \
	libqhull.so.7 \
	libnetcdf.so.13 \
	libhdf5_serial.so.100 \
	libogdi.so.3.2 \
	libgeotiff.so.2 \
	libmysqlclient.so.20 \
	libswresample.so.2 \
	libcrystalhd.so.3 \
	libx265.so.146 \
	libx264.so.152 \
	libvpx.so.5 \
	end
do
	[[ "$so" = end ]] && continue
	lib=$PWD/lib/$so
	[[ ! -f "$lib" ]] && echo "Missing $so" && exit 2
	libs="$libs:$lib"
done

#[[ ! -f ]]
# https://raw.githubusercontent.com/google/mediapipe/ecb5b5f44ab23ea620ef97a479407c699e424aa7/mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt

LD_PRELOAD="$libs" \
GLOG_logtostderr=1 \
	./bin/iris_tracking_gpu \
		--calculator_graph_config_file=mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt

#full static
# https://github.com/bazelbuild/bazel/issues/8672#issuecomment-505064783
# https://github.com/bazelbuild/bazel/issues/8672#issuecomment-507634776
# https://blog.jessfraz.com/post/top-10-favorite-ldflags/
#  --unresolved-symbols=ignore-all

