# How to build ClickHouse on Linux

Build should work on Linux Ubuntu 12.04, 14.04 or newer.
With appropriate changes, it should also work on any other Linux distribution.
The build process is not intended to work on Mac OS X.
Only x86_64 with SSE 4.2 is supported. Support for AArch64 is experimental.

To test for SSE 4.2, do

```bash
grep -q sse4_2 /proc/cpuinfo && echo "SSE 4.2 supported" || echo "SSE 4.2 not supported"
```

## Install Git and CMake

```bash
sudo apt-get install git cmake ninja-build
```

Or cmake3 instead of cmake on older systems.

## Install GCC 7

There are several ways to do this.

### Install from a PPA package

```bash
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-7 g++-7
```

### Install from sources

Look at [ci/build-gcc-from-sources.sh](https://github.com/yandex/ClickHouse/blob/master/ci/build-gcc-from-sources.sh)

## Use GCC 7 for builds

```bash
export CC=gcc-7
export CXX=g++-7
```

## Install required libraries from packages

```bash
sudo apt-get install libicu-dev libreadline-dev libssl-dev
```

## Checkout ClickHouse sources

To get the latest stable version:

```bash
git clone -b stable --recursive git@github.com:yandex/ClickHouse.git
# or: git clone -b stable --recursive https://github.com/yandex/ClickHouse.git

cd ClickHouse
```

For development, switch to the `master` branch.
For the latest release candidate, switch to the `testing` branch.

## Build ClickHouse

There are two build variants.

### Build release package

Install prerequisites to build Debian packages.

```bash
sudo apt-get install devscripts dupload fakeroot debhelper
```

Install the most recent version of Clang.

Clang is embedded into the ClickHouse package and used at runtime. The minimum version is 5.0. It is optional.

To install clang, see  [ci/build-clang-from-sources.sh](https://github.com/yandex/ClickHouse/blob/master/ci/build-clang-from-sources.sh)

You may also build ClickHouse with Clang for development purposes.
For production releases, GCC is used.

Run the release script:

```bash
rm -f ../clickhouse*.deb
./release
```

You will find built packages in the parent directory:

```bash
ls -l ../clickhouse*.deb
```

Note that usage of debian packages is not required.
ClickHouse has no runtime dependencies except libc, so it could work on almost any Linux.

Installing freshly built packages on a development server:

```bash
sudo dpkg -i ../clickhouse*.deb
sudo service clickhouse-server start
```

### Build to work with code

```bash
mkdir build
cd build
cmake ..
ninja
cd ..
```

To create an executable, run `ninja clickhouse`.
This will create the `dbms/programs/clickhouse` executable, which can be used with `client` or `server` arguments.

