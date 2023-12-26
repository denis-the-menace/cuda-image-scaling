NVCC = nvcc
NVCCFLAGS = -std=c++11 -arch=sm_61 -ccbin=/opt/cuda/bin
INCLUDES = -Iinclude
TARGET = cuda_bilinear_scaling
SRCS = src/cuda_main.cu
OBJS = $(SRCS:.cu=.o)
DEPS = $(OBJS:.o=.d)

$(TARGET): $(OBJS)
	$(NVCC) $(NVCCFLAGS) $(INCLUDES) -o $@ $^

%.o: %.cu
	$(NVCC) $(NVCCFLAGS) $(INCLUDES) -c -o $@ $<

-include $(DEPS)

clean:
	rm -f $(TARGET) $(OBJS) $(DEPS)
