#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

IMAGE_PREFIX="hybridfuzzer"
PHP_VERSION="7"
BUILD_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--php)
            PHP_VERSION="$2"
            shift 2
            ;;
        -a|--all)
            BUILD_ALL=true
            shift
            ;;
        -n|--name)
            IMAGE_PREFIX="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -p, --php VERSION    PHP version to build (7 or 8). Default: 7"
            echo "  -a, --all            Build all PHP versions (7 and 8)"
            echo "  -n, --name NAME      Docker image prefix name. Default: hybridfuzzer"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-p 7|8] [-a] [-n name]"
            exit 1
            ;;
    esac
done

if [[ "$BUILD_ALL" == true ]]; then
    php_versions=( "7" "8" )
else
    php_versions=( "$PHP_VERSION" )
fi

for version in "${php_versions[@]}"; do
    python3 ${DIR}/checkout.py ${version}
done

if [[ "$BUILD_ALL" == true ]]; then
    builds=( "base" "php7" "php8" )
else
    builds=( "base" "php${PHP_VERSION}" )
fi

buildtypes=( "build" "run" )

for b in "${builds[@]}"; do
    for btype in "${buildtypes[@]}"; do
        if docker build -t ${IMAGE_PREFIX}/${b}${btype} -f "${DIR}/${b}${btype}.Dockerfile" "${DIR}/../${b}"; then
            docker tag ${IMAGE_PREFIX}/${b}${btype} ${IMAGE_PREFIX}/${b}${btype}:latest
            printf "\033[32mSucessfully built ${b}${btype} \033[0m\n"
        else
            printf "\033[31mFailed to build ${b}${btype} \033[0m\n"
            exit 191
        fi
        if [[ "$b" == 'base' && "$btype" == 'build' ]]; then
            docker build -t ${IMAGE_PREFIX}/build-widash-x86 -f "${DIR}/build-widash-x86.dockerfile" "${DIR}/../${b}"
        fi
    done
done