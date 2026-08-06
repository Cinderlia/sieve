
# PHP Opcode Tracer

Traces PHP execution at the VM opcode level based on Witcher's https://github.com/sefcom/Witcher/blob/master/docker/php7build.Dockerfile

## ⚠️ Important Limitations

- **JIT Compiler:** Does NOT work with PHP JIT. JIT bypasses the VM opcode executor, so opcodes won't be traced. Disable JIT with `opcache.jit=0`?

- Each PHP line = multiple opcodes, so expect duplicates.

## Installation
```bash
phpize
./configure
make
sudo make install
```

Add to `php.ini`:
```ini
extension=opcode_tracer.so
```

## Usage
```bash
OPCODE_TRACE=/tmp/trace.log php script.php
cat /tmp/trace.log
```

Remove consecutive duplicates:
```bash
uniq /tmp/trace.log
```

## Note

