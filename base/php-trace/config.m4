PHP_ARG_ENABLE(opcode_tracer, whether to enable opcode tracer support,
[  --enable-opcode-tracer   Enable opcode tracer support])

if test "$PHP_OPCODE_TRACER" != "no"; then
  PHP_NEW_EXTENSION(opcode_tracer, opcode_tracer.c, $ext_shared)
fi
