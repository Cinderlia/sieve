# LLM Configuration

The loader reads configuration in this order:

1. Process environment variables
2. `.env` in the same directory as the resolved runtime config file
3. Built-in defaults

If the same key exists in multiple places, the earlier source wins.

## How the `.env` location is resolved

The `.env` file is loaded from the same runtime config directory such as:

- `witcher_config.json`
- `request_data.json`
- `symex_config.json`

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


## Notes

- Environment variables always override `.env` values.
- `API_KEY` may be empty in configuration, but actual LLM requests will fail if no valid key is provided.
- `BASE_URL` is normalized by removing a trailing `/`.
