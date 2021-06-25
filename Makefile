SLUG ?= google/mediapipe
COMMIT ?= ecb5b5f44ab23ea620ef97a479407c699e424aa7

BUILD = cat Dockerfile | DOCKER_BUILDKIT=1 docker build


# cat Dockerfile | DOCKER_BUILDKIT=1 docker build --target=builder-iris_tracking_cpu --tag=builder-iris_tracking_cpu -
# docker run --rm -it builder-iris_tracking_cpu /bin/sh
# ldd /x/iris_tracking_cpu
#	linux-vdso.so.1 (0x00007ffceedb5000)
#	libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f38aade1000)
#	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f38aaa43000)
#	libopencv_calib3d.so.3.2 => /usr/lib/x86_64-linux-gnu/libopencv_calib3d.so.3.2 (0x00007f38aa6f3000)
# ...

LIBS  = lib/libdap.so.25
LIBS += lib/libopencv_calib3d.so.3.2
LIBS += lib/libopencv_core.so.3.2
LIBS += lib/libopencv_features2d.so.3.2
LIBS += lib/libopencv_flann.so.3.2
LIBS += lib/libopencv_highgui.so.3.2
LIBS += lib/libopencv_imgcodecs.so.3.2
LIBS += lib/libopencv_imgproc.so.3.2
LIBS += lib/libopencv_video.so.3.2
LIBS += lib/libopencv_videoio.so.3.2
LIBS += lib/libgdcmMSFF.so.2.8
LIBS += lib/libIlmImf-2_2.so.22
LIBS += lib/libHalf.so.12
LIBS += lib/libgdal.so.20
LIBS += lib/libgdcmDSED.so.2.8
LIBS += lib/libdc1394.so.22
LIBS += lib/libavcodec.so.57
LIBS += lib/libavformat.so.57
LIBS += lib/libavutil.so.55
LIBS += lib/libswscale.so.4
LIBS += lib/libgdcmIOD.so.2.8
LIBS += lib/libgdcmDICT.so.2.8
LIBS += lib/libgdcmjpeg8.so.2.8
LIBS += lib/libgdcmjpeg12.so.2.8
LIBS += lib/libgdcmjpeg16.so.2.8
LIBS += lib/libCharLS.so.1
LIBS += lib/libjson-c.so.3
LIBS += lib/libgdcmCommon.so.2.8
LIBS += lib/libIex-2_2.so.12
LIBS += lib/libIlmThread-2_2.so.12
LIBS += lib/libarmadillo.so.8
LIBS += lib/libproj.so.12
LIBS += lib/libpoppler.so.73
LIBS += lib/libqhull.so.7
LIBS += lib/libnetcdf.so.13
LIBS += lib/libhdf5_serial.so.100
LIBS += lib/libogdi.so.3.2
LIBS += lib/libgeotiff.so.2
LIBS += lib/libmysqlclient.so.20
LIBS += lib/libswresample.so.2
LIBS += lib/libcrystalhd.so.3
LIBS += lib/libx265.so.146
LIBS += lib/libx264.so.152
LIBS += lib/libvpx.so.5

$(LIBS):
	$(BUILD) --target=libs -o=lib/ -
	$(foreach so,$(LIBS),test -f $(so);) # Tests for missing SOs

ASSETS  = mediapipe/modules/hand_landmark/handedness.txt

ASSETS += mediapipe/modules/face_detection/face_detection_front.tflite
ASSETS += mediapipe/modules/face_landmark/face_landmark.tflite
ASSETS += mediapipe/modules/iris_landmark/iris_landmark.tflite
ASSETS += mediapipe/modules/palm_detection/palm_detection.tflite
ASSETS += mediapipe/modules/hand_landmark/hand_landmark.tflite

GRAPH__iris_tracking_cpu = mediapipe/graphs/iris_tracking/iris_tracking_cpu.pbtxt
GRAPH__iris_tracking_gpu = mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt
GRAPH__hand_tracking_cpu = mediapipe/graphs/hand_tracking/hand_tracking_desktop_live.pbtxt
GRAPH__hand_tracking_gpu = mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt

ASSETS += $(GRAPH__iris_tracking_cpu)
ASSETS += $(GRAPH__iris_tracking_gpu)
ASSETS += $(GRAPH__hand_tracking_cpu)
ASSETS += $(GRAPH__hand_tracking_gpu)

.PRECIOUS: $(ASSETS)
mediapipe/%.txt mediapipe/%.tflite mediapipe/%.pbtxt:
	mkdir -p $(dir $@)
	curl -f#SLo $@ https://raw.githubusercontent.com/$(SLUG)/$(COMMIT)/$@ || rm $@

.PRECIOUS: bin/%
bin/%:
	$(BUILD) --target=$* -o=bin/ -
	test -x $@

run.%: $(ASSETS) $(LIBS) bin/%
	GLOG_logtostderr=1 LD_PRELOAD="$(PWD)/$(subst $(eval) ,:$(PWD)/,$(LIBS))" \
	  ./bin/$* \
	    --calculator_graph_config_file=$(GRAPH__$*)
