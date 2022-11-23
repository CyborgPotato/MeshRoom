podman run \
	-it --runtime=nvidia \
	-v "/tmp/.X11-unix:/tmp/.X11-unix" \
	-e "DISPLAY=$DISPLAY" -h "$HOSTNAME" \
	-v "$HOME/.Xauthority:/root/.Xauthority" \
	alicevision/meshroom:2021.1.0-av2.4.0-centos7-cuda10.2 bash
