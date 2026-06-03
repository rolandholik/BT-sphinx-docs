
MQTT setup
==========

.. _mqtt_setup:

For some of our experiments, we used Mosquitto :term:`MQTT` broker for data
exporting. For its relative simplicity we used a Docker stack with configuration
described in this guide.

.. admonition:: Prerequisites
   :class: custom-note

   To follow this guide, one should have the following programs installed:

   - ``docker`` ---  A container engine used to build, run, and package container images.
   - ``docker compose`` ---  Orchestration tool that defines and runs container applications using an :term:`YAML` config.

Overall deployment structure:

.. code-block::

   mqtt/
   ├── compose.yml
   └── volumes
       ├── config/
       │   ├── mosquitto.conf
       │   └── pwfile
       ├── data/
       └── log/


Docker compose
--------------

File with docker compose declaration ``compose.yml``:

.. code-block:: yaml

   services:
     mosquitto:
       image: eclipse-mosquitto
       container_name: mosquitto
       user: 1000:1000
       volumes:
         - ./volumes/config:/mosquitto/config:rw
         - ./volumes/data:/mosquitto/data:rw
         - ./volumes/log:/mosquitto/log:rw
       ports:
         - 10902:1883
         - 9001:9001
       stdin_open: true 
       tty: true

.. note::
   Make sure to create the directories ``./volumes/data``, ``./volumes/config``,
   ``./log`` path under user with UID 1000, otherwise the containers will
   complain about permissions for reading of their data.
   .. code-block:: console

      mkdir -p ./volumes/config

      mkdir -p ./volumes/data

      mkdir -p ./volumes/log

      sudo chown -R 1000 ./volumes


Configuration
-------------

MQTT broker config ``./volumes/config/mosquitto.conf``:

::

   listener 1883
   listener 9001
   protocol websockets
   persistence true
   persistence_file mosquitto.db
   persistence_location /mosquitto/data/

   #Authentication
   allow_anonymous false
   password_file /mosquitto/config/pwfile


To correctly use the above files, it's necessary to create users/passwords. At
least one for :term:`TSEM` for data export, ideally also a user for reading from
the broker. This can be achieved in the command line of the *mosquitto*
container.

.. code-block:: console

   $ docker exec mosquitto mosquitto_passwd -b /mosquitto/config/pwfile tsem "test"
   $ docker exec mosquitto mosquitto_passwd -b /mosquitto/config/pwfile tsem "test"

Deployment
----------

To run the containers in detached mode (in the background), run (at the top
directory):

.. code-block:: console

   $ docker compose up -d
