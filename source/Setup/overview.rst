Complementary tools
===================

.. _overview:

.. toctree::
   :hidden:
   :maxdepth: 3

   elastic_setup
   mqtt_setup
   runc_setup


To fully explore :term:`TSEM`, the following tools might come in handy:

Elasticsearch
~~~~~~~~~~~~~

Elasticsearch is a distributed search and analytics engine commonly used for
indexing, querying, and visualizing large amounts of structured or
semi-structured data. Within :term:`TSEM`, it can be used for storing and
analyzing exported security events.

See :ref:`Process mode <elastic_setup>`.

(https://www.elastic.co/elasticsearch)

MQTT broker
~~~~~~~~~~~

:term:`MQTT` is a lightweight publish-subscribe messaging protocol designed for
low-bandwidth and high-latency environments. ``quixote-export`` can publish
security events to an :term:`MQTT` broker.

See :ref:`Container mode <mqtt_setup>`.

(https://mqtt.org)

Runc bundle
~~~~~~~~~~~

A ``runc`` bundle is a directory structure containing an :term:`OCI`
configuration file and a root filesystem required to launch a container using
``runc``. Quixote uses ``runc`` bundles when operating in container.

See :ref:`Execute mode <runc_setup>`.

(https://github.com/opencontainers/runc)

