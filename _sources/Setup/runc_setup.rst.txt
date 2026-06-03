
Runc setup
==========

.. _runc_setup:

For some of our experiments, we used ``runc`` container-based workloads. In
order to run containers with "pure ``runc``" one needs an :term:`OCI` bundle. We
acquired :term:`OCI` bundles by decomposing Docker images. The following guide
walks through the steps necessary to reproduce our approach.

.. admonition:: Prerequisites
   :class: custom-note

   To follow this guide, one should have the following programs installed:

   - ``docker`` ---  A container engine used to build, run, and package container images.
   - ``skopeo`` ---  A tool for copying, inspecting, and converting container images between registries and formats.
   - ``umoci`` ---  An OCI image manipulation tool used to unpack container images into OCI bundles that ``runc`` can execute.
   - ``runc`` ---  A low‑level OCI runtime that executes OCI bundles as containers. Quixote utilities use this runtime for running container workloads.

.. warning::
   For kernels compiled with minimal *.config* (``make localmodconf``), it's
   very likely, ``docker`` will not work, since the minimal configuration won't
   include all required kernel features. However when created on a host with the
   kernel features enabled, the :term:`OCI` runtime bundles can be copied over
   and run, even with kernel compiled with the minimal ``.config``, using
   ``runc``.

.. note::
   This guide uses Debian Trixie container/image for demonstration, but the gist
   of this guide can be applied to arbitrary containers/images as long as the
   image follows the :term:`OCI` standard.

Acquiring the image
-------------------

First, download the debian image from docker hub.

.. code-block:: console

   $ docker pull debian:trixie-slim
   trixie-slim: Pulling from library/debian
   5b4d6ff92fc4: Pull complete 
   Digest: sha256:b6e2a152f22a40ff69d92cb397223c906017e1391a73c952b588e51af8883bf8
   Status: Downloaded newer image for debian:trixie-slim
   docker.io/library/debian:trixie-slim


Converting to OCI layout
------------------------

Save the image as ``.tar`` archive and exported its :term:`OCI` image layout
using ``skopeo``. 

.. code-block:: console

   $ docker image save -o debian.tar debian:trixie-slim
   $ skopeo copy docker-archive:debian.tar oci:debian:trixie-slim
   Getting image source signatures
   Copying blob 219a998c6050 done  
   Copying config 17d533096a done  
   Writing manifest to image destination
   Storing signatures

.. note::
   We could have exported the :term:`OCI` layout directly from docker daemon,
   but it may cause following error on older docker versions:

   .. code-block:: console
   
      $ skopeo copy docker-daemon:debian:trixie-slim oci:debian:trixie-slim
      FATA[0000] initializing source docker-daemon:debian:trixie-slim: loading
      image from docker engine: Error response from daemon: {"message":"client
      version 1.22 is too old. Minimum supported API version is 1.24, please
      upgrade your client to a newer version"}

Next, convert the :term:`OCI` image layout to :term:`OCI` runtime bundle using
``umoci``:

.. code-block:: console

   $ sudo umoci unpack --image debian:trixie-slim bundle

With the :term:`OCI` runtime bundle, the container can be launched using
``runc``:

.. code-block:: console

   $ sudo runc run -b bundle/ debian

If the above works, copy the bundle directory to the
*/var/lib/Quixote/Magazine/* directory. Quixote launches containers from that
directory.

.. code-block:: console

   $ sudo cp -rp bundle /var/lib/Quixote/Magazine/trixie
