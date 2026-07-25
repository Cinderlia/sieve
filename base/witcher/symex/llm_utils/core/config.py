"""Load LLM runtime configuration from environment variables and .env files."""

import os
try:
    from dataclasses import dataclass
except Exception:
    from compat_dataclasses import dataclass
from typing import Dict, List, Optional

try:
    from common.app_config import load_symex_app_config
except Exception:
    from symex.common.app_config import load_symex_app_config


@dataclass(frozen=True)
class LLMConfig:
    """Immutable configuration for an LLM HTTP client."""
    base_url: str
    api_key: str
    model: str
    temperature: float = 0.0
    timeout_s: float = 60.0
    max_tokens: Optional[int] = None
    max_retries: int = 3


_DEFAULTS = {
    'base_url': 'https://api.openai.com/v1',
    'api_key': '',
    'model': 'gpt-5.4-mini',
    'temperature': 0.2,
    'timeout_s': 300.0,
    'max_tokens': 8192,
    'max_retries': 3,
}


def _norm_base_url(base_url: str) -> str:
    """Normalize a base URL to a stable form (no trailing '/')."""
    u = (base_url or '').strip()
    if not u:
        return u
    return u.rstrip('/')


def _read_env_file(env_path: str) -> Dict[str, str]:
    data: Dict[str, str] = {}
    if not os.path.exists(env_path):
        return data
    with open(env_path, 'r', encoding='utf-8', errors='replace') as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            data[key.strip()] = value.strip()
    return data


def _pick_env_value(name: str, env_file_values: Dict[str, str], aliases: Optional[List[str]] = None) -> Optional[str]:
    names = [name]
    if aliases:
        names.extend(aliases)
    for key in names:
        value = os.environ.get(key)
        if value is not None:
            return value
    for key in names:
        value = env_file_values.get(key)
        if value is not None:
            return value
    return None


def _resolve_env_dirs(config_path: Optional[str] = None) -> List[str]:
    candidates: List[str] = []
    try:
        cfg = load_symex_app_config(config_path=config_path)
        cfg_path = str(getattr(cfg, 'config_path', '') or '').strip()
        if cfg_path:
            candidates.append(os.path.dirname(os.path.abspath(cfg_path)))
    except Exception:
        pass
    if config_path:
        candidates.append(os.path.dirname(os.path.abspath(config_path)))
    seen = set()
    ordered: List[str] = []
    for path in candidates:
        if not path:
            continue
        key = os.path.normcase(os.path.abspath(path))
        if key in seen:
            continue
        seen.add(key)
        ordered.append(os.path.abspath(path))
    return ordered


def load_llm_config(config_path: Optional[str] = None) -> LLMConfig:
    """
    Load LLM config from environment variables and nearby .env files.

    Precedence:
    - process environment variables
    - `.env` in the resolved runtime config directory
    - built-in defaults
    """
    env_dirs = _resolve_env_dirs(config_path)
    env_file_values: Dict[str, str] = {}
    for cfg_dir in env_dirs:
        env_path = os.path.join(cfg_dir, '.env')
        env_file_values.update(_read_env_file(env_path))

    base_url = _norm_base_url(str(_pick_env_value('BASE_URL', env_file_values, ['OPENAI_BASE_URL', 'JOERNTRACE_LLM_BASE_URL']) or _DEFAULTS['base_url']).strip())
    api_key = str(_pick_env_value('API_KEY', env_file_values, ['OPENAI_API_KEY', 'JOERNTRACE_LLM_API_KEY']) or _DEFAULTS['api_key']).strip()
    model = str(_pick_env_value('MODEL', env_file_values, ['OPENAI_MODEL', 'JOERNTRACE_LLM_MODEL']) or _DEFAULTS['model']).strip()

    temperature = _pick_env_value('TEMPERATURE', env_file_values)
    timeout_s = _pick_env_value('TIMEOUT_S', env_file_values)
    max_tokens = _pick_env_value('MAX_TOKENS', env_file_values)
    max_retries = _pick_env_value('MAX_RETRIES', env_file_values)

    temperature_f = float(temperature) if temperature not in (None, '') else float(_DEFAULTS['temperature'])
    timeout_f = float(timeout_s) if timeout_s not in (None, '') else float(_DEFAULTS['timeout_s'])
    max_tokens_i = int(max_tokens) if max_tokens not in (None, '') else int(_DEFAULTS['max_tokens'])
    max_retries_i = int(max_retries) if max_retries not in (None, '') else int(_DEFAULTS['max_retries'])

    if not base_url:
        raise ValueError('missing base_url')
    if not model:
        raise ValueError('missing model')

    return LLMConfig(
        base_url=base_url,
        api_key=api_key,
        model=model,
        temperature=temperature_f,
        timeout_s=timeout_f,
        max_tokens=max_tokens_i,
        max_retries=max_retries_i,
    )
