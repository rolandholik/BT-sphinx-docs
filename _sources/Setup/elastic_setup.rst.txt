
Elastic setup
=============

.. _elastic_setup:

Part of our eploration involved ELK stack --- Elasticsearch for data indexing
and Kibana for data inspection. For its relative simplicity we used docker stack
with following configuration.

.. admonition:: Prerequisites
   :class: custom-note

   To follow this guide, one should have the following programs installed:

   - ``docker`` ---  A container engine used to build, run, and package container images.
   - ``docker compose`` ---  Orchestration tool that defines and runs container applications using an :term:`YAML` config.

Overall deployment structure:

.. code-block::

   elk
   ├── compose.yml
   └── docker-volumes
       ├── certs
       ├── esdata01
       └── kibanadata

Docker compose
--------------

File with docker compose declaration ``compose.yml``:

.. code-block:: yaml

    services:
      setup:
        image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
        volumes:
          - ${VOLUMES_PATH}/certs:/usr/share/elasticsearch/config/certs
        user: "0"
        command: >
          bash -c '
            if [ x${ELASTIC_PASSWORD} == x ]; then
              echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
              exit 1;
            elif [ x${KIBANA_PASSWORD} == x ]; then
              echo "Set the KIBANA_PASSWORD environment variable in the .env file";
              exit 1;
            fi;
            if [ ! -f config/certs/ca.zip ]; then
              echo "Creating CA";
              bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
              unzip config/certs/ca.zip -d config/certs;
            fi;
            if [ ! -f config/certs/certs.zip ]; then
              echo "Creating certs";
              echo -ne \
              "instances:\n"\
              "  - name: es01\n"\
              "    dns:\n"\
              "      - es01\n"\
              "      - localhost\n"\
              "    ip:\n"\
              "      - 127.0.0.1\n"\
              > config/certs/instances.yml;
              bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
              unzip config/certs/certs.zip -d config/certs;
            fi;
            echo "Setting file permissions"
            chown -R root:root config/certs;
            find . -type d -exec chmod 750 \{\} \;;
            find . -type f -exec chmod 640 \{\} \;;
            echo "Waiting for Elasticsearch availability";
            until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
            echo "Setting kibana_system password";
            until curl -s -X POST --cacert config/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
            echo "All done!";
          '
        healthcheck:
          test: ["CMD-SHELL", "[ -f config/certs/es01/es01.crt ]"]
          interval: 1s
          timeout: 5s
          retries: 120
        networks:
          - nw
    
      es01:
        depends_on:
          setup:
            condition: service_healthy
        container_name: es01
        image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
        restart: unless-stopped
        volumes:
          - ${VOLUMES_PATH}/certs:/usr/share/elasticsearch/config/certs
          - ${VOLUMES_PATH}/esdata01:/usr/share/elasticsearch/data
        ports:
          - "${ES_PORT}:9200"
        environment:
          - node.name=es01
          - cluster.name=${CLUSTER_NAME}
          - discovery.type=single-node
          - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
          - bootstrap.memory_lock=true
          - xpack.security.enabled=true
          - xpack.security.http.ssl.enabled=true
          - xpack.security.http.ssl.key=certs/es01/es01.key
          - xpack.security.http.ssl.certificate=certs/es01/es01.crt
          - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
          - xpack.security.transport.ssl.enabled=true
          - xpack.security.transport.ssl.key=certs/es01/es01.key
          - xpack.security.transport.ssl.certificate=certs/es01/es01.crt
          - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
          - xpack.security.transport.ssl.verification_mode=certificate
          - xpack.license.self_generated.type=${LICENSE}
          - xpack.ml.use_auto_machine_memory_percent=true
        mem_limit: ${MEM_LIMIT}
        ulimits:
          memlock:
            soft: -1
            hard: -1
        healthcheck:
          test:
            [
              "CMD-SHELL",
              "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
            ]
          interval: 10s
          timeout: 10s
          retries: 120
        networks:
          - nw
    
      kibana:
        depends_on:
          es01:
            condition: service_healthy
        container_name: kibana
        image: docker.elastic.co/kibana/kibana:${STACK_VERSION}
        restart: unless-stopped
        volumes:
          - ${VOLUMES_PATH}/certs:/usr/share/kibana/config/certs
          - ${VOLUMES_PATH}/kibanadata:/usr/share/kibana/data
        ports:
          - "${KIBANA_PORT}:5601"
        environment:
          - SERVERNAME=kibana
          - ELASTICSEARCH_HOSTS=https://es01:9200
          - ELASTICSEARCH_USERNAME=kibana_system
          - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
          - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
        mem_limit: ${MEM_LIMIT}
        healthcheck:
          test:
            [
              "CMD-SHELL",
              "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
            ]
          interval: 10s
          timeout: 10s
          retries: 120
        networks:
          - nw
    
    networks:
    
      nw:

The compose file prepares the configuration for the deployment of Elasticsearch
and Kibana. The ``setup`` service serves for the one-time setup of certificates
and distribution of the certificate authority used by Elasticsearch and Kibana
for encrypted communication. It also configures passwords for Kibana system user
and the admin Elastic user.

.. note::
   Make sure to create the directories in ``./docker-volumes`` path under user
   with UID 1000, otherwise the containers will complain about permissions for
   reading of their data.
   .. code-block:: console

      mkdir -p ./docker-volumes/kibanadata

      mkdir -p ./docker-volumes/esdata01

      sudo chown -R 1000 ./docker-volumes
    

Environment variables
---------------------

File with environment variables ``.env``:

:: 

   VOLUMES_PATH=./docker-volumes

   # Password for the 'elastic' user (at least 6 characters)
   ELASTIC_PASSWORD='superultrasecretpassword12345Q?!1337'
   
   # Password for the 'kibana_system' user (at least 6 characters)
   KIBANA_PASSWORD='ultrasecretpassword12345Q?!1337'
   
   # Version of Elastic products
   STACK_VERSION=9.2.2
   
   # Set the cluster name
   CLUSTER_NAME='elk-cluster'
   
   # Set to 'basic' or 'trial' to automatically start the 30-day trial
   LICENSE=basic
   
   # Port to expose Elasticsearch HTTP API to the host
   ES_PORT=9200
   
   # Port to expose Kibana to the host
   KIBANA_PORT=5601
   
   # Increase or decrease based on the available host memory (in bytes)
   MEM_LIMIT=8589934592


Deployment
----------

To run the containers in detached mode (in the background), run (at the top
directory):

.. code-block:: console

   $ docker compose up -d

.. warning::
   The ELK deployment requires at least 8 GiB of system memory. While operation
   may be possible with less memory, Elasticsearch is a memory-intensive
   application, and performance improves with increased memory allocation.

User configuration
------------------

To use Elasticsearch smoothly with ``quixote-inject``, we created "tsem" user
with "global_index_writer" role under DevTools/Console in the Kibana instance by
executing the following command:

.. code-block::

   PUT /_security/role/global_index_writer
   {
     "cluster": [],
     "indices": [
       {
         "names": [ "*" ],
         "privileges": [
           "create",
           "create_index",
           "write",
           "index"
         ]
       }
     ]
   }
   
   POST /_security/user/tsem
   {
     "password" : "test123",
     "roles" : [ "global_index_writer" ],
     "full_name" : "Don Quixote",
     "email" : "rocinanate@decervantes"
   }
