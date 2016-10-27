manylinux wheels
================

Definition
----------

Manylinux wheels are described in `PEP 513 <https://www.python.org/dev/peps/pep-0513/>`_ -- *A Platform Tag for Portable Linux Built Distributions*

Two additional PEP are relevant to the subject:

- `PEP 425 <https://www.python.org/dev/peps/pep-0425/>`_ -- *Compatibility Tags for Built Distributions*
- `PEP 427 <https://www.python.org/dev/peps/pep-0427/>`_ -- *The Wheel Binary Package Format 1.0*

Using a wheel to install a software library, rather than starting from the source code, saves you from having to build and compile it. This speeds-up the procedure and removes the need to install a build system in the target environment.

A manylinux wheel with a platform tag *manylinux1_x86_64* and *manylinux1_i686* can be installed and used, with pip 8.1 and later, on the vast majority of desktop and server Linux distributions.

To achieve this large compatibility with linux distributions, the wheel should depend only on "old" symbol versions of a limited set of external shared library listed in PEP 513, and should depend only on a widely-compatible kernel `ABI <https://en.wikipedia.org/wiki/Application_binary_interface>`_. This can be achieved by building the wheel on a very old distribution, CentOS 5.11 being the official choice defined in PEP 513.

PyPA manylinux project
----------------------

CentOS 5 docker images
+++++++++++++++++++++++

The `Python Packaging Authority (PyPA) <https://www.pypa.io/>`_ maintains a *manylinux* project on github.com. This project provides two CentOS 5 docker images, a 64-bit image (x86-64) and a 32-bit image (i686), containing:

- CPython 2.6, 2.7, 3.3, 3.4, and 3.5, installed in ``/opt/python/<python tag>-<abi tag>`` -- e.g. ``/opt/python/cp27-cp27mu``
- Devel packages for all the libraries that PEP 513 allows you to assume are present on the host system
- The `auditwheel tool`_.


auditwheel tool
+++++++++++++++


``auditwheel`` is a command line tool to facilitate the creation of manylinux wheel packages containing pre-compiled binary extensions.

``auditwheel show``: shows external shared libraries that the wheel depends on (beyond the libraries included in the manylinux1 policy), and checks the extension modules for the use of versioned symbols that exceed the manylinux ABI.

``auditwheel repair``: copies these external shared libraries into the wheel itself, and automatically modifies the appropriate RPATH entries such that these libraries will be picked up at runtime.

The project repository is  on github: https://github.com/pypa/auditwheel

It is made available for installation on pypi: https://pypi.python.org/pypi/auditwheel

python-manylinux-demo
+++++++++++++++++++++

PyPA provides a demo project for building Python wheels for Linux with Travis-CI:
https://github.com/pypa/python-manylinux-demo

This sample project contains a C compile extension module that links to an external library (ATLAS, a linear algebra library).

The ``.travis.yml`` is configured to download the "official" CentOS 5 docker images and run a build script on them. This build script goes through the following steps for all python version available in the Cent OS image:

- install the required external library, as a system package with ``yum``
- compile the wheels with ``pip wheel``
- bundle external shared libraries into the wheel with ``auditwheel`` 
- install wheel and run the tests

This approach removes the need for installing *Docker* on your machine.


Using CentOS Docker images
--------------------------

Installing docker
+++++++++++++++++

You can start by checking if docker is not already installed on your linux computer by typing ``docker version`` in a terminal.

Next, you can go to the `docker website <https://docs.docker.com/engine/installation/>`_ to find installation instructions for all major linux distributions.

The main prerequisites is that you need a 64 bits (*x86_64*) architecture, with a linux kernel >= 3.10. You will also need a root or a sudo user account to install docker, to start the docker daemon and to use it.

The Debian 8 install described on `docker.com <https://docs.docker.com/engine/installation/linux/debian/>`_ consists of adding an apt repository entry, then install the ``docker-engine`` package with ``apt-get``. 

Run a command in a docker container
+++++++++++++++++++++++++++++++++++

To start the docker daemon, run::

    sudo service docker start

Test if docker is working::

    sudo docker run hello-world

If this fails with a message blaming your internet connection, you might need to set-up your proxy for docker. See https://docs.docker.com/engine/admin/systemd/#http-proxy for help. Alternatively, you can uncomment and edit the relevant line in ``/etc/default/docker`` and restart the docker daemon with ``sudo service docker restart``.

Before changing the proxy settings, you should first check if you have internal Docker registries that you need to contact without proxying. Use ``sudo docker images`` to find existing images. The first column lists the existing repositories that you might want to add to the ``NO_PROXY`` environment variable.

If some dark magic (e.g. remote administration tools) prevents you from succesfuly restarting the docker daemon, you can reboot your entire computer in a final desperate attempt to get docker to work.

Let's test the PyPA 64 bits CentOS image::

    sudo docker run --rm -v `pwd`:/io quay.io/pypa/manylinux1_x86_64 cp /etc/redhat-release /io/centos-release

The ``-v`` option bind mounts a volume on the image OS. In our case, we bind mount the local directory on the host machine (the result of the `pwd` command) on the ``/io`` path on the CentOS image. The result of this command is that the ``/etc/redhat-release`` file of the CentOS image is copied to the local directory on our computer.

The first time you run this command, ``docker`` downloads the 300 MB container file from the internet. The next time you use this image, it uses a local copy, so the execution will be muchfaster.

Every time you run a command on this image, docker creates a new *container*. This will quickly fill up all your disk space. Use the ``--rm`` option to automatically remove the container when it exits.

Open an interactive shell in a docker container
+++++++++++++++++++++++++++++++++++++++++++++++

You can start an interactive ``bash`` shell in a new container using the following command::

    sudo docker run --rm -v `pwd`:/io -i -t quay.io/pypa/manylinux1_x86_64 /bin/bash

The ``-i`` option stands for *interactive*: keep STDIN open.

The ``-t`` option allocates a `pseudo-TTY <https://en.wikipedia.org/wiki/Pseudoterminal>`_

Type ``exit`` to exit the container.

If you need to work on a regular basis with Cent OS docker containers, you can add following shortcuts to your ``.bashrc`` file::

    # docker shortcuts
    alias d='sudo docker run --rm -v ~/artifacts:/io -i -t'
    alias d32='d quay.io/pypa/manylinux1_i686'
    alias d64='d quay.io/pypa/manylinux1_x86_64'
    alias db32='d32 /bin/bash'
    alias db64='d64 /bin/bash'

    
