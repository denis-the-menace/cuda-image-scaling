If you happen to get "invalid combination of type specifiers" error, it is most likely because of your gcc version.
Cuda uses gcc 12, if you have gcc 13 installed nvcc might be mixing gcc 12 and gcc 13.
