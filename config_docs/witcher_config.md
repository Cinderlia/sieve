# witcher_config.json Reference

This document explains configuration items used by Witcher itself.

## Example Configuration Found in the Repository

```json
{
  "testname": "unittests",
  "afl_inst_interpreter_binary": "/bins/php7-cgi-mysqli-afl",
  "wc_inst_interpreter_binary": "/bins/php7-cgi-mysqli-wc",
  "base_url": "http://localhost/",
  "afl_path": "/afl",
  "ld_library_path": "/wclibs",
  "afl_preload": "/wclibs/lib_db_fault_escalator.so",
  "number_of_trials": 1,
  "number_of_refuzzes": 3,
  "enable_full_param_seed": false,
  "timeout": 30,
  "script_skip_list": [],
  "script_random_order": 1,
  "cores": 3,
  "request_crawler": {
    "form_url": "http://localhost/interface/login/login.php?site=default",
    "usernameSelector": "#authUser",
    "usernameValue": "admin",
    "extraSelector_1": "[name=languageChoice]",
    "extraValue_1": "1",
    "passwordSelector": "#clearPass",
    "passwordValue": "password",
    "submitType": "enter",
    "positiveLoginMessage": "title=\"Current user\"",
    "method": "POST",
    "form_selector": ".form-login",
    "form_submit_selector": "input[type=submit]",
    "ignoreValues": [],
    "urlUniqueIfValueUnique": []
  },
  "direct": {
    "url": "http://localhost/interface/main/main_screen.php",
    "postData": "new_login_session_management=1&authProvider=TroubleMaker&authUser=admin&clearPass=password&languageChoice=1",
    "getData": "auth=login&site=default",
    "positiveHeaders": [{"Location": "/interface/main/tabs/main.php"}],
    "positiveBody": "",
    "method": "POST",
    "cgiBinary": "/php/php-cgi-mysqli-wc",
    "loginSessionCookie": "OpenEMR",
    "mandatoryGet": "",
    "extra_authorized_requests": [{"url": "http://localhost/interface/patient_file/summary/demographics.php?set_pid=2"}]
  }
}
```

## Core Fields

### `testname`
- Default: none
- Required in practice: yes
- Purpose: Used to name the report directory.

### `afl_inst_interpreter_binary`
- Default: none
- Required for `AFLR` / `AFLHR`
- Purpose: Instrumented AFL interpreter used for AFL-only modes.

### `wc_inst_interpreter_binary`
- Default: none
- Required for Witcher-instrumented modes such as `WIC*` and `EX*`
- Purpose: Instrumented interpreter used by Witcher modes.

### `base_url`
- Default: none
- Purpose: Base URL of the target application.
- Note: Used by several helper flows and expected by surrounding tooling even when not directly consumed everywhere in the main class.

### `appdir` / `app_dir` / `app_root`
- Default: `/app`
- Purpose: Application root directory.
- Resolution order: `appdir`, then `app_dir`, then `app_root`, then `/app`.

### `cores`
- Default: none
- Purpose: Number of fuzzing cores/workers.
- Note: Set this explicitly in the config when you want deterministic worker allocation.

### `timeout`
- Default: none
- Purpose: The average timeout for a single fuzz testing session.
- Note: Set this explicitly in the config when you want a stable campaign-wide timeout.

### `memory`
- Default: none
- Purpose: AFL memory limit.
- Note: Set this explicitly in the config when you want a stable memory budget for fuzzing.

### `first_crash`
- Default: CLI flag default `false`
- Purpose: Stop after the first crash instead of running until full timeout.

## AFL / Runtime Environment

### `afl_path`
- Default: `/afl`
- Purpose: Exported to `AFL_PATH`.

### `ld_library_path`
- Default: empty string when omitted
- Purpose: Exported to `LD_LIBRARY_PATH` for the target runtime.

### `afl_preload`
- Default: empty string when omitted
- Purpose: Exported to `AFL_PRELOAD`.

### `run_timeout_ms`
- Default: no explicit JSON default
- Purpose: Per-execution timeout in milliseconds used for AFL child runs.
- Precedence: Preferred over `run_timeout`.

### `run_timeout`
- Default: `200`
- Purpose: Backward-compatible per-execution timeout in milliseconds when `run_timeout_ms` is absent.

### `use_qemu`
- Default: none / falsy when omitted
- Purpose: Enables QEMU-backed execution in the Phuzzer layer.

## Campaign Control

### `number_of_trials`
- Default: `1`
- Purpose: Number of campaign trials.

### `number_of_refuzzes`
- Default: `1`
- Purpose: Number of refuzz rounds.

### `script_random_order`
- Default: falsy when omitted
- Purpose: Randomizes target script order when enabled.
- Example value in repository: `1`.

### `script_start_index`
- Default: `0`
- Purpose: Start index of the target-script slice to fuzz.

### `script_end_index`
- Default: length of the discovered target list
- Purpose: End index of the target-script slice to fuzz.

### `script_skip_list`
- Default: none
- Purpose: Declares scripts to skip.
- Note: Present in the repository example; handling depends on the target selection flow used by the campaign.

### `global_min_fuzz_time`
- Default: `300`
- Purpose: Minimum fuzzing time budget used in redistribution and campaign scheduling logic.

## Seed / Request Data Controls

### `merge_seed_requests`
- Default: `false`
- Purpose: Merges `seedRequestsFound` into `requestsFound` from `request_data.json`.

### `max_initial_seeds`
- Default: unlimited at config read time; effective fallback limit `50` when no explicit value is set during seed limiting logic
- Purpose: Caps the number of initial seeds kept per target.

### `enable_full_param_seed`
- Default: `false`
- Purpose: Enables loading full parameter seeds from the initial parameter JSON.

### `initial_params_json`
- Default: resolved as `initial_params.json` under the test location or profile directory
- Purpose: Overrides the file used to load initial parameter seeds.

## Server / Target Execution

### `server_cmd`
- Default: `null`
- Purpose: Command array used to start the application server process.
- Notes:
  - The code expects a sequence of command tokens.
  - `@@PORT@@` placeholders are replaced with the base port.

### `server_base_port`
- Default: `14000`
- Purpose: Base port assigned to started server processes and passed to the fuzzing layer.

### `server_env_vars`
- Default: `{}`
- Purpose: Extra environment variables applied when starting the server process.

### `server_up_msg`
- Default: none
- Purpose: Marker string used to detect when the server has started successfully.

### `binary_options`
- Default: none
- Required in practice: yes for normal execution paths
- Purpose: Command-line options template for the interpreter/binary under fuzzing.
- Note: The code calls `.split(" ")` on this field, so it is expected to be a space-separated string.

### `init_info_shm`
- Default: none
- Purpose: Optional command used to initialize shared memory before fuzzing.

### `war_path`
- Default: none
- Purpose: Optional path to a WAR archive for Java/Tomcat-oriented flows.

## Database / SymEx Integration

### `symex_enabled`
- Default: `true`
- Purpose: Enables launching the SymEx hybrid assistant from Witcher.

### `symex_trace_timeout`
- Default: `30`
- Purpose: Trace timeout passed to the SymEx launcher.

### `witcher_db_backup_enabled`
- Default: `true`
- Purpose: Enables automatic database backup/restore support for SymEx-related database workflows.

## `direct` Login / Authorization Block

This section is used to construct direct login requests, authorization cookies, and mandatory request context.

### `direct.url`
- Default: empty
- Purpose: Login or bootstrap URL.

### `direct.pre_login` / `direct.preLoginPage`
- Default: empty
- Purpose: Optional page fetched before login to collect cookies or session state.

### `direct.method`
- Default: `GET`
- Purpose: HTTP method used for the direct login request.

### `direct.getData`
- Default: empty
- Purpose: Query string appended to `direct.url`.

### `direct.postData`
- Default: empty
- Purpose: POST body sent with the direct login request.

### `direct.headers`
- Default: `{}`
- Purpose: Additional HTTP headers for the direct login request.

### `direct.loginSessionCookie`
- Default: empty
- Purpose: Preset login cookie value or cookie name used to preserve authenticated state.

### `direct.login_cookie`
- Default: empty
- Purpose: Additional login cookie source used in cookie-blacklist and session handling logic.

### `direct.mandatory_cookie`
- Default: empty
- Purpose: Exported to `MANDATORY_COOKIE` and treated as mandatory cookie context.

### `direct.mandatory_get`
- Default: empty
- Purpose: Exported to `MANDATORY_GET` and appended as mandatory GET context.

### `direct.mandatory_post`
- Default: empty
- Purpose: Exported to `MANDATORY_POST` and applied as mandatory POST context.

### `direct.positiveHeaders`
- Default: none
- Purpose: Expected headers used by helper flows to detect successful login behavior.

### `direct.positiveBody`
- Default: empty
- Purpose: Expected body content used by helper flows to detect successful login behavior.

### `direct.cgiBinary`
- Default: none
- Purpose: CGI binary path used in some legacy/direct execution setups.

### `direct.extra_authorized_requests`
- Default: none
- Purpose: Additional authenticated URLs that may be fetched or retained after login.

## `request_crawler` Block

The repository example includes a `request_crawler` block for the crawler login form.

Common example fields include:

- `form_url`
- `usernameSelector`
- `usernameValue`
- `passwordSelector`
- `passwordValue`
- `extraSelector_1`
- `extraValue_1`
- `submitType`
- `positiveLoginMessage`
- `method`
- `form_selector`
- `form_submit_selector`
- `ignoreValues`
- `urlUniqueIfValueUnique`

These fields are used by the request crawler helpers rather than the core Witcher class. Their exact behavior depends on the Node.js crawler implementation used in your environment.

## Practical Guidance

At minimum, a working `witcher_config.json` usually needs:

- `testname`
- the correct interpreter binary field for the selected mode
- `binary_options`
- `base_url`
- a usable `direct` login block or equivalent authenticated request setup
- campaign settings such as `cores` and `timeout`

