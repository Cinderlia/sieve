# initial_url_config.json Reference

This document explains configuration items used by the initial URL discovery pipeline.

## Default Configuration

```json
{
  "enable_code_scan": true,
  "enable_param_scan": true,
  "param_minimizer": {
    "mode_arg": "request_crawler",
    "accept_full_params_without_minimization": false
  },
  "crawler": {
    "start": false,
    "node_bin": "node",
    "no_headless": false,
    "xvfb": true,
    "timeout": "4h",
    "mode_arg": "request_crawler"
  }
}
```

## Output Files

- `initial_urls.txt`: main integrated URL list used by the later crawler/minimizer flow
- `initial_params.json`: parameter data used by the parameter minimizer
- `request_data.json`: crawler output and persistent request dataset used by Witcher
- `afl_request_data.json`: seed request dataset consumed by the crawler and later merged into fuzzing inputs


## Top-Level Fields

### `enable_code_scan`
- Default: `true`
- Purpose: Enables source-code-based URL collection.
- Effect: When enabled, the pipeline collects candidate URLs from PHP source files and appends selected results into `initial_urls.txt` and `afl_request_data.json`.

### `enable_param_scan`
- Default: `true`
- Purpose: Enables parameter discovery from source code.
- Effect: Generates `initial_urls.json` and enables the parameter minimization stage before crawler startup.

## `param_minimizer`

### `param_minimizer.mode_arg`
- Default: `request_crawler`
- Purpose: Mode argument forwarded to the downstream Node.js minimizer/crawler tooling.

### `param_minimizer.accept_full_params_without_minimization`
- Default: `false`
- Purpose: Allows full parameters to be accepted directly when minimization is skipped or cannot reduce them.

## `crawler`

### `crawler.start`
- Default: `false`
- Purpose: Automatically starts the crawler after initial URL preparation.
- CLI override: `--start-crawler`

### `crawler.node_bin`
- Default: `node`
- Purpose: Node.js executable used to launch the crawler helper.

### `crawler.no_headless`
- Default: `false`
- Purpose: Runs the browser in non-headless mode.
- CLI override: `--no-headless`

### `crawler.xvfb`
- Default: `true`
- Purpose: Launches the crawler with Xvfb support.
- CLI override: `--xvfb`

### `crawler.timeout`
- Default: `4h`
- Purpose: Timeout string passed to the crawler helper.
- CLI override: `--timeout`

### `crawler.mode_arg`
- Default: `request_crawler`
- Purpose: Mode argument passed to the crawler command.
