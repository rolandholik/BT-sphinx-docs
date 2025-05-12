Introduction
============

.. _introduction:

About
-----

This Guide came to light as supporting documentation to my bachelors thesis,
documenting my exploration of at the time of writing newly proposed Linux
Security Module (:term:`LSM`) called Trusted Security Event Modeling (or rather
**TSEM**, yeah, the full name is quite mouthful :)). It's supposed to give the
reader better understanding of what :term:`TSEM` is and how to use it.

:term:`TSEM` comes with documentation of its own, but it can be quite daunting
for newcomers and people, who just want to get their hands dirty or try to
quickly grasp the basic principles of the LSM. Here I'm providing a view of TSEM
through eyes of a undergraduate student (me).


Trusted Security Event Modeling -- TSEM
---------------------------------------

TSEM is a newly proposed Linux Security Module. What makes it different when
compared to other :term:`LSM`\s is that it uses models based on desired
behaviour of the system rather than manually defined policies. :term:`TSEM`
isn't capable of access control on its own. It's meant to interact with a Trust
Orchestrator (:term:`TO`) that is implemented as a standalone program.
:term:`TO` handles the modeling part as well as enforcing of the model.
Currently there is only one such program available made by the :term:`TSEM`
developers themselves --- **Quixote**.


Quixote
-------

Quixote represents a relatively simplistic approach to security modeling as it
uses implements deterministic modeling. Quixote :term:`TO` needs a :term:`TMA`.
Quixote comes in 6 different implementations:

    - quixote           (:term:`TMA` in kernel)
    - quixote-us		(:term:`TMA` in user space process)
    - quixote-sgx		(:term:`TMA` in SGX enclave)
    - quixote-sgx-u		(:term:`TMA` in SGX enclave (unified binary))
    - quixote-xen		(:term:`TMA` in Xen hypervisor stub domain)
    - quixote-mcu       (:term:`TMA` in Micro-controller)

    .. note::
        There are also quixote-export quixote-console wich come with no
        :term:`TMA` as they serves only for purposes of security event exporting
        and workload monitoring respectively.

The notion of TSEM is also meant to support more complicated modeling approaches
such as machine learning models. 
