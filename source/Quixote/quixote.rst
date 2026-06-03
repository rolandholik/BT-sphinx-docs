
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

For purposes of modeling and policy enforcement :term:`TMA` and :term:`TO` are
needed, respectively.

:term:`TO` and :term:`TMA` work together such that :term:`TMA` implements a
modeling algorithm and policies. :term:`TO` --- Quixote utilities --- coordinate
:term:`TMA` with the kernel. :term:`TO` sets up a modeling namespace
(**internal** or **external**), runs a workload, handles communication between
:term:`TMA` and userspace tool sending management commands (e.g. from
``quixote-console``).

When modeling in **internal** namespace, the security events get processed
in the kernel spcae, when modeling in **external** namespace, security events
get sent to the orchestrator in userspace (e.g. ``quixote-us``). The namespace
is determined by location of :term:`TMA`.

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

When run in process mode a new shell is spawned in a child process. The process
and all subordinate processes will be modeled by a Quixote utility and an
:term:`TMA`. Which :term:`TO`/:term:`TMA` is used depends on which Quixote
implementation (from table shown above) gets used.

.. note::
   Subordinate security namespaces (all namespaces except root) are
   non-hierarchical. Which means it isn't possible to one run Quixote utility
   implementation inside another.

Container
~~~~~~~~~

When run in container mode, modeling is performed for the :term:`OCI` ``runc``
process, using :term:`TO` and :term:`TMA` which are determined by the *quixote*
implementation.

The ``runc`` container(s) used with the Quixote utility are specified in
*/var/lib/Quixote/Magazine* directory. Each folder in this directory represents
a so called bundle that contains configuration files necessary for a ``runc``
container start up.

**rootfs** -- subdirectory which contains the whole filesystem tree the
container is based on 

**config.json** -- configuration file that specifies properties of the
container such as capabilities (C-list capabilities), mountpoints, environment
variables...

Usage principles
----------------

As previously mentioned, there are several "quixotes" --- Quixote utility
implementations. However most of them follow these basic usage patterns.

Creating model (map)
~~~~~~~~~~~~~~~~~~~~

``quixote-`` (\| ``us`` \| ``xen``\| ``sgx``\| ``mcu``) (``-P``\|) ``-w`` {model_name} ``-o`` {model_file}

``-P`` indicates process mode --- modeled namespace is created inside a child
process ``-w`` sets the name of the workload, which is by default ``runc``
process, when used with ``-P`` the ``-w`` sets the name of the process namespace
``-o`` specifies the file where the model is to be output.

Executing the model
~~~~~~~~~~~~~~~~~~~

``quixote-`` (\| ``us`` \| ``xen`` \| ``sgx`` \| ``mcu``) (``-P``\|) ``-w`` {model_name} ``-m`` {model_file} (``-e``\|)

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

Six additional Quixote utilities exist, though not all are currently testable
due to a non-functional state. At present, only implementations compiled using
the default make configuration are functional. For demonstration purposes, these
functional implementations adhere to the same usage principles as the others and
offer the greatest potential for real use adoption, because of their suitability
for a wider range of computing environments.

.. note::
   These non-functional implementations were allegedly previously compatible with
   earlier :term:`TSEM` releases. However, ongoing development of userspace
   utilities and :term:`TSEM` itself has resulted in these implementations falling
   behind, causing compilation errors.

.. warning::
   The flag descriptions outline intended functionality, however, due to ongoing
   development, actual behavior may deviate a bit. Features are subject to
   change or accidental breakage with new refactorings or features.


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
