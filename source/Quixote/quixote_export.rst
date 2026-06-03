
quixote-export
==============

.. _quixote_export:

This implementation doesn't do modeling --- has no associated :term:`TMA`. It's
used only for exporting security events. The events can be exported to a
specified file or sent to an :term:`MQTT` server for broadcasting. The
:term:`MQTT` option is meant to be used for the system monitoring purposes (such
as :term:`HIDS`) or collection of data for the development of machine learning
based security models.

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
     * Shows the contents of the Magazine directory, listing the available
       ``runc`` bundles. 
   - * ``-X``
     * Execute mode
     * In execute mode, there isn't namespace setup in container or process
       (running bash), but only one program with its arguments gets run in the
       created security namespace. The name of the program with its arguments
       are specified as the very last argument to the ``quixote`` utility as
       follows: ``-- {name of the program} {its arguments}``. 
   - * ``-a``
     * Timestamp
     * Adds timestamp to the exported event description.
   - * ``-f``
     * Follow
     * By default exporting from the root modeling namespace exports only events
       that occurred up until the point of calling the export from the point of
       last export. With this command, it continues streaming new events after
       the accumulated queue is flushed.
   - * ``-u``
     * Current namespace
     * Specifies if the modeling security namespace used should be based on
       the current user namespace, where the process is running, in stead of the
       initial user namespace. 
   - * ``-M``
     * Model (alternative)
     * Allows usage of an alternative model for event modeling. At the time of
       writing there is only one such model implemented available in the source
       tree of Quixote utilities. 
   - * ``-b``
     * Broker
     * In case ``quixote-export`` is used with :term:`MQTT` client, this sets
       the :term:`MQTT` broker :term:`IP` address. It may be :term:`IP` address
       directly or :term:`FQDN` or hostname.
   - * ``-d``
     * Debug
     * There are debug statements in the Quixote codebase. These get printed
       into a file if this flag is set with pathname of the file as an argument. 
   - * ``-e``
     * Endpoint
     * In case ``quixote-export`` is used with Elasticsearch this sets the
       :term:`IP` address of its endpoint. It may be :term:`IP` address directly
       or :term:`FQDN` or hostname.
   - * ``-h``
     * Hash digest
     * Sets the hash function to be used for generation of security state
       coefficients. Current default is sha256. Takes the name of the hash
       function (compiled into the kernel) as an argument. 
   - * ``-n``
     * Cache size
     * Specifies the number of preallocated structures holding data for security
       events happening in atomic context. One should not have to worry too much
       about this number, since the default (32 structures) should suffice for
       most use cases. 
   - * ``-o``
     * Output file
     * Specifies an output file, where the model of the current workload is to
       be saved. Takes string argument with pathname to the desired file. 
   - * ``-q``
     * Queue size
     * Specifies the queue size (numbers of events) ``quixote-export`` uses for
       root security namespace exporting. 
   - * ``-p``
     * Port
     * Specifies the :term:`MQTT` or Elasticsearch endpoint port, in case the
       output is routed to the :term:`MQTT` or Elasticsearch endpoint. The
       default is set to 1883 for :term:`MQTT` and 9200 for Elasticsearch (so
       this flag does not have to be used).
   - * ``-t``
     * Topic
     * When used with :term:`MQTT` or Elasticsearch endpoint, this flag's
       argument specifies the topic or Elasticsearch index to which the events
       will be sent. 
   - * ``-w``
     * Workload name
     * Specifies name of the workload that is to be run.


Concrete usage examples
........................

With ``quixote-export`` the basic notion for usage remains similar. However,
there are some differences, since it's used to export events rather than to
perform modeling

Example 0: Show runc bundles
,,,,,,,,,,,,,,,,,,,,,,,,,,,,

As mentioned in the above table, when used with ``-S``, ``quixote-export`` lists
available ``runc`` bundle directories that hold all the necessary resources for
launching a ``runc`` container.

It's likely an unintended "feature", but ``quixote-export`` in comparison to
previous Quixote implementations requires specification of an output file or
an :term:`MQTT` broker. The file doesn't need to exist, nor will it be
created...

.. code-block:: console

   # quixote-export -S -o test.exp


If the output of this command does not show any bundle directories, you might
want to create some :ref:`runc setup <runc_setup>`. Otherwise you will only
be able to use the Process/Execute mode.

Example 1: Exporting to a file
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The following is the "most basic way" to create export of a workload. It creates a
workload and outputs all of its events to the file specified by the ``-o`` flag.

When the ``-P`` isn't specified, ``quixote-export`` defaults to the container mode,
which means the process is executed inside an :term:`OCI` ``runc`` container.
This requires ``runc`` bundle directory with name corresponding to the workload
name to be placed inside ``/var/lib/Quixote/Magazine/`` directory. 

.. code-block:: console

   # quixote-export -w test_container_workload -o test.exp

Example 2: Exporting to an MQTT broker
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Exporting to a file isn't the most impressive thing ``quixote-export`` can do
--- ``quixote`` can do the same. Exporting to an :term:`MQTT` broker is what
makes ``quixote-export`` interesting.

.. code-block:: console

   # quixote-export -w test_container_workload -b broker.dm -t test -p 10902

In this example, we are exporting security events from our container workload to
an :term:`MQTT` broker with topic *test* on port 10902. One can use any
:term:`MQTT` client e.g. ``mosquitto`` to connect to the broker and listen on
the topic.

Example 3: Exporting to an Elasticsearch endpoint
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Besides exporting to an :term:`MQTT` broker, exporting to an Elasticsearch
endpoint is also possible. Before this tool was available, exporting to
Elasticsearch was possible, indirectly, by exporting to an :term:`MQTT` broker
and redirecting the export to an Elasticsearch endpoint (:ref:`ELK setup
<elastic_setup>`).

.. warning::

   Password for the Elasticsearch endpoint has to be set using *TSEM_ES_PWD*
   environment variable. The default (hardcoded user used by ``quixote-export``
   is "*tsem*".)

.. code-block:: console

   # quixote-export -w test_container_workload -e elastic.dm -t test -p 443

In this example, we are exporting security events from our container workload to
an Elasticsearch endpoint to an index *test* on port --- 443 (we are running
Elasticsearch behind a `reverse proxy
<https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-as-a-reverse-proxy-on-ubuntu-22-04>`_).

.. note::
   *broker.dm* and *elastic.dm* are the :term:`FQDN`\s for :term:`MQTT` broker
   and Elasticsearch, respectively. An :term:`IP` address can be used directly
   if the broker/endpoint doesn't have an :term:`FQDN`.

Example 4: Exporting from a root modeling namespace
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

In the above example we were exporting from a subordinate security modeling
namespace.

In this example, we demonstrate how to export events from the root modeling
namespace.

.. code-block:: console

   # quixote-export -R -w test -b broker.dm -t test

We are again exporting to the broker ``broker.dm`` on the ``test`` topic. We
have not defined a port this time --- we are exporting on the default port
(1883). This outputs only the events generated since system start or since the
last event export.

.. code-block:: console

   # quixote-export -R -w test -b broker.dm -t test -f

The above command will output all events from the system start or the last event
export ass well as all subsequent events.

