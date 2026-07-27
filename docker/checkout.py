#!/usr/bin/env python3

import os
import pathlib
import shlex
import subprocess
import sys

# lang_location from /Witcher, github repo, branch
GITHUB_REPOS = {
    '7': [
        ('php7/repo', "/php/php-src", "php-7.3.3"),
        ('php7/repo/ext/xdebug', "xdebug/xdebug", "3.0.4"),
    ],
    '8': [
        ('php8/repo', "/php/php-src", "php-8.4.21"),
        ('php8/repo/ext/xdebug', "xdebug/xdebug", "3.4.1"),
    ],
}


def check_origin(path: pathlib.Path, repo: str) -> None:
    origin_url = subprocess.run(shlex.split(
        "git remote get-url origin"), cwd=path, stdout=subprocess.PIPE).stdout.decode("utf-8")
    if repo not in origin_url:
        print(80 * "#")
        print(
            f"WARNING: remote 'origin' for {path.name} is different from checkout_all.py")
        print(
            f"This can be fixed simply by running `rm -rf {path}` and rerunning checkout_all.py")
        print(80 * "#", flush=True)


def main():
    print("Starting checkout")
    procs = []
    base_path = os.path.realpath(os.path.join(os.path.dirname(__file__),".."))

    if len(sys.argv) < 2:
        print("Usage: checkout.py <php_version>")
        print("  php_version: 7 or 8")
        sys.exit(1)

    php_version = sys.argv[1]
    print(f"Checking out PHP version: {php_version}")

    if php_version not in GITHUB_REPOS:
        print(f"Unsupported PHP version: {php_version}")
        print(f"Supported versions: {list(GITHUB_REPOS.keys())}")
        sys.exit(1)

    repos = GITHUB_REPOS[php_version]

    for rpath, repo, branch in repos:
        repos_path = pathlib.Path(os.path.join(base_path, rpath))

        print(f'\tUpdating {repo}', flush=True)

        if not repos_path.exists():
            procs.append(subprocess.Popen(["git", "clone", "--no-single-branch", "--depth=1", "-b", branch, f"git@github.com:{repo}.git", repos_path],
                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE))
        else:
            check_origin(repos_path, repo)
            procs.append(subprocess.Popen(f"git pull origin {branch}",
                                          shell=True, cwd=repos_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE))

    success = True
    for p in procs:
        out, err = p.communicate()
        rtn = p.returncode
        if rtn != 0:
            success = False
            print("Error with execution ")
            print(out)
            print(f"\033[31m{err}\033[0m")

    assert success


if __name__ == "__main__":
    main()