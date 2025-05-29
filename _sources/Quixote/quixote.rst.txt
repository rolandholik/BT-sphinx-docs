
Quixote
=======

.. _quixote_trust_orchestrator:

.. toctree::
   :hidden:
   :maxdepth: 3

   quixote_ker
   quixote_us
   quixote_export
   quixote_console


Quixote -- the trust orchestrator
---------------------------------

:term:`TSEM` Linux security module itself serves more as a "security module
infrastructure" rather than a standalone :term:`LSM`.

For purposes of modeling :term:`TO` and :term:`TMA` are needed.

:term:`TO` and :term:`TMA` work together such that :term:`TMA` represents a
modeling algorithm which :term:`TO` models in a independent security modeling
namespace --- **internal** or **external**. When modeling in **internal**
namespace, the security events get processed inside the kernel, when modeling in
**external** namespace, security events get sent to orchestrator in userspace.
The namespace is determined by location of :term:`TMA`.

As of writing of this document there are following :term:`TO` utilities --
:term:`TMA` implementations:

.. list-table::
   :widths: 15 20
   :header-rows: 1

   - * Name
     * TMA location
   - * ``quixote``
     * kernel space
   - * ``quixote-us``
     * user space 
   - * ``quixote-xen``
     * Xen based stub domain 
   - * ``quixote-sgx``
     * Intel :term:`SGX` enclave 
   - * ``quixote-mcu``
     * micro-controller


.. note::
   There are also two "quixote" utilities that aren't be used for modeling, but
   rather for **event exporting** and **interrogation of modeling**.
 
    .. list-table::
       :widths: 15 20
       :header-rows: 1

       - * Name
         * Purpouse
       - * ``quixote-export``
         * Exporting of security events from :term:`TMA`.
       - * ``quixote-console``
         * Interrogating :term:`TO`/:term:`TMA`.


These :term:`TO` utilities represent reference implementation for deterministic
modeling, however :term:`TSEM` is designed to be used with other implementations
of modeling algorithms and supervisory utilities. These implementations could be
oriented around e.g. machine learning algorithms.

Process/Container
-----------------

Process
~~~~~~~

When run in process mode a new shell is spawned in child process. The process
and all subordinate processes will be modeled by :term:`TO` and :term:`TMA`.
Which :term:`TO`/:term:`TMA` is used depends on which Quixote implementation
(from table shown above) gets used.

.. note::
   Subordinate security namespaces (all namespaces except root) are
   non-hierarchical. Which means it isn't possible to one run Quixote
   implementation inside another.

Container
~~~~~~~~~

When run in container mode the modeling is being done for :term:`OCI` runc
process -- once again :term:`TO`/:term:`TMA` is used based on which quixote
implementation is used for the modeling.

The runc container(s) used with *quixote* are specified in
``/var/lib/Quixote/Magazine`` directory. Each folder in this directory
represents a so called bundle that contains configuration files necessary for
runc container start up.

**rootfs** -- subdirectory which contains the whole file tree the container is
based on 

**config.json** -- configuration file that specifies properties of the
container such as capabilities (C-list capabilities), mountpoints, environment
variables...

Usage principles
----------------

As previously mentioned, there are several "quixotes" --- quixote
implementations. However most of them follow these basic usage patterns.

Creating model (map)
~~~~~~~~~~~~~~~~~~~~

``quixote`` (\| ``us`` \| ``xen``\| ``sgx``\| ``mcu``) (``-P``\|) ``-w`` {model_name} ``-o`` {model_file}

``-P`` indicates process mode --- modeled namespace is created inside a child
process ``-w`` sets the name of the workload, which is by default ``runc``
process, when used with ``-P`` the ``-w`` sets the name of the process namespace
``-o`` specifies the file where the model is to be output.

Executing the model
~~~~~~~~~~~~~~~~~~~

``quixote`` (\| ``us`` \| ``xen`` \| ``sgx`` \| ``mcu``) (``-P``\|) ``-w`` {model_name} ``-m`` {model_file} (``-e``\|)

``-P`` indicates process mode --- modeled namespace is created inside a child
process ``-w`` sets the name of the workload, which is by default ``runc``
process. When used with ``-P`` the ``-w`` sets the name of the process namespace
``-m`` [#]_ specifies the file from which the model is to be read ``-e`` if set,
makes the model enforced --- in case of deviation from the model defined in the
*model_file* all following operations in the namespace will get denied
(``-EPERM`` signal).

.. [#] Without the ``-m`` the modeling isn't done against any reference model
   therefore ``-e`` can't be used without ``-m``.


Detailed description
--------------------
There are more Quixote implementations, or perhaps more accurately said more
:term:`TMA` implementations, however Not all of them can be tested currently.
Because of their, at the time of writing non-functional state. Basically the
only ones that worked were the implementations that get compiled in the default
``make`` configuration. For demonstration purposes, it should not make much of a
difference as they follow the same usage principles as the functioning ones and
have the most potential for mass adoption (if such thing ends up happening).

.. note::
   The non-functional implementations were allegedly functional at some point
   with earlier :term:`TSEM` releases, but since the userspace utilities as well
   as :term:`TSEM` are under constant development, these fell behind the new
   functionalities in :term:`TSEM` and Quixote codebase which made them error
   out during compilation the time of writing.

.. warning::
   Descriptions of the flags below describe their intended functionality,
   however not all of them really work in the desired fashion. As mentioned in
   note above, this is caused by the fact that the utilities are, at the time of
   writing under heavy development and some functionalities might get
   accidentally broken as new refactor/feature gets released.


quixote 
~~~~~~~

See :ref:`quixote <quixote_ker>` for more detailed description.

quixote-us
~~~~~~~~~~

See :ref:`quixote-us <quixote_ker>` for more detailed description.

quixote-export
~~~~~~~~~~~~~~~

See :ref:`quixote-export <quixote_export>` for more detailed description.

quixote-console 
~~~~~~~~~~~~~~~

See :ref:`quixote-console <quixote_console>` for more detailed description.

----

.. role:: red
   :class: red-text

quixote-sgx
~~~~~~~~~~~

:red:`*Doesn't compile at the time of writing.*`

*quixote-mcu*
~~~~~~~~~~~~~
:red:`*Doesn't compile at the time of writing.*`

*quixote-xen*
~~~~~~~~~~~~~
:red:`*Doesn't compile at the time of writing.*`
