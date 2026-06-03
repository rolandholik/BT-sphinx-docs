
quixote
=======

.. _quixote_ker:

This implementation handles the modeling of events with :term:`TMA` inside the
kernel. This approach brings the least overhead to the modeling process as there
is no need to continually export events for evaluation into the user space. On
the other hand it requires new models (:term:`TMA`) to be implemented inside
kernel or using loadable kernel module. Therefore it can be a bit more
complicated to introduce a new model.

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
     * Shows the contents of the Magazine directory, listing the available
       ``runc`` bundles. 
   - * ``-e``
     * Enforce
     * Sets the security coefficient map to be enforced (must be used with
       ``-m`` and the predefined security map must be **sealed**). 
   - * ``-t``
     * Trajectory
     * Outputs events as *JSON*-formatted lines instead of security state
       coefficients (must be used with ``-o``). 
   - * ``-u``
     * Current namespace
     * Specifies if the modeling security namespace used should be based on
       the current user namespace, where the process is running, in stead of the
       initial user namespace. 
   - * ``-X``
     * Execute mode
     * In execute mode, there isn't namespace setup in container or process
       (running bash), but only one program with its arguments gets run in the
       created security namespace. The name of the program with its arguments
       are specified as the very last argument to the ``quixote`` utility as
       follows: ``-- {name of the program} {its arguments}``. 
   - * ``-M``
     * Model (alternative)
     * Allows usage of an alternative model for event modeling. At the time of
       writing there is only one such model implemented available in the source
       tree of Quixote utilities. 
   - * ``-d``
     * Debug
     * There are debug statements in the Quixote codebase. These get printed
       into a file if this flag is set with pathname of the file as an argument. 
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


Concrete usage examples
........................

Example 0: Show runc bundles
,,,,,,,,,,,,,,,,,,,,,,,,,,,,

As mentioned in the above table, when used with ``-S``, ``quixote`` lists
available ``runc`` bundle directories that hold all the necessary stuff for
launching a ``runc`` container.

.. code-block:: console

   # quixote -S

If the output of this command does not show any bundle directories, you might
want to create some :ref:`runc setup <runc_setup>`. Otherwise you will only
be able to use the Process/Execute mode.

Example 1: Container workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The following is the "most basic way" to create a workload. It creates a
workload in free modeling mode. Which means it does not get evaluated against
any predefined model (set of security state coefficients). This model can be
inspected using ``quixote-console`` (described in section below).

When the ``-P`` isn't specified, ``quixote`` defaults to the container mode,
which means the process is executed inside an :term:`OCI` ``runc`` container.
This requires ``runc`` bundle directory with name corresponding to the workload
name to be placed inside ``/var/lib/Quixote/Magazine/`` directory. 

.. code-block:: console

   # quixote -w test_container_workload

When the ``-o`` flag gets used, the security modeling states get output to file
specified as argument to the flag.

.. code-block:: console

   # quixote -w test_container_workload -o test.model

These coefficients can then be used as model for the workload. This way any
violations of the model are captured and can be viewed using the
``quixote-console``.

.. _ref-seal-cont-mod:

.. code-block:: console

   # quixote -w test_container_workload -m test.model

The model can also be enforced using ``-e`` flag. Any violations will now lead
to the process being evaluated as untrusted and its execution will get denied.

.. code-block:: console

   # quixote -w test_container_workload -m test.model -e

.. warning::
   In case of running multiple workloads at once, each has to have a unique name
   as the name also serves as a identification for management sockets created at
   ``/var/lib/Quixote/mgmt/`` in the linux host file system. 

Example 2: Process workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,

When used with additional ``-P`` flag, compared to previous example, ``quixote``
launches workload in a subordinate ``bash`` process.

.. code-block:: console

   # quixote -P -w test_container_workload

When the ``-o`` flag gets used, the security modeling states get output to file
specified as argument to the flag.

.. code-block:: console

   # quixote -P -w test_container_workload -o test.model

These coefficients can then be used as model for the workload. That way any
violations of the model get captured and can be viewed using the
``quixote-console``.

.. code-block:: console

   # quixote -P -w test_container_workload -m test.model

The model can also be enforced using ``-e`` flag. Any violations will now lead
to the process being evaluated as untrusted and its execution will get denied.

.. code-block:: console

   # quixote -w test_container_workload -m test.model -e

Example 3: Execute workload
,,,,,,,,,,,,,,,,,,,,,,,,,,,

One can execute a specific program in :term:`TSEM` security namespace using
the ``-X`` flag as follows.

This runs ``ls`` command itself in a security namespace.

.. code-block:: console

   # quixote -w test_container_workload -X test_container -- ls

Its usefulness can be seen a little bit better when a model definition is
created.

.. code-block:: console

   # quixote -w test_container_workload -X test_container -o test_model -- ls

Now when trying to list contents of ``/`` directory, we get "Permission denied".

.. code-block:: console

   # quixote -w test_container_workload -X test_container -m test_model -e -- ls /

However, running listing of current directory works just fine.

.. code-block:: console

   # quixote -w test_container_workload -X test_container -m test_model -e -- ls


.. warning::
   In case of running multiple workloads at once, each has to have a unique name
   as the name also serves as an identification for management sockets created
   at ``/var/lib/Quixote/mgmt/`` in the Linux host file system. 

