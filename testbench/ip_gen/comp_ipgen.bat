@rem GCCmust be from questasim or modelsim!!!!!!!!!!!!!!!!!!

C:\Xilinx\modelsim10.1c\gcc-4.5.0-mingw64\bin\gcc.exe  -g -c -IC:/Xilinx/modelsim10.1c/include ipgen_pli.c
C:\Xilinx\modelsim10.1c\gcc-4.5.0-mingw64\bin\gcc.exe  -shared -LC:/Xilinx/modelsim10.1c/win64  ipgen_pli.o -lmtipli -o ipgen_pli.dll

C:\Xilinx\modelsim10.1c\gcc-4.5.0-mingw64\bin\gcc.exe  -g -c -IC:/Xilinx/modelsim10.1c/include ipgen_pli2.c
C:\Xilinx\modelsim10.1c\gcc-4.5.0-mingw64\bin\gcc.exe  -shared -LC:/Xilinx/modelsim10.1c/win64  ipgen_pli2.o -lmtipli -o ipgen_pli2.dll



@rem C:\Xilinx\modelsim10.1c\gcc-4.5.0-mingw64\bin\gcc.exe  -g -c -IC:/Xilinx/questasim_6.6a/include ipgen_test_pli.c
@rem C:\Xilinx\questasim_6.6a\questasim-gcc-4.2.1-mingw32vc9\gcc-4.2.1-mingw32vc9\bin\gcc.exe  -shared -LC:/Xilinx/questasim_6.6a/win32 -lmtipli -o ipgen_test_pli.dll ipgen_test_pli.o


@rem C:\Xilinx\questasim_6.6a\questasim-gcc-4.2.1-mingw32vc9\gcc-4.2.1-mingw32vc9\bin\gcc.exe  -g -c -IC:/Xilinx/questasim_6.6a/include gen_framer_pli.c
@rem C:\Xilinx\questasim_6.6a\questasim-gcc-4.2.1-mingw32vc9\gcc-4.2.1-mingw32vc9\bin\gcc.exe  -shared -LC:/Xilinx/questasim_6.6a/win32 -lmtipli -o gen_framer_pli.dll gen_framer_pli.o


