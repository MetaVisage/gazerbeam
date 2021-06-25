# gazerbeam
Safe, seamless, AI-based Head-Coupled Perspective as a mouse driver. Open. Reproducible

```
# Requires docker >=18.06

make run.face_detection_cpu
make run.face_detection_gpu
make run.face_mesh_cpu
make run.face_mesh_gpu
make run.hair_segmentation_gpu
make run.hand_tracking_cpu
make run.hand_tracking_gpu
make run.holistic_tracking_cpu
make run.holistic_tracking_gpu
make run.iris_tracking_cpu
make run.iris_tracking_gpu
make run.object_detection_cpu
make run.object_tracking_cpu
make run.pose_tracking_cpu
make run.pose_tracking_gpu

# `make help` for moar
# Cf. https://google.github.io/mediapipe/solutions/solutions.html
```

## wip
* multiplatform userland mouse driver?
	* in rust
	* in Go
* https://github.com/bytebeamio/rumqtt
* metavisage security of IPC => use cloud-based password?
* license you can read the code but pay me for commercial. Also: buy the app => you're not the product *signaling*
