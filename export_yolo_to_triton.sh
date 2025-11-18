yolo export model=yolo11n.pt format=onnx opset=12 dynamic=True simplify=True imgsz=640 project=./weights name=export
docker run --rm -it --gpus all \
  -v ./weights:/opt/weights \
  nvcr.io/nvidia/tensorrt:25.03-py3 \
  /usr/src/tensorrt/bin/trtexec \
    --onnx=/opt/weights/yolo11n.onnx \
    --saveEngine=/opt/weights/yolo11n_fp32.engine \
    --minShapes=images:1x3x640x640 \
    --optShapes=images:8x3x640x640 \
    --maxShapes=images:16x3x640x640 \
