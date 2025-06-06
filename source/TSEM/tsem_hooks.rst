
LSM Hooks
=========

.. _tsem_hooks:


This section describes some of the :term:`LSM` hooks :term:`TSEM` leverages.

:term:`TSEM` implements all together 111 :term:`LSM` hooks with 109 unique
functions --- ``msg_queue_alloc_security``, ``sem_alloc_security``,
``shm_alloc_security`` are all handeled by same functions. Most of the functions
basically populate structures that hold characteristics of different security
events, but there are also functions that do something different.


Generating security events (few examples)
-----------------------------------------

This section describes hooks that populate :term:`TSEM` security event
structures with data. Most of the hooks in :term:`TSEM` do basically just that,
therefore most of the hooks chosen for this demonstration actually do a bit more
set up.

bprm_check_security
~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   static int tsem_bprm_check_security(struct linux_binprm *bprm)
   {
   	struct tsem_event *ep;
   
   	if (static_branch_unlikely(&tsem_not_ready))
   		return 0;
   	if (bypass_event(TSEM_BPRM_CHECK_SECURITY))
   		return 0;
   
   	ep = tsem_event_allocate(TSEM_BPRM_CHECK_SECURITY, NOLOCK);
   	if (!ep)
   		return -ENOMEM;
   
   	ep->CELL.bprm = bprm;
   	return dispatch_event(ep);
   }

This hook is one of the simple ones. It checks if :term:`TSEM` is fully
initialized and if this function is modeled by the current namespace. If one
of the conditions is not true, it exits, granting permission without modeling
the event. It allocates structure holding data about binary handlers in
:term:`TSEM` CELL structure and assigns the binary characteristics to it.
Afterwards, the hook models the event --- deciding to deny or permit the
operation --- and destroys the event structure.


file_open
~~~~~~~~~

.. code-block:: c

   static int tsem_file_open(struct file *file)
   {
   	struct inode *inode = file_inode(file);
   	struct tsem_event *ep;
   
   	if (static_branch_unlikely(&tsem_not_ready))
   		return 0;
   	if (bypass_event(TSEM_FILE_OPEN))
   		return 0;
   	if (unlikely(tsem_inode(inode)->status == TSEM_INODE_CONTROL_PLANE)) {
   		if (capable(CAP_MAC_ADMIN))
   			return 0;
   		else
   			return -EPERM;
   	}
   
   	if (!S_ISREG(inode->i_mode))
   		return 0;
   	if (tsem_inode(inode)->status == TSEM_INODE_COLLECTING)
   		return 0;
   
   	ep = tsem_event_allocate(TSEM_FILE_OPEN, NOLOCK);
   	if (!ep)
   		return -ENOMEM;
   
   	ep->CELL.file.in.file = file;
   	ep->CELL.file.in.pseudo_file = pseudo_filesystem(inode);
   
   	return dispatch_event(ep);
   }

This hook checks if :term:`TSEM` is fully initialized and if this type of event
is modeled by the current namespace. If one of the conditions isn't true, the
hook grants permission without modeling the event. If the file it tries to
access belongs to the :term:`TSEM` control plane and the process trying to open
the file has ``CAP_MAC_ADMIN`` capability set, the hook allows opening of the
file without modeling the event. If a process without ``CAP_MAC_ADMIN``
capability tries to open control plane file, the hook denies the operation
without modeling the event. The hook allocates event structure holding data
about file in :term:`TSEM` CELL structure and assigns file characteristics from
the accesses file to it. Afterwards, the hook models the event --- deciding to
deny or permit the operation --- and destroys the event structure.


mmap_file
~~~~~~~~~

.. code-block:: c

   static int tsem_mmap_file(struct file *file, unsigned long prot,
   			  unsigned long flags, unsigned long extra)
   {
   	struct inode *inode = NULL;
   	struct tsem_event *ep;
   
   	if (static_branch_unlikely(&tsem_not_ready))
   		return 0;
   	if (bypass_event(TSEM_MMAP_FILE))
   		return 0;
   
   	if (!file && !(prot & PROT_EXEC))
   		return 0;
   	if (file) {
   		inode = file_inode(file);
   		if (!S_ISREG(inode->i_mode))
   			return 0;
   		if (pseudo_filesystem(inode))
   			return 0;
   	}
   
   	ep = tsem_event_allocate(TSEM_MMAP_FILE, NOLOCK);
   	if (!ep)
   		return -ENOMEM;
   
   	ep->CELL.mmap_file.anonymous = file == NULL ? 1 : 0;
   	ep->CELL.mmap_file.file.in.file = file;
   	ep->CELL.mmap_file.prot = prot;
   	ep->CELL.mmap_file.flags = flags;
   
   	return dispatch_event(ep);
   }

This hook checks if :term:`TSEM` is fully initialized and if this type of event
is modeled by the current namespace. If one of the conditions isn't true, the
hook grants permission without modeling the event. The hook exits if there
is no file provided to the hook and the mapping is not set executable (e.g.
anonymous mapping of shared memory), granting permission for further execution
without modeling the event. The hook allocates :term:`TSEM` event structure for
``mmap_file`` characteristics and stores ``mmap_file`` related characteristics
to it. Afterwards, the hook models the event --- deciding to deny or permit the
operation --- and destroys the event structure. 

task_alloc
~~~~~~~~~~

.. code-block:: c

   static int tsem_task_alloc(struct task_struct *new, unsigned long flags)
   {
   	struct tsem_event *ep;
   
   	tsem_task(new)->tnum = tsem_task(current)->tnum;
   	tsem_task(new)->context = tsem_task(current)->context;
   
   	ep = tsem_event_allocate(TSEM_TASK_ALLOC, NOLOCK);
   	if (!ep)
   		return -ENOMEM;
   
   	ep->CELL.task_args.task = new;
   	ep->CELL.task_args.flags = flags;
   
   	if (tsem_context(new)->id)
   		kref_get(&tsem_task(new)->context->kref);
   	return dispatch_event(ep);
   }

This hook assigns serial number (tnum) and modeling namespace (context) to a
new task. It allocates :term:`TSEM` event structure for task_alloc event
characteristics and stores task_alloc related characteristics to it. If the new
task has valid id it increments reference count for the task. Afterwards, the
hook models the event --- deciding to deny or permit the operation --- and
destroys the event structure. 


task_free
~~~~~~~~~

.. code-block:: c

   static void tsem_task_free(struct task_struct *task)
   {
   	struct tsem_event ep;
   	struct tsem_context *ctx = tsem_context(task);
   
   	memset(&ep, '\0', sizeof(ep));
   	ep.event = TSEM_TASK_FREE;
   	ep.CELL.task_args.task = task;
   
   	if (likely(!ctx->ops->event_init))
   		tsem_event_init(&ep);
   	else
   		ctx->ops->event_init(&ep);
   
   	if (ctx->id)
   		tsem_ns_put(ctx);
   	else if (unlikely(tsem_tma_context(task)))
   		tsem_ns_put(tsem_tma_context(task));
   }

This hook sets its event structure to zeros, populates it with
``TSEM_TASK_FREE`` related characteristics and releases its kernel reference
from the modeling namespace of the task. This hook does not explicitly grant or
deny access as it's a void function.


task_kill
~~~~~~~~~

.. code-block:: c

   static int tsem_task_kill(struct task_struct *target,
   			  struct kernel_siginfo *info, int sig,
   			  const struct cred *cred)
   {
   	bool cross_model;
   	struct tsem_event *ep;
   	struct tsem_context *src_ctx = tsem_context(current);
   	struct tsem_context *tgt_ctx = tsem_context(target);
   
   	if (bypass_event(TSEM_TASK_KILL))
   		return 0;
   
   	cross_model = src_ctx->id != tgt_ctx->id;
   
   	if (info != SEND_SIG_NOINFO && SI_FROMKERNEL(info))
   		return 0;
   	if (sig == SIGURG)
   		return 0;
   	if (!capable(CAP_MAC_ADMIN) &&
   	    has_capability_noaudit(target, CAP_MAC_ADMIN))
   		return -EPERM;
   	if (!capable(CAP_MAC_ADMIN) && cross_model)
   		return -EPERM;
   
   	ep = tsem_event_allocate(TSEM_TASK_KILL, LOCK);
   	if (!ep)
   		return -ENOMEM;
   
   	ep->CELL.task_kill.signal = sig;
   	ep->CELL.task_kill.cross_model = cross_model;
   	memcpy(ep->CELL.task_kill.target, tsem_task(target)->task_id,
   	       tsem_digestsize());
   
   	return dispatch_event(ep);
   }

This hook acquires namespace context for current task (the one sending the 
signal) and target task (the one that is to recieve the signal). If
``task_kill`` isn't modeled by the current namespace, the signal originates
from kernel or it's urgent signal, the hook exits, granting permission without
modeling the event. If the task initiating the signal doesn't have
``CAP_MAC_ADMIN`` and the target task does or if the task initiating the
signaling doesn't have ``CAP_MAC_ADMIN`` and the signal is sent to task from
another modeling namespace, it returns permission denied, without modeling the
event. The hook allocates :term:`TSEM` event structure holding data about
``task_kill``, populates it with task kill characteristics and models the event
--- deciding to grant or deny permission --- and destroys the event structure.


Not generating security events
------------------------------

The following hooks don't do any modeling related operations and don't
grant/deny permissions. They only manage structures needed for proper
functioning of :term:`TSEM` :term:`LSM`.

.. _inode_alloc_security_r:

inode_alloc_security
~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   static int tsem_inode_alloc_security(struct inode *inode)
   {
       struct tsem_inode *tsip = tsem_inode(inode);

       mutex_init(&tsip->digest_mutex);
       INIT_LIST_HEAD(&tsip->digest_list);

       mutex_init(&tsip->create_mutex);
       INIT_LIST_HEAD(&tsip->create_list);

       mutex_init(&tsip->instance_mutex);
       INIT_LIST_HEAD(&tsip->instance_list);

       return 0;
   }

This hook initializes linked lists holding structures with: 
   - digests calculated for the inode
   - information about inodes created under a directory
   - task identities that have created inodes under a directory


inode_init_security
~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   static int tsem_inode_init_security(struct inode *inode, struct inode *dir,
   				    const struct qstr *qstr,
   				    struct xattr *xattrs, int *xattr_count)
   {
   	u8 *owner = tsem_task(current)->task_id;
   	struct tsem_inode *tsip = tsem_inode(inode);
   	struct tsem_inode_instance *entry, *retn = NULL;
   
   	mutex_lock(&tsem_inode(dir)->create_mutex);
   	list_for_each_entry(entry, &tsem_inode(dir)->create_list, list) {
   		if (!memcmp(entry->owner, owner, tsem_digestsize()) &&
   		    !strcmp(qstr->name, entry->pathname)) {
   			retn = entry;
   			break;
   		}
   	}
   
   	if (retn) {
   		tsip->backing = ERR_PTR(-ENOENT);
   		tsip->created = true;
   		tsip->creator = retn->creator;
   		tsip->instance = retn->instance;
   		memcpy(tsip->owner, retn->owner, tsem_digestsize());
   
   		list_del(&retn->list);
   		__putname(retn->pathname);
   		kfree(retn);
   	}
   	mutex_unlock(&tsem_inode(dir)->create_mutex);
   
   	return -EOPNOTSUPP;
   }

This hook searches in the directory parent directory of the inode that is meant
to have its security related data initialized. If found the hook initializes the
tsem_inode structure with :term:`TSEM` security related credentials of the
current task.


inode_free_security
~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   static void tsem_inode_free_security(struct inode *inode)
   {
   	struct tsem_inode_instance *owner, *tmp_owner;
   	struct tsem_inode_digest *digest, *tmp_digest;
   	struct tsem_inode_entry *entry, *tmp_entry;
   	struct tsem_context *ctx = tsem_context(current);
   
   	mutex_lock(&ctx->inode_mutex);
   	list_for_each_entry_safe(entry, tmp_entry, &ctx->inode_list, list) {
   		if (entry->tsip == tsem_inode(inode)) {
   			list_del(&entry->list);
   			_release_inode_instances(ctx->id, entry->tsip);
   			kfree(entry);
   		}
   	}
   	mutex_unlock(&ctx->inode_mutex);
   
   	list_for_each_entry_safe(digest, tmp_digest,
   				 &tsem_inode(inode)->digest_list, list) {
   		list_del(&digest->list);
   		kfree(digest->name);
   		kfree(digest);
   	}
   
   	list_for_each_entry_safe(owner, tmp_owner,
   				 &tsem_inode(inode)->create_list, list) {
   		list_del(&owner->list);
   		kfree(owner);
   	}
   
   	list_for_each_entry_safe(owner, tmp_owner,
   				 &tsem_inode(inode)->instance_list, list) {
   		list_del(&owner->list);
   		kfree(owner);
   	}
   }

This hook clears data in the three lists that :ref:`inode_alloc_security
<inode_alloc_security_r>` initializes.

.. note::
   The data in those lists get filled in hooks that didn't get covered by this
   page. :ref:`inode_alloc_security <inode_alloc_security_r>` only initializes
   the lists.

Managed by same function
~~~~~~~~~~~~~~~~~~~~~~~~

The tsem_ipc_alloc hook gets mapped to three different :term:`LSM` hooks.

msg_queue_alloc_security, sem_alloc_security, shm_alloc_security
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.. code-block:: c

   static int tsem_ipc_alloc(struct kern_ipc_perm *kipc)
   {
   	struct tsem_ipc *tipc = tsem_ipc(kipc);
   
   	memcpy(tipc->owner, tsem_task(current)->task_id, tsem_digestsize());
   	return 0;
   }

This hook assigns id of the task that created the :term:`IPC` resource to the
tsem_ipc structure of the resource. Data in this structure is important for
modeling of hooks that utilize the resource.


