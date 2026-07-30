# symex_config.json / sieve_config.json Reference

This document explains the shared configuration file used by the Sieve/SymEx subsystem.

## Name Resolution

The code accepts either `sieve_config.json` or `symex_config.json` and treats them as interchangeable runtime config names. 

## Example Configuration Found in the Repository

```json
{
  "symex_enabled": true,
  "app_name": "joomla-3.7"
}
```

## Important Note About Defaults

## Core Fields

### `symex_enabled`
- Default: `true`
- Purpose: Enables the SymEx subsystem.
- Effect: Used by the Witcher-side SymEx launcher and by the example config.

### `app_name`
- Default: none / normalized empty when omitted
- Purpose: Logical application name used by SymEx app configuration and related metadata.

## Optional `symbolic_db` Block

This block configures database queries and database backup/restore support.

If omitted, the code falls back to these defaults:

```json
{
  "symbolic_db": {
    "engine": "mysql",
    "host": "127.0.0.1",
    "port": 3306,
    "database": "",
    "username": "root",
    "password": "",
    "connect_timeout_sec": 3,
    "query_timeout_sec": 5,
    "max_rows": 50
  }
}
```

### `symbolic_db.engine`
- Default: `mysql`
- Purpose: Database engine for symbolic DB access.
- Note: Current implementation only supports MySQL.

### `symbolic_db.host`
- Default: `127.0.0.1`
- Purpose: Database host.

### `symbolic_db.port`
- Default: `3306`
- Purpose: Database port.

### `symbolic_db.database`
- Default: empty string
- Purpose: Database name.
- Note: If empty, DB-assisted features are effectively disabled.

### `symbolic_db.username`
- Default: `root`
- Purpose: Database username.

### `symbolic_db.password`
- Default: empty string
- Purpose: Database password.

### `symbolic_db.connect_timeout_sec`
- Default: `3`
- Purpose: Connection timeout for DB access.

### `symbolic_db.query_timeout_sec`
- Default: `5`
- Purpose: Query timeout for DB access.

### `symbolic_db.max_rows`
- Default: `50`
- Purpose: Maximum number of rows returned or processed for DB-assisted symbolic querying.

## Optional `symbolic_seed_kinds` Block

This block enables or disables symbolic seed categories.

Supported keys:

- `POST`
- `GET`
- `COOKIE`
- `SESSION`
- `ENV`
- `SQL`
- `FILE`

Example:

```json
{
  "symbolic_seed_kinds": {
    "POST": true,
    "GET": true,
    "COOKIE": false,
    "SESSION": true,
    "ENV": true,
    "SQL": true,
    "FILE": true
  }
}
```

Each key:
- Default: `true`
- Purpose: Enables or disables symbolic seed generation/processing for that input kind.

## Path-Related Behavior

The app configuration loader also understands path settings from the same runtime config file.

If present, these fields may be read:

### `paths.input_dir`
- Default: `input`
- Purpose: Runtime input directory.

### `paths.tmp_dir`
- Default: `tmp`
- Purpose: Runtime temporary directory.

### `paths.test_dir`
- Default: `test`
- Purpose: Runtime test directory.

### `paths.output_dir`
- Default: `output`
- Purpose: Runtime output directory.

Equivalent top-level fallbacks also exist:

- `input_dir`
- `tmp_dir`
- `test_dir`
- `output_dir`

## Minimal Practical Config

A minimal usable config is:

```json
{
  "symex_enabled": true,
  "app_name": "your-app-name"
}
```

Add `symbolic_db` only if you want DB-assisted symbolic querying or DB backup/restore support.
