
quixote-export
==============

.. _quixote_export:

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

Exporting to a file isn't the most impressive thing ``quixote-export`` can do
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


