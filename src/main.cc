#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "tensorflow/lite/core/c/common.h"

#ifdef BENCHMARK_RESNET
#include "models/resnet_model_quant.h"
#endif

#ifdef BENCHMARK_KWS
#include "models/kws_model.h"
#endif

#ifdef BENCHMARK_VWW
#include "models/vww_model.h"
#endif

#ifdef BENCHMARK_AD
#include "models/ad01_model.h"
#endif

#define BENCHMARK_LOOP 1

int main(){

    #ifdef BENCHMARK_RESNET
    const tflite::Model* model = ::tflite::GetModel(resnet_model_quant);
    #endif

    #ifdef BENCHMARK_VWW
    const tflite::Model* model = ::tflite::GetModel(vww_model);
    #endif

    #ifdef BENCHMARK_KWS
    const tflite::Model* model = ::tflite::GetModel(kws_model);
    #endif

    #ifdef BENCHMARK_AD
    const tflite::Model* model = ::tflite::GetModel(ad01_model);
    #endif


    if (model->version() != TFLITE_SCHEMA_VERSION) {
      MicroPrintf(
        "Model provided is schema version %d not equal "
        "to supported version %d.\n",
          model->version(), TFLITE_SCHEMA_VERSION);
        return -1;
    }

    #ifdef BENCHMARK_RESNET
    tflite::MicroMutableOpResolver<8> resolver;
    resolver.AddAdd();
    resolver.AddConv2D();
    resolver.AddRelu();
    resolver.AddBatchToSpaceNd();
    resolver.AddReshape();
    resolver.AddAveragePool2D();
    resolver.AddFullyConnected();
    resolver.AddSoftmax();

    const int tensor_arena_size = 128 * 1024;
    uint8_t tensor_arena[tensor_arena_size];
    #endif

    #ifdef BENCHMARK_VWW
    tflite::MicroMutableOpResolver<9> resolver;
    resolver.AddAdd();
    resolver.AddConv2D();
    resolver.AddDepthwiseConv2D();
    resolver.AddRelu();
    resolver.AddReshape();
    resolver.AddBatchToSpaceNd();
    resolver.AddAveragePool2D();
    resolver.AddFullyConnected();
    resolver.AddSoftmax();

    const int tensor_arena_size = 128 * 1024;
    uint8_t tensor_arena[tensor_arena_size];

    #endif

    #ifdef BENCHMARK_KWS
    tflite::MicroMutableOpResolver<9> resolver;
    resolver.AddAdd();
    resolver.AddConv2D();
    resolver.AddDepthwiseConv2D();
    resolver.AddRelu();
    resolver.AddReshape();
    resolver.AddBatchToSpaceNd();
    resolver.AddAveragePool2D();
    resolver.AddFullyConnected();
    resolver.AddSoftmax();

    const int tensor_arena_size = 64 * 1024;
    uint8_t tensor_arena[tensor_arena_size];

    #endif

    #ifdef BENCHMARK_AD
    tflite::MicroMutableOpResolver<7> resolver;
    resolver.AddAdd();
    resolver.AddConv2D();
    resolver.AddRelu();
    resolver.AddReshape();
    resolver.AddBatchToSpaceNd();
    resolver.AddFullyConnected();
    resolver.AddSoftmax();

    const int tensor_arena_size = 64 * 1024;
    uint8_t tensor_arena[tensor_arena_size];

    #endif

    tflite::MicroInterpreter interpreter(
        model, resolver,
        tensor_arena,tensor_arena_size
        );

    interpreter.AllocateTensors();

    TfLiteTensor* input = interpreter.input(0);

    if(input == nullptr){
        MicroPrintf("interpreter is null, benchmark failed!");
        return -1;
    }
    else{
        MicroPrintf("Model Input size: %d,", input->dims->size);
        for(int i = 0; i < input->dims->size; i++){
            MicroPrintf("%d ", input->dims->data[i]);
        }
        const char* model_type = input->type == kTfLiteFloat32 ? "float" : "uint8";
        MicroPrintf("Model Input type: %s\n", model_type);
    }

    // Inference Benchmarking
    MicroPrintf("Start Inference Benchmarking For %d Times!",
        BENCHMARK_LOOP);
    for(int i = BENCHMARK_LOOP; i > 0; i--){
        for(int j = 0; j < input->bytes; j++){
            input->data.uint8[j] = 0;
        }
        MicroPrintf("Start Inference No.%d", i);
        TfLiteStatus invoke_status = interpreter.Invoke();
        if (invoke_status != kTfLiteOk) {
            MicroPrintf("Invoke failed!");
            return -1;
        }
        TfLiteTensor* output = interpreter.output(0);
        MicroPrintf("Completed Inference No.%d", i);
    }
    MicroPrintf("Finished Inference Benchmarking!");
    return 0;
}