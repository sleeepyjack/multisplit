#include <iostream>
#include <assert.h>
#include <omp.h>

#include "cuda_helpers.cuh"
#include "hash_functions.cuh"

template<class Index,
         Index K,
         class SplitFunc>
GLOBALQUALIFIER void multisplit(Index * input,
                                Index ** splits,
                                Index * split_counts,
                                Index len,
                                SplitFunc split_func)
{
    for(Index tid = blockIdx.x * blockDim.x + threadIdx.x;
        tid < len;
        tid += gridDim.x * blockDim.x)
    {
        const Index value    = input[tid];
        const Index my_split = split_func(value) % K;

        #pragma unroll K
        for(Index i = 0; i < K; ++i)
        {
            if(i == my_split)
            {
                const Index j = atomicAggInc(&split_counts[i]);
                splits[i][j]  = value;
            }
        }
    }
}

template<class Index,
         Index K,
         class SplitFunc>
GLOBALQUALIFIER void validate(Index ** split,
                              Index * split_count,
                              Index this_split,
                              SplitFunc split_func)
{
    const Index tid = blockIdx.x*blockDim.x+threadIdx.x;
    if(tid >= split_count[this_split]) return;

    const Index value = split[this_split][tid];
    const Index my_split = split_func(value) % K;

    assert(my_split == this_split); //or die!
}

int main()
{
    using index_t = unsigned int; //the input and index type to be used
    using split_t = mueller_hash_uint32_t; //the split function

    //PARAMETERS
    constexpr index_t len = (1UL<<28); //num input elements
    constexpr index_t k   = 4; //num splits

    std::cout << "PARAMS: input_length: " << len
              << "\t"   << "num_splits: " << k
                                          << std::endl;

    TIMERSTART(init)
    //init K split arrays
    index_t ** splits_h = new index_t*[k];
    for(index_t i = 0; i < k; ++i)
    {
        cudaMalloc(&splits_h[i], sizeof(index_t)*len); CUERR
    }
    index_t ** splits_d; cudaMalloc(&splits_d, sizeof(index_t*)*k); CUERR
    cudaMemcpy(splits_d, splits_h, sizeof(index_t*)*k, H2D); CUERR

    //init split counters
    index_t * split_counts; cudaMalloc(&split_counts, sizeof(index_t)*k); CUERR
    memset_kernel<<<SDIV(len, 1024), 1024>>>(split_counts, k, index_t(0)); CUERR

    //init input array
    index_t * input_h = new index_t[len];
    #pragma omp parallel for
    for(index_t i = 0; i < len; ++i)
    {
        input_h[i] = i;
    }
    index_t * input_d; cudaMalloc(&input_d, sizeof(index_t)*len); CUERR
    cudaMemcpy(input_d, input_h, sizeof(index_t)*len, H2D); CUERR
    TIMERSTOP(init)


    //execute multisplit
    TIMERSTART(multisplit)
    multisplit
    <index_t, k, split_t>
    <<<SDIV(len, 1024), 1024>>>
    (input_d, splits_d, split_counts, len, split_t()); CUERR
    cudaDeviceSynchronize(); CUERR
    TIMERSTOP(multisplit) CUERR
    float input_gb  = sizeof(index_t)*len/1000000000.0f; //input size in GB
    float time_sec  = timemultisplit/1000.0f; //exec time in seconds
    float bandwidth = input_gb/time_sec;
    std::cout << "BANDWIDTH: " << bandwidth << " GB/s" << std::endl;

    //validate results
    TIMERSTART(validate)
    for (index_t i = 0; i < k; ++i)
    {
        validate
        <index_t, k, split_t>
        <<<SDIV(len, 1024), 1024>>>
        (splits_d, split_counts, i, split_t()); CUERR
    }
    cudaDeviceSynchronize(); CUERR
    TIMERSTOP(validate)

    //free memory
    delete[] splits_h;
    for(index_t i = 0; i < k; ++i)
    {
        cudaFree(splits_h[i]); CUERR
    }
    cudaFree(splits_d); CUERR

    cudaFree(split_counts); CUERR

    delete[] input_h;
    cudaFree(input_d); CUERR
}
