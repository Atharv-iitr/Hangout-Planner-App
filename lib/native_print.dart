import 'dart:ffi' as ffi;
import 'dart:io';

typedef NativePrintFunc = ffi.Void Function();
typedef DartPrintFunc = void Function();

class NativePrint {
  late ffi.DynamicLibrary _lib;
  late DartPrintFunc printFromNative;

  NativePrint() {
    _lib = Platform.isAndroid
        ? ffi.DynamicLibrary.open("libnative.so")
        : Platform.isIOS
            ? ffi.DynamicLibrary.process() // iOS links differently
            : ffi.DynamicLibrary.open("native.dll");

    printFromNative =
        _lib.lookup<ffi.NativeFunction<NativePrintFunc>>("print_from_native").asFunction();
  }
}
