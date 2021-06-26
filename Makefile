SLUG ?= google/mediapipe
COMMIT ?= 139237092fedef164a17840aceb4e628244f8173

BUILD = cat Dockerfile | DOCKER_BUILDKIT=1 docker build --build-arg MEDIAPIPE_COMMIT=$(COMMIT)


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

$(LIBS): Dockerfile
	$(BUILD) --target=libs -o=lib/ -
	$(foreach so,$(LIBS),test -f $(so);) # Tests for missing SOs
	touch lib/* # Ensure $@ is yougner than %<

libs: $(LIBS)

GRAPH__face_detection_cpu = mediapipe/graphs/face_detection/face_detection_desktop_live.pbtxt
GRAPH__face_detection_gpu = mediapipe/graphs/face_detection/face_detection_mobile_gpu.pbtxt
GRAPH__face_mesh_cpu = mediapipe/graphs/face_mesh/face_mesh_desktop_live.pbtxt
GRAPH__face_mesh_gpu = mediapipe/graphs/face_mesh/face_mesh_desktop_live_gpu.pbtxt
# GRAPH__hair_segmentation_cpu = NONE
GRAPH__hair_segmentation_gpu = mediapipe/graphs/hair_segmentation/hair_segmentation_mobile_gpu.pbtxt
GRAPH__hand_tracking_cpu = mediapipe/graphs/hand_tracking/hand_tracking_desktop_live.pbtxt
GRAPH__hand_tracking_gpu = mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt
GRAPH__holistic_tracking_cpu = mediapipe/graphs/holistic_tracking/holistic_tracking_cpu.pbtxt
GRAPH__holistic_tracking_gpu = mediapipe/graphs/holistic_tracking/holistic_tracking_gpu.pbtxt
GRAPH__iris_tracking_cpu = mediapipe/graphs/iris_tracking/iris_tracking_cpu.pbtxt
GRAPH__iris_tracking_gpu = mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt # Fails ; Side packet "focal_length_pixel" is required but was not provided.
GRAPH__object_detection_cpu = mediapipe/graphs/object_detection/object_detection_desktop_live.pbtxt
# GRAPH__object_detection_gpu = NONE
GRAPH__object_tracking_cpu = mediapipe/graphs/tracking/object_detection_tracking_desktop_live.pbtxt
# GRAPH__object_tracking_gpu = NONE
GRAPH__pose_tracking_cpu = mediapipe/graphs/pose_tracking/pose_tracking_cpu.pbtxt
GRAPH__pose_tracking_gpu = mediapipe/graphs/pose_tracking/pose_tracking_gpu.pbtxt
GRAPH__selfie_segmentation_cpu = mediapipe/graphs/selfie_segmentation/selfie_segmentation_cpu.pbtxt
GRAPH__selfie_segmentation_gpu = mediapipe/graphs/selfie_segmentation/selfie_segmentation_gpu.pbtxt
# GRAPH__objectron https://google.github.io/mediapipe/solutions/objectron.html#desktop

GRAPHS = $(subst GRAPH__,,$(filter GRAPH__%,$(.VARIABLES)))

help:
	$(foreach g, $(sort $(GRAPHS)), $(info make run.$(g)))

Dockerfile:
	cat Dockerfile.bases >$@
	cat Dockerfile.libs >>$@
	$(foreach ex,$(filter %_cpu,$(GRAPHS)),cat Dockerfile.cpu | sed 's%EXAMPLE%$(subst _cpu,,$(ex))%g' >>$@;)
	$(foreach ex,$(filter %_gpu,$(GRAPHS)),cat Dockerfile.gpu | sed 's%EXAMPLE%$(subst _gpu,,$(ex))%g' >>$@;)

ASSETS  = $(foreach g, $(GRAPHS), $(GRAPH__$(g)))
ASSETS += mediapipe/models/hair_segmentation.tflite
ASSETS += mediapipe/models/ssdlite_object_detection.tflite
ASSETS += mediapipe/models/ssdlite_object_detection_labelmap.txt
ASSETS += mediapipe/modules/face_detection/face_detection_front.tflite
ASSETS += mediapipe/modules/face_detection/face_detection_short_range.tflite
ASSETS += mediapipe/modules/face_landmark/face_landmark.tflite
ASSETS += mediapipe/modules/hand_landmark/hand_landmark.tflite
ASSETS += mediapipe/modules/hand_landmark/handedness.txt
ASSETS += mediapipe/modules/holistic_landmark/hand_recrop.tflite
ASSETS += mediapipe/modules/iris_landmark/iris_landmark.tflite
ASSETS += mediapipe/modules/palm_detection/palm_detection.tflite
ASSETS += mediapipe/modules/pose_detection/pose_detection.tflite
ASSETS += mediapipe/modules/pose_landmark/pose_landmark_full_body.tflite
ASSETS += mediapipe/modules/selfie_segmentation/selfie_segmentation.tflite

.PRECIOUS: $(ASSETS)
mediapipe/%.txt mediapipe/%.tflite mediapipe/%.pbtxt:
	mkdir -p $(dir $@)
	curl -f#SLo $@ https://raw.githubusercontent.com/$(SLUG)/$(COMMIT)/$@ || rm $@

.PRECIOUS: bin/%
bin/%: Dockerfile
	$(BUILD) --target=$* -o=bin/ -
	test -x $@

run.%: $(ASSETS) $(LIBS) bin/%
	@LD_PRELOAD="$(PWD)/$(subst $(eval) ,:$(PWD)/,$(LIBS))" \
	GLOG_logtostderr=1 \
	  ./bin/$* \
	    --calculator_graph_config_file=$(GRAPH__$*)

clean:
	$(if $(wildcard Dockerfile), $(RM) Dockerfile)
	$(if $(wildcard bin/*), $(RM) bin/*)
	$(if $(wildcard lib/*), $(RM) lib/*)
	docker system prune -a
