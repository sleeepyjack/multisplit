all:
	/usr/local/cuda-8.0/bin/nvcc -O3 -std=c++11 -arch=sm_52 -Xcompiler -fopenmp multisplit.cu -o multisplit

clean:
	rm multisplit
