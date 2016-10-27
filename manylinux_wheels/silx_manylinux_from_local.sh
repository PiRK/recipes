#!/bin/bash
######################################################################
# Script building manylinux silx wheels
# The silx sources (main setup.py) must be in the current working directory.
#
# Run it on a manylinux CentOS docker image.
# For 64 bits wheels, run:
#    sudo docker run --rm -v `pwd`:/io quay.io/pypa/manylinux1_x86_64 /io/scriptname.sh
# For 32 bits wheels, run:
#    sudo docker run --rm -v `pwd`:/io quay.io/pypa/manylinux1_i686 /io/scriptname.sh
#
# The option "-v `pwd`:/io" bind mounts the local directory on the
# host to "/io" on the docker container. The wheels are saved in
# ./build/wheelhouse.
###################################################################### 

set -e -x

# uncomment and complete the following lines with your network
# proxy address if necessary:
#export http_proxy="http://proxy:port"
#export https_proxy="http://proxy:port"
#cat > /etc/yum/yum.conf <<EOF
#[main]
#proxy=http://proxy:port
#EOF

# x86_64 or i686
arch=`arch`

# Install a system package required by our library
# yum --disablerepo="*" --enablerepo="epel" install -y hdf5-devel.${arch}  hdf5.${arch}

# delete existing silx wheels
rm -Rf /io/build/wheelhouse/silx-*_${arch}.whl

# build silx wheels
for PYBIN in /opt/python/cp27-*/bin /opt/python/cp34-*/bin  /opt/python/cp35-*/bin; do
    # pyversion 2.7, 3.4 or 3.5
    pyversion=`${PYBIN}/python -V 2>&1 | awk '{print $2}' | cut -c1-3`
    ${PYBIN}/pip install numpy
    # remove previous builds
    rm -Rf /io/build/lib.linux-${arch}-${pyversion}
    ${PYBIN}/pip wheel /io/ -w /wheelhouse
done

# include libraries and move new wheels to ./build/wheelhouse/
for whl in /wheelhouse/silx*_${arch}.whl; do
    auditwheel repair $whl -w /io/build/wheelhouse/
done

# run tests
cat > /silx_tests.py <<EOF
import silx.test
silx.test.run_tests()
EOF

for PYBIN in /opt/python/cp27-*/bin /opt/python/cp34-*/bin  /opt/python/cp35-*/bin; do
    # test
    ${PYBIN}/pip install h5py
    ${PYBIN}/pip install silx --no-index -f /io/build/wheelhouse
    WITH_QT_TEST=False ${PYBIN}/python /silx_tests.py
done
