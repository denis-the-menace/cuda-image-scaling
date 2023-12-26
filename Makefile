# Compiler and flags
NVCC = nvcc
NVCCFLAGS = -std=c++11 -arch=sm_61  # Adjust architecture as needed

# Include paths
INCLUDES = -Iinclude

# Target executable
TARGET = my_cuda_app

# Source files
SRCS = src/cuda_main.cu

# Object files
OBJS = $(SRCS:.cu=.o)

# Dependencies
DEPS = $(OBJS:.o=.d)

# Build the executable
$(TARGET): $(OBJS)
	$(NVCC) $(NVCCFLAGS) $(INCLUDES) -o $@ $^

# Compile CUDA source files
%.o: %.cu
	$(NVCC) $(NVCCFLAGS) $(INCLUDES) -c -o $@ $<

# Include dependencies
-include $(DEPS)

# Clean the build
clean:
	rm -f $(TARGET) $(OBJS) $(DEPS)
