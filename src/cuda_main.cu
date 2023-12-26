#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "../include/stb_image.h"
#include "../include/stb_image_write.h"
#define CHANNEL_NUM 1

#include <cuda.h>
#include <cuda_runtime.h>

typedef struct
{
  unsigned char red, green, blue;
} Pixel;

__global__ void bilinear_downscaling_kernel(uint8_t *image, Pixel *pixels, int bpp,
                                            int width, int height, int new_width,
                                            int new_height, float scale_x,
                                            float scale_y)
{
  int x = blockIdx.x * blockDim.x + threadIdx.x;
  int y = blockIdx.y * blockDim.y + threadIdx.y;

  if (x < new_width && y < new_height)
  {
    Pixel pixel = {255, 255, 255};

    float src_x = x * scale_x;
    float src_y = y * scale_y;

    int x1 = (int)floorf(src_x);
    int y1 = (int)floorf(src_y);
    int x2 = x1 + 1;
    int y2 = y1 + 1;

    float w1 = (x2 - src_x) * (y2 - src_y);
    float w2 = (src_x - x1) * (y2 - src_y);
    float w3 = (x2 - src_x) * (src_y - y1);
    float w4 = (src_x - x1) * (src_y - y1);

    int index1 = (y1 * width + x1) * bpp;
    int index2 = (y1 * width + x2) * bpp;
    int index3 = (y2 * width + x1) * bpp;
    int index4 = (y2 * width + x2) * bpp;

    Pixel pixel1 = {image[index1], image[index1 + 1], image[index1 + 2]};
    Pixel pixel2 = {image[index2], image[index2 + 1], image[index2 + 2]};
    Pixel pixel3 = {image[index3], image[index3 + 1], image[index3 + 2]};
    Pixel pixel4 = {image[index4], image[index4 + 1], image[index4 + 2]};

    pixel.red = (unsigned char)(w1 * pixel1.red + w2 * pixel2.red +
                                w3 * pixel3.red + w4 * pixel4.red);
    pixel.green = (unsigned char)(w1 * pixel1.green + w2 * pixel2.green +
                                  w3 * pixel3.green + w4 * pixel4.green);
    pixel.blue = (unsigned char)(w1 * pixel1.blue + w2 * pixel2.blue +
                                 w3 * pixel3.blue + w4 * pixel4.blue);

    pixels[y * new_width + x] = pixel;
  }
}

void bilinear_downscaling(uint8_t *image, Pixel *pixels, int bpp, int width,
                          int height, int new_width, int new_height,
                          float scale_x, float scale_y)
{

  uint8_t *d_image;
  Pixel *d_pixels;

  cudaMalloc((void **)&d_image, width * height * bpp);
  cudaMalloc((void **)&d_pixels, new_width * new_height * sizeof(Pixel));

  cudaMemcpy(d_image, image, width * height * bpp, cudaMemcpyHostToDevice);

  dim3 blockSize(16, 16);
  dim3 gridSize((new_width + blockSize.x - 1) / blockSize.x,
                (new_height + blockSize.y - 1) / blockSize.y);

  bilinear_downscaling_kernel<<<gridSize, blockSize>>>(d_image, d_pixels, bpp,
                                                       width, height,
                                                       new_width, new_height,
                                                       scale_x, scale_y);

  cudaMemcpy(pixels, d_pixels, new_width * new_height * sizeof(Pixel),
             cudaMemcpyDeviceToHost);

  cudaFree(d_image);
  cudaFree(d_pixels);
}

int main(int argc, char *argv[])
{
  int width, height, bpp, new_width, new_height;
  float scale_x, scale_y;
  clock_t start, end;

  uint8_t *image = stbi_load(argv[1], &width, &height, &bpp, 0);

  new_width = width / 2;
  new_height = height / 2;

  scale_x = width / (float)new_width;
  scale_y = height / (float)new_height;

  printf("New width: %d, New height: %d\n", new_width, new_height);
  printf("Scale factor for x: %d, Scale factor for y: %d\n", (int)scale_x, (int)scale_y);

  Pixel *pixels = (Pixel *)malloc(new_width * new_height * sizeof(Pixel));

  start = clock();
  bilinear_downscaling(image, pixels, bpp, width, height, new_width, new_height,
                       scale_x, scale_y);
  stbi_write_jpg(argv[2], new_width, new_height, 3, pixels, 100);
  end = clock();

  double duration = ((double)end - start)/CLOCKS_PER_SEC;

  printf("Elapsed time : %lf for CUDA GPU\n", duration);

  stbi_image_free(image);
  free(pixels);
  return 0;
}
