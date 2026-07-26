# Symex Hybrid IO

`prepare_symex_inputs.py` extracts and organizes the inputs required by SymEx from a Witcher/AFL runtime directory.

## Input Sources

- `AST/*.csv`: the `AST` directory located next to `witcher_config.json`
- AFL launch scripts: `<work_dir>/fuzz-*.sh`
- AFL seeds: `<work_dir>/fuzzer-*/queue/id:*`
- Total coverage: `/dev/shm/coverages/*.cc.json` (derived from `SCRIPT_FILENAME` using the `enable_cc.php` rule)

## Output Directory

All extracted outputs are placed under `<work_dir>/symex_runtime/` to keep them separate from the original AFL runtime directory:

- `ast_inputs/`: copied CSV files
- `commands/`: extracted commands and trace execution scripts
- `commands/test_command.txt`: extracted key exports (avoids filename encoding issues under non-UTF-8 locales)
- `coverage/`: copied `.cc.json` files
- `seeds/raw/`: raw seeds (binary)
- `seeds/text/`: parsed seeds (COOKIE/GET/POST)
- `traces/`: reserved for `trace.log`
- `meta/prepare_report.json`: extraction report

## Usage

```bash
python witcher/symex/hybrid_io/prepare_symex_inputs.py \
  --config /path/to/witcher_config.json \
  --work-dir /path/to/work
```
