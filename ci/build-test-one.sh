#!/bin/bash

if [ -z "${VIRTUAL_ENV}" ] && [ -z "${GITHUB_WORKSPACE}" ] ; then
	echo "Required: use of a virtual environment."
	exit 1
fi

if [ -z "$1" ] ; then
	echo "Usage: $0 sample"
	echo "Where:"
	echo "  sample is the name in samples directory (e.g. cryptography)"
	exit 1
fi

set -x

# Get script directory
CI_DIR=$(dirname "${BASH_SOURCE[0]}")
# This script is on ci subdirectory
TOP_DIR=${CI_DIR}/..
# Get the real path in a compatible way (do not use realpath)
pushd $TOP_DIR
TOP_DIR=$(pwd)
popd

echo "Define variables"
BUILD_DIR=$(python -c "from sysconfig import get_platform as p, get_python_version as v; print(f'build/exe.{p()}-{v()}')")
TEST_SAMPLE=$1
TEST_PRECMD=./
if [ "${OSTYPE}" == "msys" ] ; then
    if [ -z "${GITHUB_WORKSPACE}" ] ; then
        TEST_PRECMD="mintty --hold always -e ./"
    fi
fi

pushd ${CI_DIR}
TEST_NAMES=( $(python build-test-json.py ${TEST_SAMPLE} app) )
TEST_REQUIRES=$(python build-test-json.py ${TEST_SAMPLE} req)
TEST_LINKS=$(python build-test-json.py ${TEST_SAMPLE} req2)
popd

set -e -x

echo "Install dependencies for ${TEST_SAMPLE} sample"
python -m pip install --upgrade pip
pip install --upgrade importlib-metadata setuptools wheel
if ! [ -z "${TEST_REQUIRES}" ] ; then
    echo "${TEST_REQUIRES}"
    pip install --upgrade ${TEST_REQUIRES}
    echo "Requirements installed: ${TEST_REQUIRES}"
fi
if ! [ -z "${TEST_LINKS}" ] ; then
    echo "${TEST_LINKS}"
    pip install ${TEST_LINKS}
    echo "Requirements installed: ${TEST_LINKS}"
fi

if ! cxfreeze --version 2>/dev/null ; then
    if [ -d "${TOP_DIR}/wheelhouse" ] ; then
        echo "Install cx-freeze from wheelhouse"
        pip install --no-index -f "${TOP_DIR}/wheelhouse" cx-freeze --no-deps
    fi
fi

# Check if the samples is in current directory or in a cx_Freeze tree
echo "Freeze ${TEST_SAMPLE} sample"
if [ -d "${TEST_SAMPLE}" ] ; then
    pushd ${TEST_SAMPLE}
else
    TEST_DIR=${TOP_DIR}/cx_Freeze/samples/${TEST_SAMPLE}
    if ! [ -d "${TEST_DIR}" ] ; then
        echo "Sample's directory not found"
        exit 1
    fi
    pushd $TEST_DIR
fi
python setup.py build_exe --silent --excludes=tkinter

echo "Run ${TEST_SAMPLE} sample"
cd $BUILD_DIR
for TEST_NAME in "${TEST_NAMES[@]}" ; do
    if [ -f "${TEST_NAME}" ] ; then
        ${TEST_PRECMD}${TEST_NAME}
    fi
    if [ "${TEST_SAMPLE}" == "simple" ] ; then
        echo "test - rename the executable"
        if [ "${OSTYPE}" == "msys" ] ; then
            cp hello.exe Test_Hello.exe
        else
            cp hello Test_Hello
        fi
        ${TEST_PRECMD}Test_Hello ação ótica côncavo peña
    fi
done

popd
