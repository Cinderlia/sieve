#ifndef PHP_OPCODE_TRACER_H
#define PHP_OPCODE_TRACER_H

extern zend_module_entry opcode_tracer_module_entry;
#define phpext_opcode_tracer_ptr &opcode_tracer_module_entry

#define PHP_OPCODE_TRACER_VERSION "1.0.0"

#ifdef PHP_WIN32
#   define PHP_OPCODE_TRACER_API __declspec(dllexport)
#elif defined(__GNUC__) && __GNUC__ >= 4
#   define PHP_OPCODE_TRACER_API __attribute__ ((visibility("default")))
#else
#   define PHP_OPCODE_TRACER_API
#endif

#ifdef ZTS
#include "TSRM.h"
#endif

#endif /* PHP_OPCODE_TRACER_H */
