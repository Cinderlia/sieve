# LLM Configuration

After this change, the SymEx LLM configuration is no longer read from `llm_config.json`.

## Configuration sources

The loader now reads configuration in this order:

1. Process environment variables
2. `.env` in the same directory as the resolved runtime config file
3. Built-in defaults

If the same key exists in multiple places, the earlier source wins.

## How the `.env` location is resolved

The `.env` file is loaded from the same runtime config directory that Witcher and SymEx already use for files such as:

- `witcher_config.json`
- `request_data.json`
- `symex_config.json`

In other words, the loader follows the resolved config directory, not the `llm_utils` code directory.

## Configuration log

Each configuration load also writes a diagnostic log entry to `llm_config.log` inside the runtime `meta` directory when that directory can be resolved.

Typical target locations are based on runtime metadata paths such as:

- `SYMEX_PIPELINE_RUN_DIR/meta/llm_config.log`
- `WITCHER_SYMEX_META_DIR/llm_config.log`
- the current working directory, if the process is already running inside a `meta` directory

The log records:

- resolved config argument
- resolved `.env` search directories
- `.env` files that were checked
- resolved meta log directories
- the source of each LLM setting (`environment`, `.env`, or `default`)

`API_KEY` is masked in the log.

## Supported keys

Use the same format in both environment variables and `.env` files:

```env
API_KEY=sk-your-actual-api-key
BASE_URL=https://api.openai.com/v1
MODEL=gpt-5.4-mini
TEMPERATURE=0.2
TIMEOUT_S=300
MAX_TOKENS=8192
MAX_RETRIES=3
```

## Default values

If a key is not provided by the environment or `.env`, these defaults are used:

- `BASE_URL`: `https://api.openai.com/v1`
- `API_KEY`: empty
- `MODEL`: `gpt-5.4-mini`
- `TEMPERATURE`: `0.2`
- `TIMEOUT_S`: `300`
- `MAX_TOKENS`: `8192`
- `MAX_RETRIES`: `3`

## Example

If your active runtime config is stored in a project directory, put `.env` in that same directory.

Example:

```env
API_KEY=sk-your-actual-api-key
BASE_URL=https://api.openai.com/v1
MODEL=gpt-5.4-mini
```

## Notes

- Environment variables always override `.env` values.
- `API_KEY` may be empty in configuration, but actual LLM requests will fail if no valid key is provided.
- `BASE_URL` is normalized by removing a trailing `/`.
