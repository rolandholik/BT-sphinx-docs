
Quixote
=======

.. _quixote_trust_orchestrator:

Quixote -- the trust orchestrator
---------------------------------

TSEM Linux security module itself serves more as a "security module
infrastructure" rather than a standalone LSM.

For purposes of modeling :term:`TO` and :term:`TMA` are needed.

:term:`TO` and :term:`TMA` work together such that :term:`TMA` represents a
modeling algorithm which :term:`TO` models in a independent security modeling
namespace. The namespace is determined by location of :term:`TMA`.

As of writing of this document there are following :term:`TO` utilities --
:term:`TMA` implementations:

quixote -- kernel space

quixote-us -- user space

quixote-xen -- Xen based stub domain

quixote-sgx -- SGX enclave

quixote-sgx -- SGX enclave (unified binary)

quixote-mcu -- micro-controller

* quixote-export -- no :term:`TMA`, event export only

These :term:`TO` utilities represent reference implementation for deterministic
modeling, however TSEM is designed to be used with other implementations of
modeling algorithms and supervisory utilities. These implementations could be
oriented around e.g. machine learning algorithm.

Process/Container
-----------------

Process
~~~~~~~

When run in process mode a new shell is spawned in child process. The process
and all subordinate processes will be modeled by :term:`TO` and :term:`TMA`.
Which :term:`TO`/:term:`TMA` is used depends on which quixote implementation
(from list mentioned above) gets
used.

Container
~~~~~~~~~

When run in container mode the modeling is being done for OCI runc process --
once again :term:`TO`/:term:`TMA` is used based on which quixote implementation
is used for the modeling.

The runc container(s) used with quixote are specified in
/var/lib/Quixote/Magazine directory. Each folder in this directory represents a
so called bundle that contains configuration files necessary for runc container
start up.

**rootfs** -- subdirectory which contains the whole file tree the container is
based on 

**config.json** -- configuration files that specifies properties of the
container such as capabilities (C-list capabilities), mountpoints, enviroment
variables...

Usage principles
-------------------

As perviously mentioned, there are several "quixotes" -- quixote
implementations. However most of them follow these basic usage pattern.

Creating the model
~~~~~~~~~~~~~~~~~~

quixote(\|us\|xen\|sgx\|mcu) (-P\|) -w {model_name} -o {model_file}

-P indicates process mode --- modeled namespace is created inside a child process
-w sets the name of the workload, which is by default runc process, when used
with -P it sets the name of the process namespace
-o specifies the file where the model is to be output

Executing the model
~~~~~~~~~~~~~~~~~~~

quixote(\|us\|xen\|sgx\|mcu) (-P\|) -c {model_name} -m {model_file} (-e\|)

-P indicates process mode -- modeled namespace is created inside a child process
-w sets the name of the workload, which is by default runc process, when used
with -P it sets the name of the process namespace
-m specifies the file from which the model is to be read
-e if set, makes the model enforced -- in case of deviation from the model
defined in the *model_file* all following operations in the namespace will get
denied (EPERM signal)
