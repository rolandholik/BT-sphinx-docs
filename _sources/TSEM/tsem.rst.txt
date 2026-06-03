
TSEM
====

.. toctree::
   :hidden:
   :maxdepth: 3

   tsem_hooks

.. _tsem:

:term:`TSEM` kernel code is located in directory ``security/tsem`` in the Linux
kernel source tree.

The :term:`TSEM` implementation is composed of the following files:

.. list-table::
   :widths: 15 100
   :header-rows: 1

   - * File
     * Description
   - * ``event.c``
     * Contains functions that handle population of ``struct tsem_event`` --- a
       structure used to describe security events in :term:`TSEM`.
   - * ``export.c``
     * Contains functions used for exporting *JSON*-encoded security events to
       an external trust orchestrator and handling structures used for caching
       events of processes running in atomic context.
   - * ``fs.c``
     * Contains functions used for generating *JSON* objects that populate event
       descriptions. It also implements the control plane :term:`TSEM` uses to
       communicate with :term:`TO`/:term:`TMA`\s.
   - * ``map.c``
     * Part of the internal :term:`TMA` implementation. It provides functions
       for mapping event characteristics into a security state coefficient and
       function responsible for generating TASK_ID in the modeling algorithm used
       by the :term:`TMA`.
   - * ``model.c``
     * Part of the internal :term:`TMA` implementation. It implements structures
       that hold characteristics of events used to create security state
       coefficients as well as the function responsible for their creation.
   - * ``model0.c``
     * Defines array of boolean values that define which :term:`LSM` hooks
       should get handled by :term:`TSEM`.
   - * ``namespace.c``
     * Manages subordinate namespaces used by :term:`TSEM`.
   - * ``nsmgr.c``
     * Contains functions that handle management of security models which can be
       added as loadable security modules.
   - * ``nsmgr.h``
     * Header file for the ``nsmgr.c``.
   - * ``trust.c``
     * Responsible for working with the :term:`PCR` register used by
       :term:`TSEM` for extension of security events. It is also responsible for
       loading the hardware aggregate, generated at system boot time, in
       :term:`PCR` 0-7 to the security namespaces (both internal and external).
   - * ``tsem.c``
     * The main implementation file that is responsible for initialization of
       the :term:`TSEM` :term:`LSM`. It holds definition for all the :term:`LSM`
       hooks that :term:`TSEM` implements and manages their initialization.
   - * ``tsem.h``
     * Holds structures and functions used in the :term:`TSEM` implementation
       such as :term:`COE` structure and structure holding characteristics of a
       :term:`TSEM` event as a whole.


.. note::
   All code mentioned in this document and all its sub-documents is adopted from
   :term:`TSEM` code base developed by **Quixote Project**
   https://github.com/Quixote-Project.

Initialization
--------------

The following function (located in tsem.c) takes care of :term:`TSEM`
initialization. 

.. code-block:: c
   :linenos:

   static int __init tsem_init(void)
   {
       int retn;
       char *msg;
       struct tsem_task *tsk = tsem_task(current);
       struct tsem_context *ctx = &root_context;
       struct tsem_model *model = &root_model;

       BUILD_BUG_ON(sizeof(tsem_names) != TSEM_EVENT_CNT*sizeof(void *));

       security_add_hooks(tsem_hooks, ARRAY_SIZE(tsem_hooks), &tsem_lsmid);

       tsk->context = ctx;
       kref_init(&ctx->kref);
       kref_get(&ctx->kref);

       mutex_init(&ctx->inode_mutex);
       INIT_LIST_HEAD(&ctx->inode_list);

       mutex_init(&ctx->mount_mutex);
       INIT_LIST_HEAD(&ctx->mount_list);

       root_context.ops = &tsem_model0_ops;
       root_context.model = &root_model;
       for (lp = 0; lp <= 255; ++lp)
           INIT_LIST_HEAD(&root_model.coeff_lists[lp]);

       retn = tsem_event_cache_init();
       if (retn)
           return retn;

       retn = tsem_model_cache_init(model, magazine_size);
       if (retn)
           goto done;

       retn = tsem_export_cache_init();
       if (retn)
           goto done;

       retn = tsem_event_magazine_allocate(ctx, magazine_size);
       if (retn)
           goto done;
       memcpy(ctx->actions, tsem_root_actions, sizeof(tsem_root_actions));

       switch (tsem_mode) {
       case FULL_MODELING:
           msg = "full modeling";
           break;
       case NO_ROOT_MODELING:
           msg = "namespace only modeling";
           break;
       case ROOT_EXPORT_ONLY:
           msg = "root export only";
           break;
       }
       pr_info("tsem: Initialized %s.\n", msg);

       tsem_available = true;
       tsk->trust_status = TSEM_TASK_TRUSTED;
       retn = 0;

    done:
       if (retn) {
           tsem_event_magazine_free(ctx);
           tsem_model_magazine_free(model);
       }
       return retn;
   }

Lines 5--7 reference structures that hold settings for root modeling namespace.

Line 9 checks if structure containing names (``struct tsem_names`` located in
``tsem.c``) of hooks implemented by :term:`TSEM` matches number of enumerators
in the associated enumeration (``enum tsem_event_type`` located in ``tsem.h``).
This check is important, as the enumeration is used throughout :term:`TSEM`
codebase to refer to the names in this structure [#]_.

Line 11 initializes :term:`TSEM`\s security hooks.

Lines 13--15 initialize kernel reference counter for ``struct tsem_context`` and
acquire additional reference for the current task. This counter tracks the
number of ``tsem_task`` structures that reference the structure in their
attributes. The ``struct tsem_context`` holds information about state of the
root namespace.

Lines 17--21, initialize lists that track inodes and mount points associated
with the root namespace.

Lines 23--24 configure the root namespace to use the default :term:`TSEM` model
implementation and associate the root context with the root model.

Lines 25--26 initialize the hash table buckets used to store security
coefficient lists generated by the internal :term:`TMA`.

Lines 28--40 initialize caches used for efficient ``struct tsem_event``
allocation, model-specific event allocation, and event export handling.

Line 43 copies the default action configuration into the root namespace context.

Lines 45--54 set the scope of :term:`TSEM` modeling. It can be set by
``tsem_mode=`` kernel boot parameter. It's set to "FULL_MODELING" by default.

Lines 56--60 print kernel information message indicating :term:`LSM`
initialization, mark the current task as trusted and complete initialization.


.. [#] Even thought it might seem so at first glance, not all hooks have
   corresponding event name/event type. (For example inode_init_security.)

To finalize :term:`TSEM` initialization. ``set_ready()`` function is called
amongst the last init functions in kernel initialization phase.


.. code-block:: c
   :linenos:

   static int __init set_ready(void)
   {
   	int retn;
   
   	if (!tsem_available)
   		return 0;
   
   	retn = configure_root_digest();
   	if (retn)
   		goto done;
   
   	retn = tsem_model_init();
   	if (retn)
   		goto done;
   
   	retn = tsem_fs_init();
   	if (retn)
   		goto done;
   
   	if (tsem_mode == ROOT_EXPORT_ONLY) {
   		retn = tsem_ns_export_root(magazine_size);
   		if (retn)
   			goto done;
   	}
   
   	pr_info("tsem: Now active.\n");
   	static_branch_disable(&tsem_not_ready);
   
    done:
   	return retn;
   }

   late_initcall(set_ready);

Line 5 checks if the ``tsem_init()`` function executed correctly.

Line 8 configures the digest used by the root namespace, defaulting to sha256.
One can define other digest using ``tsem_digest`` kernel command line parameter.

Line 12 initializes aggregate value, calculated over :term:`TPM` registers 0--7,
for internal namespaces (if :term:`TPM` is present of course).

Line 16 initializes pseudo-filesystem used by :term:`TSEM` --- :ref:`control
plane <h_control_plane>`.

Lines 20-24 sets up root namespace that handles exporting of events generated in
the namespace if the ``tsem_mode`` kernel command line parameter was set to
``ROOT_EXPORT_ONLY``.

Lines 26-27 print info kernel message indicating that :term:`TSEM` is active and
disable static branch ``tsem_not_ready`` (used by some hooks that might get
called before this point).

Line 33 is not part of the function, it just emphasizes that it is executed
amongst last init functions.


LSM Hooks
---------

:term:`TSEM` like all other :term:`LSM`\s uses security hooks to intercept
security relevant operations on the system. These hooks get called in places
where security critical operations happen in Linux kernel. It is up to the code
executed by the hook to decide whether execution of code from the point, where
the hook was called will continue --- **permission granted** or the execution
gets stopped --- **permission denied**. Code executed on the hook call is
called from a linked list containing code definitions for the hook that get
appended to the list upon initialization of a given :term:`LSM` Currently,
:term:`TSEM` manages 111 :term:`LSM` hooks (list below is alphabetically
ordered): 

    - bpf
    - bpf_map
    - bpf_prog
    - bprm_check_security
    - bprm_committed_creds
    - capable
    - capget
    - capset
    - cred_prepare
    - file_fcntl
    - file_ioctl
    - file_ioctl_compat
    - file_lock
    - file_open
    - file_receive
    - file_truncate
    - inode_alloc_security
    - inode_create
    - inode_free_security
    - inode_getattr
    - inode_getxattr
    - inode_init_security
    - inode_killpriv
    - inode_link
    - inode_listxattr
    - inode_mkdir
    - inode_mknod
    - inode_removexattr
    - inode_rename
    - inode_rmdir
    - inode_setattr
    - inode_setxattr
    - inode_symlink
    - inode_unlink
    - ipc_permission
    - kernel_load_data
    - kernel_module_request
    - kernel_read_file
    - key_alloc
    - key_permission
    - mmap_file
    - move_mount
    - msg_queue_alloc_security
    - msg_queue_associate
    - msg_queue_msgctl
    - msg_queue_msgrcv
    - msg_queue_msgsnd
    - netlink_send
    - path_chmod
    - path_chown
    - path_chroot
    - path_link
    - path_mkdir
    - path_mknod
    - path_rename
    - path_rmdir
    - path_symlink
    - path_truncate
    - path_unlink
    - ptrace_access_check
    - ptrace_traceme
    - quotactl
    - quota_on
    - sb_mount
    - sb_pivotroot
    - sb_remount
    - sb_statfs
    - sb_umount
    - sem_alloc_security
    - sem_associate
    - sem_semctl
    - sem_semop
    - settime
    - shm_alloc_security
    - shm_associate
    - shm_shmat
    - shm_shmctl
    - socket_accept
    - socket_bind
    - socket_connect
    - socket_create
    - socket_getpeername
    - socket_getsockname
    - socket_listen
    - socket_post_create
    - socket_recvmsg
    - socket_sendmsg
    - socket_setsockopt
    - socket_shutdown
    - socket_socketpair
    - syslog
    - task_alloc
    - task_free
    - task_getioprio
    - task_getpgid
    - task_getscheduler
    - task_getsid
    - task_kill
    - task_prctl
    - task_prlimit
    - task_setioprio
    - task_setnice
    - task_setpgid
    - task_setrlimit
    - task_setscheduler
    - tun_dev_attach
    - tun_dev_attach_queue
    - tun_dev_create
    - tun_dev_open
    - unix_may_send
    - unix_stream_connect


See :ref:`LSM Hooks <tsem_hooks>` for more detailed description.


.. _h_control_plane:

Control Plane
-------------

:term:`TSEM` utilizes a pseudo-file system that is used for communication with
userspace :term:`TO`\s. The control plane is used mainly to export event
descriptions and security state coefficients to the :term:`TO`. It is located in
``/sys/kernel/security/tsem/`` of the host system.

See tree listing of the directory below:

.. code-block:: console

   $ tree -F /sys/kernel/security/tsem
   /sys/kernel/security/tsem
   ├── aggregate
   ├── control
   ├── export
   ├── id
   └── internal_tma/
       └── model0/
           ├── forensics
           ├── forensics_coefficients
           ├── forensics_counts
           ├── measurement
           ├── state
           ├── trajectory
           ├── trajectory_coefficients
           └── trajectory_counts
   
   2 directories, 12 files

Each of the 12 files responds in context of the namespace, the accessing process
is assigned to. This means multiple :term:`TO`\s might run at once and even
though they write and read from the same files each communicates :term:`TMA`
that manages their corresponding modeling namespace.


.. list-table::
   :widths: 15 100
   :header-rows: 1

   - * Directory
     * Description
   - * ``internal_tma``
     * Holds subdirectories which internal external :term:`TMA`\s implemented
       in the kernel. Currently, there is only one --- model0.
   - * ``model0``
     * Holds files used for exporting events and security state coefficients for
       the "model0" kernel-based :term:`TMA`.


.. list-table::
   :widths: 15 100
   :header-rows: 1

   - * File
     * Description
   - * ``export``
     * Used by userspace utilities to read *JSON*-formated events.
   - * ``aggregate``
     * Used by :term:`TO`\s to acquire the aggregate value calculated by
       extending of :term:`PCR`\s 0--7. This value can be seen, for example, on
       the first line of a security map generated when saving a map of security
       state coefficients using ``quixote`` with ``-m`` command line option.
   - * ``control``
     * Used by :term:`TO`\s to create and control security modeling namespaces
       by writing control commands to and reading from the file.
   - * ``id``
     * Used to read the *id* number of the security namespace, in which the
       orchestrator is operating.
   - * ``forensics``
     * Used to read a set of *JSON*-formatted event descriptions from the
       reading process's namespace. These descriptions detail violations of the
       current security map.
   - * ``forensic_coefficients``
     * Used to read the set of security state coefficients, that violate the
       current security map according to which the :term:`TMA` is modeling. The
       coefficients correspond to the namespace of the process reading the file.
   - * ``forensic_counts``
     * Used to read the linear extension of all security state coefficients
       generated up to that point, by the namespace of the process reading the
       file.
   - * ``measurement``
     * Used to read the linear extension of all security state coefficients
       generated up to that point by the namespace of the process reading the
       file.
   - * ``state``
     * Used to read the security‑state coefficient the namespace is currently
       in.
   - * ``trajectory``
     * Used to read the set of *JSON*-formatted security events generated by the
       namespace.
   - * ``trajectory_coefficients``
     * Used to read the set of security state coefficients generated by the
       namespace of the process reading the file.
   - * ``trajectory_counts``
     * Used to read the counts of individual security events generated by the
       namespace of the process reading the file.

