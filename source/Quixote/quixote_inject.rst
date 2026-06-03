
quixote-inject
==============

.. _quixote_inject:

This implementation doesn't preform modeling --- has no associated :term:`TMA`.
It is used for injection of security event descriptions into an Elasticsearch
instance. It doesn't need to be run on the same system as the interrogated
*quixote* --- it handles import of events from files.

Command line flags
..................

.. list-table::
   :widths: 10 20 60
   :header-rows: 1

   - * Flag
     * Name
     * Description
   - * ``-M``
     * Modeling
     * Enables modeling of security events against a TSEM model. When active,
       each event is processed through the model and the event description is
       augmented with the event's security coefficient and a violation status
       before being injected into the index.
   - * ``-n``
     * No-inject
     * Disables injection of events into the Elasticsearch index. Events are
       still read and, if ``-M`` is active, modeled, but nothing is written
       to the endpoint.
   - * ``-v``
     * Verbose
     * Prints each event description to standard output as it is processed.
   - * ``-h``
     * Host
     * Specifies the hostname or IP address of the Elasticsearch endpoint
       that events are to be injected into. Can also be set via the
       ``QUIXOTE_IDX_HOST`` environment variable.
   - * ``-i``
     * Index
     * Specifies the Elasticsearch index into which events are injected.
   - * ``-m``
     * Model
     * Specifies the path to a security model file to load when running in
       modeling mode (``-M``). If the model file contains a ``seal`` directive,
       violations against the model are flagged as such in the injected output.
   - * ``-p``
     * Port
     * Specifies the port of the Elasticsearch endpoint. Can also be set via
       the ``QUIXOTE_IDX_PORT`` environment variable.
   - * ``-u``
     * User
     * Specifies the username used to authenticate with the Elasticsearch
       endpoint. Can also be set via the ``QUIXOTE_IDX_USER`` environment
       variable.
   - * ``-P``
     * Password
     * Specifies the password used to authenticate with the Elasticsearch
       endpoint. Can also be set via the ``QUIXOTE_IDX_PWD`` environment
       variable.


Concrete usage examples
.......................

Example 0: Inject raw security events
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The most basic usage reads security events from standard input and injects
them into the specified Elasticsearch index as-is, without any modeling.

.. code-block:: console

   # quixote-inject -h elastic.dm -u tsem -P test123 -i security-events < events.log

Example 1: Inject with modeling
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

When used with ``-M``, each event is processed through an instance of external
:term:`TMA` before injection. The injected documents are augmented with a
security coefficient and a violation status field. This mode is useful for
labeling events against a known-good behavioral baseline.

.. code-block:: console

   # quixote-inject -M -h elastic.dm -u tsem -P test123 -i security-events < events.log

A specific model file can be supplied with ``-m``. Events are then evaluated
against the predefined set of security state coefficients in that file.

.. code-block:: console

   # quixote-inject -M -m test.model -h elastic.dm -u tsem -P test123 -i security-events < events.log

If the model file contains a seal directive, any event that violates the
model will have its violation field set to yes in the injected document.

Example 2: Preview events without injecting
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The ``-n`` flag disables injection entirely. Combined with ``-v``, this lets you
inspect what would be sent to the index without writing anything to the
Elasticsearch endpoint. This is useful for verifying event formatting or model
augmentation before committing to an index.

.. code-block:: console

   # quixote-inject -n -v -M -m test.model -h elastic.dm -u tsem -P test123 -i security-events < events.log

Example 3: Using environment variables
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The *host*, *user*, *password*, and *port* can be provided via environment
variables instead of flags, which is convenient in scripted or containerized
deployments.

.. code-block:: console

   # export QUIXOTE_IDX_HOST=elastic.dm
   # export QUIXOTE_IDX_USER=tsem
   # export QUIXOTE_IDX_PWD=test123
   # quixote-inject -i security-events < events.log


.. note::
   *elastic.dm* is the :term:`FQDN` for Elasticsearch. An :term:`IP` address
   can be used directly if the endpoint doesn't have an :term:`FQDN`.
