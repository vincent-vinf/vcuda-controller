IMAGE_NAME := registry.cn-hangzhou.aliyuncs.com/adpc/vcuda:1.1.0

image:
	IMAGE_FILE=$(IMAGE_NAME) ./build-img.sh

push: image
	docker push $(IMAGE_NAME)

dev-image:
	docker build -t clion/remote-cpp-env:0.5 -f dev.dockerfile .