#!/bin/bash
######################################################################
# Script building manylinux silx wheels
# The silx sources are dowloaded from the git repository
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

git clone https://github.com/silx-kit/silx.git
cd silx

# build silx wheels
for PYBIN in /opt/python/cp27-*/bin /opt/python/cp34-*/bin  /opt/python/cp35-*/bin; do
    ${PYBIN}/pip install numpy
    # put initial wheels in /wheelhouse
    ${PYBIN}/pip wheel . -w /wheelhouse
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
