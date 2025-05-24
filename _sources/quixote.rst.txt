
Quixote
=======

.. _quixote_trust_orchestrator:

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
   rather for **event exporting** and **interrogation of modeling **.
 
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
   writing under heavy development and some functionalities get accidentally
   broken as new refactor/feature gets released.

quixote
~~~~~~~
This implementation handles the modeling of events with :term:`TMA` inside
kernel. This approach brings least overhead to the modeling process as there is
no need to continually export events for evaluation into the user space. On the
other hand it requires the model (:term:`TMA`) to be implemented inside kernel
or using loadable kernel module. Therefore it can a bit more complicated to
introduce new model.

Current default --- and the only model available at the time of writing --- 
is implemented in the root directory of :term:`TSEM` in the kernel.

Command line flags
..................

.. list-table::
   :widths: 10 20 60
   :header-rows: 1

   - * Flag
     * Name
     * Description
   - * ``-P``
     * Process mode
     * Runs a workload with security modeling namespace created inside a bash
       process. 
   - * ``-S``
     * Show mode
     * Shows contents of Magazine directory, so it basically shows available
       runc bundles. 
   - * ``-e``
     * Enforce
     * Sets the security coefficient map to be enforced (must be used with
       ``-m`` and the predefined security map must be **sealed**). 
   - * ``-t``
     * Trajectory
     * Outputs events as *JSON* formatted lines in stead of security state
       coefficients (must be used with ``-o``). 
   - * ``-u``
     * Current namespace
     * Specifies if the modeling security namespace used should be based on
       current user namespace, where the process is running in stead of the
       initial user namespace. 
   - * ``-X``
     * Execute mode
     * In execute mode there isn't namespace setup in container or process
       (running bash), but only one program with its arguments gets run in the
       created security namespace. The name of the program with its arguments
       are specified as the very last argument to the quixote utility as
       follows: ``-- {name of the program} {its arguments}``. 
   - * ``-M``
     * Model (alternative)
     * Allows usage of alternative model for event modeling. At the time of
       writing there is only one model implemented, therefore this argument
       doesn't have its purpose fulfilled for now. 
   - * ``-d``
     * Debug
     * There are debug statements in the Quixote codebase. These get printed
       into a file if this flag is set with pathname of the file as argument. 
   - * ``-h``
     * Hash digest
     * Sets hash function to be used for generation of security state
       coefficients. Current default is sha256. Takes name of hash function
       (compiled into the kernel) as argument. 
   - * ``-m``
     * Model
     * Specifies which model the workload is going to be modeled against. 
   - * ``-n``
     * Cache size
     * Specifies number of preallocated structures holding data for security
       events happening in atomic context. One should not have to worry too much
       about this number, since the default (32 structures) should suffice for
       most use cases. 
   - * ``-o``
     * Output file
     * Specifies that a output file, where the model of current workload is to
       be saved. Takes string argument with pathname to the desired file. 
   - * ``-w``
     * Workload name
     * Specifies name of the workload that is to be run. 


More visual usage examples
..........................

Example 0: Show runc bundles
,,,,,,,,,,,,,,,,,,,,,,,,,,,,

As mentioned in the above table, when used with ``-S``, ``quixote`` lists
available runc bundle directories that hold all the necessary stuff for
launching a runc container.

.. code-block:: console

   # quixote -S

If the output of this command does not show any bundle directories, you might
want to create some. Otherwise you will only be able to use the Process/Execute
mode.

Example 1: Container workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The following is the "most basic way" to create a workload. It creates a
workload in free modeling mode. Which means it does not get evaluated against
any predefined model (set of security state coefficients). This Model can be
inspected using quixote-console (described in section below).

When ``-P`` isn't specified, ``quixote`` defaults to container mode, which means the
process is executed inside :term:`OCI` runc container. This requires runc bundle
directory with name corresponding to the workload name to be placed inside
``/var/lib/Quixote/Magazine/`` directory. 

.. code-block:: console

   # quixote -w test_container_workload

When ``-o`` flag gets used, the security modeling states get output to file
specified as argument to the flag.

.. code-block:: console

   # quixote -w test_container_workload -o test.model

These coefficients can than be used as model for the workload. This way any
violations of the model get captured and can be viewed using the
quixote-console.

.. _ref-seal-cont-mod:

.. code-block:: console

   # quixote -w test_container_workload -m test.model

The model can also be enforced using ``-e`` flag. Any violations will now lead
to the process being evaluated as untrusted and its execution will get denied.

.. code-block:: console

   # quixote -w test_container_workload -m test.model -e

.. warning::
   In case of running multiple workloads at once, each has to have unique name
   as the name also serves as a identification for management sockets created at
   ``/var/lib/Quixote/mgmt/`` in the linux host file system. 

Example 2: Process workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,

When used with additional ``-P`` flag, compared to previous example, ``quixote``
launches workload in a subordinate ``bash`` process.

.. code-block:: console

   # quixote -P -w test_container_workload

When ``-o`` flag gets used, the security modeling states get output to file
specified as argument to the flag.

.. code-block:: console

   # quixote -P -w test_container_workload -o test.model

These coefficients can than be used as model for the workload. This way any
violations of the model get captured and can be viewed using the
quixote-console.

.. code-block:: console

   # quixote -P -w test_container_workload -m test.model

The model can also be enforced using ``-e`` flag. Any violations will now lead
to the process being evaluated as untrusted and its execution will get denied.

.. code-block:: console

   # quixote -w test_container_workload -m test.model -e

Example 3: Execute workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,

One can execute specific program in :term:`TSEM` security namespace using ``-X``
flag in following way.

This runs ``ls`` command itself in a security namespace. It does not have much
use except analysis though.

.. code-block:: console

   # quixote -X test_container_workload -- ls

Its power can be seen a little bit better when a model definition is created.

.. code-block:: console

   # quixote -X test_container_workload -o test_model -- ls

Now when trying to list contents of ``/`` directory, we get "Permission denied".

.. code-block:: console

   # quixote -X test_container_workload -m test_model -e -- ls /

However running listing of current directory works just fine.

.. code-block:: console

   # quixote -X test_container_workload -m test_model -e -- ls


.. warning::
   In case of running multiple workloads at once, each has to have unique name
   as the name also serves as a identification for management sockets created at
   ``/var/lib/Quixote/mgmt/`` in the linux host file system. 


quixote-us
~~~~~~~~~~
This implementation handles the modeling of events with :term:`TMA` in user
space. This approach brings more overhead to the modeling process as the
security event descriptions have to be exported to to userspace for further
processing. However, its (:term:`TMA`) is implemented in userspace, which makes
is easier for new models to be introduced as no kernel code recompilation is
needed. It does require recompilation of the quixote-us utility because it is
implemented in its source directory.

Command line flags
..................

.. list-table::
   :widths: 10 20 60
   :header-rows: 1

   - * Flag
     * Name
     * Description
   - * ``-P``
     * Process mode
     * Runs a workload with security modeling namespace created inside a bash
       process. 
   - * ``-S``
     * Show mode
     * Shows contents of Magazine directory, so it basically shows available
       runc bundles. 
   - * ``-e``
     * Enforce
     * Sets the security coefficient map to be enforced (must be used with
       ``-m`` and the predefined security map must be **sealed**). 
   - * ``-t``
     * Trajectory
     * Outputs events as *JSON* formatted lines in stead of security state
       coefficients (must be used with ``-o``). 
   - * ``-u``
     * Current namespace
     * Specifies if the modeling security namespace used should be based on
       current user namespace, where the process is running in stead of the
       initial user namespace. 
   - * ``-X``
     * Execute mode
     * In execute mode there isn't namespace setup in container or process
       (running bash), but only one program with its arguments gets run in the
       created security namespace. The name of the program with its arguments
       are specified as the very last argument to the quixote utility as
       follows: ``-- {name of the program} {its arguments}``. 
   - * ``-d``
     * Debug
     * There are debug statements in the Quixote codebase. These get printed
       into a file if this flag is set with pathname of the file as argument. 
   - * ``-h``
     * Hash digest
     * Sets hash function to be used for generation of security state
       coefficients. Current default is sha256. Takes name of hash function
       (compiled into the kernel) as argument. 
   - * ``-m``
     * Model
     * Specifies which model the workload is going to be modeled against. 
   - * ``-n``
     * Cache size
     * Specifies number of preallocated structures holding data for security
       events happening in atomic context. One should not have to worry too much
       about this number, since the default (128 structures) should suffice for
       most use cases. 
   - * ``-o``
     * Output file
     * Specifies that a output file, where the model of current workload is to
       be saved. Takes string argument with pathname to the desired file. 
   - * ``-w``
     * Workload name
     * Specifies name of the workload that is to be run. 

.. note::
   The available flags are almost the same as for ``quixote``. Except that
   ``-M`` is not used here because there the model is implemented as part of the
   userspace utility. And the size of cache is increased to 128, as it is also
   used to store event descriptions before exporting them to userspace.


Concrete usage examples
.......................

The usage is pretty much identical to ``quixote`` except the different
executable name.

Example 0: Show runc bundles
,,,,,,,,,,,,,,,,,,,,,,,,,,,,

As mentioned in the above table, when used with ``-S``, ``quixote-us`` lists
available runc bundle directories that hold all the necessary stuff for
launching a ``runc`` container.

.. code-block:: console

   # quixote-us -S

If the output of this command does not show any bundle directories, you might
want to create some. Otherwise you will only be able to use the Process/Execute
mode.

Example 1: Container workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The following is the "most basic way" to create a workload. It creates a
workload in free modeling mode. Which means it does not get evaluated against
any predefined model (set of security state coefficients). This Model can be
inspected using ``quixote-console`` (described in section below).

When ``-P`` isn't specified, ``quixote-us`` defaults to container mode, which means the
process is executed inside :term:`OCI` runc container. This requires runc bundle
directory with name corresponding to the workload name to be placed inside
``/var/lib/Quixote/Magazine/`` directory. 

.. code-block:: console

   # quixote-us -w test_container_workload

When ``-o`` flag gets used, the security modeling states get output to file
specified as argument to the flag.

.. code-block:: console

   # quixote-us -w test_container_workload -o test.model

These coefficients can than be used as model for the workload. This way any
violations of the model get captured and can be viewed using the
quixote-console.

.. code-block:: console

   # quixote-us -w test_container_workload -m test.model

The model can also be enforced using ``-e`` flag. Any violations will now lead to
the process being evaluated as untrusted and its execution will get denied.

.. code-block:: console

   # quixote-us -w test_container_workload -m test.model -e

.. warning::
   In case of running multiple workloads at once, each has to have unique name
   as the name also serves as a identification for management sockets created at
   ``/var/lib/Quixote/mgmt/`` in the linux host file system. 

Example 2: Process workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,

When used with additional ``-P`` flag, compared to previous example, ``quixote``
launches workload in a subordinate ``bash`` process.

.. code-block:: console

   # quixote-us -P -w test_container_workload

When ``-o`` flag gets used, the security modeling states get output to file
specified as argument to the flag.

.. code-block:: console

   # quixote-us -P -w test_container_workload -o test.model

These coefficients can than be used as model for the workload. This way any
violations of the model get captured and can be viewed using the
quixote-console.

.. code-block:: console

   # quixote-us -P -w test_container_workload -m test.model

The model can also be enforced using ``-e`` flag. Any violations will now lead
to the process being evaluated as untrusted and its execution will get denied.

.. code-block:: console

   # quixote-us -w test_container_workload -m test.model -e

Example 3: Execute workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,

One can execute specific program in :term:`TSEM` security namespace using ``-X``
flag in following way.

This runs ``ls`` command itself in a security namespace. It does not have much
use except analysis though.

.. code-block:: console

   # quixote-us -X test_container_workload -- ls

Its power can be seen a little bit better when a model definition is created.

.. code-block:: console

   # quixote-us -X test_container_workload -o test_model -- ls

Now when trying to list contents of ``/`` directory, we get "Permission denied".

.. code-block:: console

   # quixote-us -X test_container_workload -m test_model -e -- ls /

However running listing of current directory works just fine.

.. code-block:: console

   # quixote-us -X test_container_workload -m test_model -e -- ls

.. warning::
   In case of running multiple workloads at once, each has to have unique name
   as the name also serves as a identification for management sockets created at
   ``/var/lib/Quixote/mgmt/`` in the linux host file system. 


quixote-export
~~~~~~~~~~~~~~
This implementation doesn't do modeling --- has no associated :term:`TMA`. It is
used only for exporting of security events. The events can be exported to
specified file or sent to a MQTT server for broadcasting. The MQTT option is
meant to be used for system monitoring purposes (such as :term:`HIDS`) or
collection of data for for development of machine learning based security
models.

.. note::
   As of right now there is no such utility that would implement machine
   learning models directly. It's meant to lay the groundwork for future
   developers of such systems.

Command line flags
..................

.. list-table::
   :widths: 10 20 60
   :header-rows: 1

   - * Flag
     * Name
     * Description
   - * ``-P``
     * Process mode
     * Runs a workload with security modeling namespace created inside a bash
       process. 
   - * ``-R``
     * Root mode
     * Exports security events from root security modeling namespace.
   - * ``-S``
     * Show mode
     * Shows contents of Magazine directory, so it basically shows available
       runc bundles. 
   - * ``-X``
     * Execute mode
     * In execute mode there isn't namespace setup in container or process
       (running bash), but only one program with its arguments gets run in the
       created security namespace. The name of the program with its arguments
       are specified as the very last argument to the quixote utility as
       follows: ``-- {name of the program} {its arguments}``. 
   - * ``-f``
     * Follow
     * By default exporting from root modeling namespace exports only events
       that occured up untill the point of calling the export from the point of
       last export. Using this follow option drops into a bash shell after
       exporting the accumulated events and continues modeling in the shell.
   - * ``-u``
     * Current namespace
     * Specifies if the modeling security namespace used should be based on
       current user namespace, where the process is running in stead of the
       initial user namespace. 
   - * ``-M``
     * Model (alternative)
     * Allows usage of alternative model for event modeling. At the time of
       writing there is only one model implemented, therefore this argument
       doesn't have its purpose fulfilled for now. 
   - * ``-b``
     * Broker
     * In case ``quixote-export`` is used with MQTT client, this sets the
       :term:`MQTT` broker IP address. It can be IP address directly or
       :term:`FQDN` or hostname.
   - * ``-d``
     * Debug
     * There are debug statements in the Quixote codebase. These get printed
       into a file if this flag is set with pathname of the file as argument. 
   - * ``-h``
     * Hash digest
     * Sets hash function to be used for generation of security state
       coefficients. Current default is sha256. Takes name of hash function
       (compiled into the kernel) as argument. 
   - * ``-n``
     * Cache size
     * Specifies number of preallocated structures holding data for security
       events happening in atomic context. One should not have to worry too much
       about this number, since the default (32 structures) should suffice for
       most use cases. 
   - * ``-o``
     * Output file
     * Specifies that a output file, where the model of current workload is to
       be saved. Takes string argument with pathname to the desired file. 
   - * ``-q``
     * Queue size
     * Specifies queue size (numbers of events) ``quixote-export`` uses for root
       security namespace exporting. 
   - * ``-p``
     * Port
     * Specifies the :term:`MQTT` port, in case the output is routed to the
       :term:`MQTT`. Default is set to 1883 (so this flag does not have to be
       used necessarily).
   - * ``-t``
     * Topic
     * When used with :term:`MQTT` this flag's argument specifies the topic to
       which the events will be sent. 
   - * ``-w``
     * Workload name
     * Specifies name of the workload that is to be run.


More visual usage examples
..........................

With ``quixote-export`` the basic notion for usage remains similar. However
there are things that change, since it's used for exporting of events, not
modeling.

The usage is pretty much identical to ``quixote`` except the different
executable name.

Example 0: Show runc bundles
,,,,,,,,,,,,,,,,,,,,,,,,,,,,

As mentioned in the above table, when used with ``-S``, ``quixote`` lists
available runc bundle directories that hold all the necessary stuff for
launching a ``runc`` container.

It's likely unintended "feature", but ``quixote-export`` in comparison to
previous Quixote implementations requires specification of output file or
:term:`MQTT` broker. The file doesn't need to exist, nor will it be created...

.. code-block:: console

   # quixote-export -S -o test.exp


If the output of this command does not show any bundle directories, you might
want to create some. Otherwise you will only be able to use the Process/Execute
mode.

Example 1: Exporting to a file
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The following is the "most basic way" to create export of a workload. It creates a
workload and outputs all of its events to the file specified by the ``-o`` flag.

When ``-P`` isn't specified, ``quixote-export`` defaults to container mode,
which means the process is executed inside :term:`OCI` runc container. This
requires runc bundle directory with name corresponding to the workload name.

.. code-block:: console

   # quixote-export -w test_container_workload -o test.exp

Example 2: Exporting to a MQTT broker
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Exporting to a file isn't the most impressive thing ``-quixote-export`` can do
--- ``quixote`` can do the same. Exporting to a :term:`MQTT` broker is what
makes ``quixote-export`` interesting.

.. code-block:: console

   # quixote-export -w test_container_workload -b broker.dm -t test -p 10902

Here we are exporting security events from our container workload to
:term:`MQTT` broker with topic ``test`` on port 10902. One can use any
:term:`MQTT` client e.g. ``mosquito`` to connect to the broker and listen on the
topic.

.. note::
   ``broker.dm`` is :term:`FQDN` for :term:`MQTT` broker. IP can be used
   directly, if the broker does not have a :term:`FQDN`.

Example 3: Exporting from a root modeling namespace
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

In the above example we were exporting from a subordinate security modeling
namespace.

Here we demonstrate how to use export events from root modeling namespace.

.. code-block:: console

   # quixote-export -R -w test -b broker.dm -t test

We are again exporting to the broker ``broker.dm`` to ``test`` topic. We have
not defined port this time --- we are exporting on the default port (1883). This
outputs only the events generated from system start or last event export.

.. code-block:: console

   # quixote-export -R -w test -b broker.dm -t test

Following will output will generate all events from system start or last event
export and drop a bash shell where the modeling continues.


quixote-console
~~~~~~~~~~~~~~~
This implementation doesn't do modeling --- has no associated :term:`TMA`. It
is used for interrogation of :term:`TMA`\s. It has to be run on the same system
as the interrogated *quixote* because it communicates with the *quixote* using
management sockets located in ``/var/lib/Quixote/mgmt``.

Command line flags
..................

.. list-table::
   :widths: 10 20 60
   :header-rows: 1

   - * Flag
     * Name
     * Description
   - * ``NONE``
     * No flag
     * When called with no flag, ``quixote-console`` prints list of running
       workloads which can be interrogated [#]_.
   - * ``-E``
     * Output events
     * Outputs log of events divergent from predefined sealed map --- only
       system call name and name of process which called the system call in
       *JSON* format.
   - * ``-F``
     * Output forensics
     * Makes ``quixote-console`` output security events that violate the
       predefined and sealed map for the interrogated workload.
   - * ``-M``
     * Output model
     * Outputs model (security state coefficients). In case a predefined map of
       security state coefficients is defined and is in sealed mode, it only
       outputs the predefined map.
   - * ``-S``
     * Output state
     * Prints security state coefficient the interrogated workload is currently
       in.
   - * ``-T``
     * Output trajectory
     * If run without predefined map --- outputs full model (all its events).

       If run with predefined **non-sealed** map --- outputs events divergent
       from the predefined model.

       If run with predefined **sealed** map --- outputs empty model.
   - * ``-c``
     * Count output
     * If used with ``-T`` or ``-F`` count of each event in the gets output in
       stead of the list of events. The order of the events is preserved ---
       this can be used for analysis purposes.
   - * ``-p``
     * Prefix
     * When used in combination with ``-T`` ``-s`` or ``-F`` ``-s`` it outputs
       states with prepended "state" keyword.
   - * ``-s``
     * Coefficient output 
     * If used with ``-T`` or ``-F`` coefficients get output in stead of
       security events.
   - * ``-u``
     * Update
     * Outputs updated security map (security state coefficients) with
       security state coefficients generated by the violations of the predefined
       map of the interrogated workload. **Has to be used with** ``-M``
       **flag.**
   - * ``-w``
     * Workload name
     * Specifies name of the workload that is to be interrogated. This flag takes
       string argument with the name. 

.. [#] It is mentioned in official documentation that it should drop a "Quixote
   Shell" which would accept interrogation commands, but at the time of writing
   this feature is "dead code" --- it is implemented, but can't be reached in
   the workflow of the code.

More visual usage examples
..........................

With ``quixote-console`` has a bit simpler usage, since it's used for workload
interrogation.

Example 0: Show runc bundles and process sockets
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Launching just ``quixote-console`` itself will list bundle directories in
``/var/lib/Quixote/Magazine`` (or even other than bundle, but those are supposed
to be there) and sockets for Process/Execute workloads.

.. code-block:: console

   # quixote-console 

Example 1: Output current workload state
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

To output just the state the workload is currently in.

.. code-block:: console

   # quixote-console -w test -S

This outputs just the state value for current workload state. The ``state`` is
not prepended even if ``-p`` is used.

Example 2: Output current model
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Following outputs current model definition with all states that happened during
the workload execution. If a sealed model was previously loaded (e.g.
:ref:`here <ref-seal-cont-mod>`) only the loaded model gets output.

.. code-block:: console

   # quixote-console -w test -M

In case a model with all events is desired to be output in **sealed** mode e.g.
for back "propagation" --- relaunching the workload with the updated model, so
that previous model violations are included --- do the following.

.. code-block:: console

   # quixote-console -w test -M -u

Example 3: Output trajectory
,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Outputs security event descriptions with following logic:
    - If run in **free modeling** with **no predefined** security event map:
        * The full model --- all security events triggered.
    - If run in **free modeling** with **predefined** security event map:
        * The full model --- outputs events divergent from the predefined model.
    - If run in **sealed** mode with **predefined** security event map:
        * Empty output

.. code-block:: console

   # quixote-console -w test -T

If states are desired in stead of *JSON* event descriptions, run following.

.. code-block:: console

   # quixote-console -w test -T -s

If the output states are intended to be used for e.g. model enforcement in the
future, following outputs the stated with ``state `` prepended to each state
coefficient.

.. code-block:: console

   # quixote-console -w test -T -s -p


*quixote-sgx* 
~~~~~~~~~~~~~

*Doesn't compile at the time of writing.* 

*quixote-mcu*
~~~~~~~~~~~~~
*Doesn't compile at the time of writing.* 

*quixote-xen*
~~~~~~~~~~~~~
*Doesn't compile at the time of writing.* 
