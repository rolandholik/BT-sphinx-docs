Introduction
============

.. _introduction:

About
-----

This guide came to light as supporting documentation to my bachelor's thesis,
documenting my exploration of at the time of writing newly proposed Linux
Security Module (:term:`LSM`) called Trusted Security Event Modeling (or rather
**TSEM**. It's supposed to give the reader better understanding of what
:term:`TSEM` is and how to use it.

:term:`TSEM` comes with documentation of its own, which explains mostly the
theory behind the :term:`LSM`. Therefore it can be quite daunting for newcomers
and people, who just want to get their hands dirty or try to quickly grasp the
basic principles of the :term:`LSM`. In this documentation, I'm hoping to
provide a more "hands on" overview of :term:`TSEM`, through eyes of a
undergraduate computer science student (me).

Trusted Security Event Modeling -- TSEM
---------------------------------------

:term:`TSEM` is a newly proposed Linux Security Module. What makes it different
when compared to other :term:`LSM`\s is that it uses models based on desired
behaviour of the system rather than manually defined policies. :term:`TSEM`
isn't capable of access control on its own. It's meant to interact with a Trust
Orchestrator (:term:`TO`) that is implemented as a standalone program and a
Trusted Modeling Agent (:term:`TMA`).

:term:`TMA` represents the root of trust of the modeling in :term:`TSEM`. It
implements the modeling algorithm, models security events and decides on model
(policy) violation. Currently there are 2 types of :term:`TMA`\s available,
internal (implemented in kernel space) and external (implemented in user space).

:term:`TO` handles coordination between userspace interrogation utilities and
:term:`TMA` (creating namespaces, loading workload models, exporting policy
relevant data). Currently there is one set of such utilities available made by
the :term:`TSEM` developers --- **Quixote**. The notion of TSEM is meant to also
support more complicated modeling approaches such as machine learning models. 

.. note::
   The :term:`TSEM` :term:`LSM` --- said in very simple terms --- is more of a
   framework than an actual :term:`LSM`. This means it can be used as, for
   example, an :term:`HIDS`, if such functionality gets implemented in a
   userspace program.


Quixote
-------

Quixote utilities are the userspace :term:`TO`\s for :term:`TSEM`. Its current
utilities help implement relatively simple deterministic security models through
:term:`TMA`. Within the :term:`TSEM` architecture, each :term:`TO` is paired
with a :term:`TMA` that implements the security modeling algorithm and root of
trust. Quixote github repository currently provides six different :term:`TMA`
implementations:

    - quixote           (:term:`TMA` in kernel)
    - quixote-us		(:term:`TMA` in user space process)
    - quixote-sgx		(:term:`TMA` in SGX enclave)
    - quixote-sgx-u		(:term:`TMA` in SGX enclave (unified binary))
    - quixote-xen		(:term:`TMA` in Xen hypervisor stub domain)
    - quixote-mcu       (:term:`TMA` in Micro-controller)

    .. note::
        There are also quixote-export quixote-console which come with no
        :term:`TMA` as they serves only for purposes of security event exporting
        and workload monitoring respectively.
