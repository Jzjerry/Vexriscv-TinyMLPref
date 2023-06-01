# MLPerf™ Tiny for Vexriscv

This repo includes TinyML files and models ported for Vexriscv (particularly for the regression tests).

## Contents

+ TensorFlow Lite Micro library source files (`src/tensorflow`, `src/third_party`)
+ Models from MLPerf™ Tiny (`models`)
+ Prebuild Hex for Vexriscv Benchmarking (`hex`)

## Supported ISA

Currently the files are only for RV32I[M[C]] ISA, which is the basic ISA supported by Vexriscv.

## Usage

```
$ make BENCH=<select from: RESNET,VWW,KWS,AD> MULDIV=yes(for RV32M) COMPRESSED=yes(for RV32C)
```

## Adding New Models

1. Follow the tutorials of TFLM to convert models into C files, move them to `src/models`.
2. Modify `src/main.cc` refering to existing benchmarks. (use `#ifdef` and `#endif`)

## Ported Files

For now, the only modified file is `src/tensorflow/micro/debug_log.cc`. 
The printing function is redirected to the simulated UART just like other benchmarks for Vexriscv.