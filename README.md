# Sieve

Sieve (or Symex) is a hybrid fuzzing tool built on top of Witcher. 
It currently supports PHP 7 and 8.

## License

Sieve is distributed under a dual-license model:

- The Witcher code is licensed under the BSD 3-Clause License. See [LICENSE.md](./LICENSE.md) for details.
- Sieve-specific modifications and new components (including the symbolic execution engine, PHP 8 support, opcode tracer, and none request parameters) are licensed under the BSD 3-Clause License. See [LICENSE](./LICENSE) for details.

## Installation

We recommend using the provided Docker images to run Sieve.

### Building the Docker Images

Clone the repository and navigate to the docker directory:
```bash
git clone https://github.com/Cinderlia/sieve.git
cd sieve
git submodule update --init --recursive
cd docker
./build.sh
```

### Using the Docker Images

Run the PHP 7 runtime container:
```bash
docker run -it --rm sieve/php7run

```

## Overview

1. Start and prepare the target server inside the container.
2. Create a working directory for config files and generated artifacts.
3. Configure `witcher_config.json`.
4. Configure `initial_url_config.json`.
5. Run the initial URL discovery and optional crawler stage.
6. Generate AST files and place them under `AST/`.
7. Configure `sieve_config.json` or `symex_config.json`.
8. Start Witcher with the Sieve/SymEx-enabled test profile.

## Environment Preparation

Run the following commands in the container:

```bash
# Start services
service apache2 start
mysqld --daemonize

# Scheduler settings
echo 1 > /proc/sys/kernel/sched_child_runs_first
echo core > /proc/sys/kernel/core_pattern

# CPU performance mode
for fn in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > "$fn"
done

# Set display
export DISPLAY=:0
```

## Prepare a Working Directory

Create a directory to store configuration files and generated artifacts.

Typical files created or used in this directory include:

- `witcher_config.json`
- `sieve_config.json`
- `initial_url_config.json`
- `request_data.json`
- `AST/`
- fuzzing outputs produced by Witcher

We have provided example configuration files in the Docker image.

## Configure Witcher

Create and edit `witcher_config.json` in the working directory.

A full field-by-field reference is provided in [witcher_config.md](./config_docs/witcher_config.md).

## Configure Initial URL Discovery

Create and edit `initial_url_config.json` in the working directory. 
For most use cases, we recommend sticking with the defaults. 
A full field-by-field reference is provided in [initial_url_config.md](./config_docs/initial_url_config.md).

## Run the Modified Crawler

Run the following command to execute the modified initial URL pipeline. If the server does not provide a graphical environment, keep `--xvfb` enabled.

```bash
su - sv
python3 /helpers/initial_url/main.py http://127.0.0.1/dvwa/ ./ /app/dvwa/ --start-crawler --no-headless --timeout 4h --xvfb
```

### Positional Arguments

1. `http://127.0.0.1/dvwa/`
   - `base_url`
   - Base URL of the target web application.
2. `./`
   - `base_appdir`
   - Working directory that contains configuration files and receives generated outputs.
3. `/app/dvwa/`
   - `source_dir`
   - Source-code directory of the target application.

### Optional Arguments

- `--max-file-bytes`
  - Default: `5242880` (5 MiB)
  - Maximum source-file size considered by code scanning and parameter scanning.
- `--config`
  - Default: `initial_url_config.json`
  - Config file name resolved relative to the working directory.
- `--start-crawler`
  - Default: disabled
  - Starts the request crawler after initial URL and parameter preparation.
  - Equivalent to setting `crawler.start=true` in `initial_url_config.json`.
- `--no-headless`
  - Default: disabled at CLI level; config default is `false`
  - Runs the crawler with a visible browser instead of headless mode.
  - Overrides `crawler.no_headless` to `true`.
- `--xvfb`
  - Default: disabled at CLI level; config default is `true`
  - Forces crawler startup through Xvfb.
  - Useful on servers without a desktop session.
  - Overrides `crawler.xvfb` to `true`.
- `--timeout`
  - Default: empty at CLI level; config default is `4h`
  - Timeout passed to the crawler command.
  - Overrides `crawler.timeout`.

### Expected results of crawling

The pipeline now keeps only the required files:

- `initial_urls.txt`
- `initial_urls.json`
- `request_data.json`
- `afl_request_data.json`


## Generate AST Files

Create an `AST` directory inside the working directory, then generate AST data for the target application.

Generate `nodes.csv` and `rels.csv`:

```bash
/phpjoern/php2ast -n nodes.csv -r rels.csv /app/dvwa
```

Generate `cpg_edges.csv`:

```bash
/joern/phpast2cpg nodes.csv rels.csv
```

Place all three files under `AST/`:

- `nodes.csv`
- `rels.csv`
- `cpg_edges.csv`

## Configure Sieve / SymEx

Create `sieve_config.json` or `symex_config.json` in the working directory.
The code treats these names as interchangeable and resolves either one as the active SymEx config.

Sieve can run without this configuration file, but some features may not work as expected. We recommend at least filling in the symbolic_db section to ensure full functionality.

A full field-by-field reference is provided in [symex_config.md](./config_docs/symex_config.md).

## Configure LLM Access

The LLM configuration is loaded from environment variables or a `.env` file placed in the same working directory as the active runtime config files.

Typical `.env` keys include:

```env
API_KEY=your_api_key
BASE_URL=https://api.openai.com/v1
MODEL=gpt-5.4-mini
TEMPERATURE=0.2
TIMEOUT_S=300
MAX_TOKENS=8192
MAX_RETRIES=3
```

## Start Witcher

Start Witcher with:

```bash
su - sv
p --testver SIEVE
```

Notes:

- The command-line entry point accepts the test location, test profile, timeout, and other runtime options. 
- The `sieve`/`symex` flow is enabled together with Witcher for the corresponding test profile in this project’s environment.
- The main fuzzing timeout defaults to `3600` seconds at CLI level unless overridden by `witcher_config.json` or command-line flags.

## Coverage Collection

Start recording coverage files:

```bash
touch /tmp/start_test.dat
```

Coverage files are generated under `/dev/shm/coverages`.

Merge the coverage files:

```bash
python3 /codecov_conversion.py
```

Merged coverage output is generated under `/tmp/coverages`.

## Configuration Reference Files

Detailed configuration references are available under [config_docs](./config_docs):

- [witcher_config.md](./config_docs/witcher_config.md)
- [initial_url_config.md](./config_docs/initial_url_config.md)
- [symex_config.md](./config_docs/symex_config.md)
