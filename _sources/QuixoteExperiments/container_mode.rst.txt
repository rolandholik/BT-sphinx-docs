
Container mode
==============

.. _container_mode:

In container mode we experimented with modeling of two containers: minimalistic
Debian Buster container and Apache web server container.

Minimalistic Debain Buster
~~~~~~~~~~~~~~~~~~~~~~~~~~

We started by generating the model running ``ls`` command and then exiting the
workload.

.. code-block:: console

   # quixote -w buster -o buster.model
   # ls
   bin   dev  home  lib32	libx32	mnt  proc  run	srv  tmp  var
   boot  etc  lib	lib64	media	opt  root  sbin  sys  usr
   # 
   Wrote security model to: buster.model

Afterwards we enforced the model and ran the ``ls`` command.

.. code-block:: console

   # quixote -w buster -o buster.model
   # ls
   bin   dev  home  lib32	libx32	mnt  proc  run	srv  tmp  var
   boot  etc  lib	lib64	media	opt  root  sbin  sys  usr
   # 
   Wrote security model to: buster.model
   # quixote -w buster -m buster.model -e
   # ls
   bin   dev  home  lib32	libx32	mnt  proc  run	srv  tmp  var
   boot  etc  lib	lib64	media	opt  root  sbin  sys  usr

It got permitted.

Then we ran process monitoring tool ``top``.

.. code-block:: console

   # quixote -w buster -o buster.model
   # ls
   bin   dev  home  lib32	libx32	mnt  proc  run	srv  tmp  var
   boot  etc  lib	lib64	media	opt  root  sbin  sys  usr
   # 
   Wrote security model to: buster.model
   # quixote -w buster -m buster.model -e
   # ls
   bin   dev  home  lib32	libx32	mnt  proc  run	srv  tmp  var
   boot  etc  lib	lib64	media	opt  root  sbin  sys  usr
   # top
   sh: 2: Cannot fork
   # ls
   sh: 3: Cannot fork
   #

It got denied. What is more interesting, to note, is that running ``ls`` again
got denied.

Apache web server
~~~~~~~~~~~~~~~~~

Since running just a bare-bones container is not too useful, we also tried to
model a container running Apache Web Server.

We launched the container in order to create the model.

.. code-block:: console

   # quixote -w httpd -o httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   [Tue Jun 03 06:37:04.248420 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache
   /2.4.63 (Unix) configured -- resuming normal operations
   [Tue Jun 03 06:37:04.249136 2025] [core:notice] [pid 1:tid 1] AH00094: Command
   line: ’httpd -D FOREGROUND’
   127.0.0.1 - - [03/Jun/2025:06:37:36 +0000] "GET / HTTP/1.1" 304 -
   ^C[Tue Jun 03 06:39:02.019698 2025] [mpm_event:notice] [pid 1:tid 1] AH00491:
   caught SIGTERM, shutting down
   Wrote security model to: httpd.model

Afterwards, we tired to enforce the model.

.. code-block:: console

   # quixote -w httpd -o httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   [Tue Jun 03 06:37:04.248420 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache
   /2.4.63 (Unix) configured -- resuming normal operations
   [Tue Jun 03 06:37:04.249136 2025] [core:notice] [pid 1:tid 1] AH00094: Command
   line: ’httpd -D FOREGROUND’
   127.0.0.1 - - [03/Jun/2025:06:37:36 +0000] "GET / HTTP/1.1" 304 -
   ^C[Tue Jun 03 06:39:02.019698 2025] [mpm_event:notice] [pid 1:tid 1] AH00491:
   caught SIGTERM, shutting down
   Wrote security model to: httpd.model
   # quixote -w httpd -m httpd.model -e
   time="2025-06-03T06:39:17Z" level=warning msg="unable to terminate initProcess"
   error="operation not permitted"
   time="2025-06-03T06:39:17Z" level=warning msg="unable to destroy container: unable
   to remove container’s cgroup: rmdir /sys/fs/cgroup/user.slice/user-1000.slice
   /httpd: operation not permitted"
   time="2025-06-03T06:39:17Z" level=error msg="runc run failed: unable to start
   container process: error during container init: procReady not received"

We were met with permission denial.

To see what went wrong, we ran the workload again, but this time only in sealed
mode, so that we could examine what caused the denial.

.. code-block:: console

   # quixote -w httpd -o httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   [Tue Jun 03 06:37:04.248420 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache
   /2.4.63 (Unix) configured -- resuming normal operations
   [Tue Jun 03 06:37:04.249136 2025] [core:notice] [pid 1:tid 1] AH00094: Command
   line: ’httpd -D FOREGROUND’
   127.0.0.1 - - [03/Jun/2025:06:37:36 +0000] "GET / HTTP/1.1" 304 -
   ^C[Tue Jun 03 06:39:02.019698 2025] [mpm_event:notice] [pid 1:tid 1] AH00491:
   caught SIGTERM, shutting down
   Wrote security model to: httpd.model
   # quixote -w httpd -m httpd.model -e
   time="2025-06-03T06:39:17Z" level=warning msg="unable to terminate initProcess"
   error="operation not permitted"
   time="2025-06-03T06:39:17Z" level=warning msg="unable to destroy container: unable
   to remove container’s cgroup: rmdir /sys/fs/cgroup/user.slice/user-1000.slice
   /httpd: operation not permitted"
   time="2025-06-03T06:39:17Z" level=error msg="runc run failed: unable to start
   container process: error during container init: procReady not received"
   # quixote -w httpd -m httpd.model
   ERRO[0000] runc run failed: container with given ID already exists

We were met with following error. As we can see in the previous output, the
contained didn't get destroyed, so it was left hanging in initialization stage.
Therefore we had to delete the container.

.. code-block:: console

   # quixote -w httpd -o httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   [Tue Jun 03 06:37:04.248420 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache
   /2.4.63 (Unix) configured -- resuming normal operations
   [Tue Jun 03 06:37:04.249136 2025] [core:notice] [pid 1:tid 1] AH00094: Command
   line: ’httpd -D FOREGROUND’
   127.0.0.1 - - [03/Jun/2025:06:37:36 +0000] "GET / HTTP/1.1" 304 -
   ^C[Tue Jun 03 06:39:02.019698 2025] [mpm_event:notice] [pid 1:tid 1] AH00491:
   caught SIGTERM, shutting down
   Wrote security model to: httpd.model
   # quixote -w httpd -m httpd.model -e
   time="2025-06-03T06:39:17Z" level=warning msg="unable to terminate initProcess"
   error="operation not permitted"
   time="2025-06-03T06:39:17Z" level=warning msg="unable to destroy container: unable
   to remove container’s cgroup: rmdir /sys/fs/cgroup/user.slice/user-1000.slice
   /httpd: operation not permitted"
   time="2025-06-03T06:39:17Z" level=error msg="runc run failed: unable to start
   container process: error during container init: procReady not received"
   # quixote -w httpd -m httpd.model
   ERRO[0000] runc run failed: container with given ID already exists
   # runc delete httpd
   ERRO[0000] container does not exist

The ``runc`` gave us the same error, but it destroyed the uninitialized
contained in the background and we were able to relaunch the workload in sealed
mode.

.. code-block:: console

   # quixote -w httpd -o httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   [Tue Jun 03 06:37:04.248420 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache
   /2.4.63 (Unix) configured -- resuming normal operations
   [Tue Jun 03 06:37:04.249136 2025] [core:notice] [pid 1:tid 1] AH00094: Command
   line: ’httpd -D FOREGROUND’
   127.0.0.1 - - [03/Jun/2025:06:37:36 +0000] "GET / HTTP/1.1" 304 -
   ^C[Tue Jun 03 06:39:02.019698 2025] [mpm_event:notice] [pid 1:tid 1] AH00491:
   caught SIGTERM, shutting down
   Wrote security model to: httpd.model
   # quixote -w httpd -m httpd.model -e
   time="2025-06-03T06:39:17Z" level=warning msg="unable to terminate initProcess"
   error="operation not permitted"
   time="2025-06-03T06:39:17Z" level=warning msg="unable to destroy container: unable
   to remove container’s cgroup: rmdir /sys/fs/cgroup/user.slice/user-1000.slice
   /httpd: operation not permitted"
   time="2025-06-03T06:39:17Z" level=error msg="runc run failed: unable to start
   container process: error during container init: procReady not received"
   # quixote -w httpd -m httpd.model
   ERRO[0000] runc run failed: container with given ID already exists
   # runc delete httpd
   ERRO[0000] container does not exist
   # quixote -w httpd -m httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default AH00558:
   httpd: Could not reliably determine the server's fully qualified domain name,
   using 127.0.0.1. Set the 'ServerName' directive globally to suppress this
   message AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server's fully qualified
   domain name, using 127.0.0.1. Set the 'ServerName' directive globally to
   suppress this message [Tue Jun 03 06:47:15.256134 2025] [mpm_event:notice]
   [pid 1:tid 1] AH00489: Apache/2.4.63 (Unix) configured -- resuming normal
   operations [Tue Jun 03 06:47:15.739326 2025] [core:notice] [pid 1:tid 1]
   AH00094: Command line: 'httpd -D FOREGROUND

In a second terminal, we examined the total of 68 forensic events. Here are the
first  Here are the first four of them for illustration.

.. code-block:: console

   # quixote-console -w httpd -F | jq
   {"event": {"context": "14", "number": "343", "process": "runc:[2:INIT]",
   "type": "inode_getattr", "ttd": "3052", "p_ttd": "3052", "task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6",
   "p_task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6", "ts":
   "847743223"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1fdffffffff"}, "inode_getattr": {"path": {"inode": {"uid": "0", "gid":
   "0", "mode": "040755", "s_magic": "0x1021994", "s_id": "tmpfs", "s_uuid":
   "e57e8eaab02749c7a48b835d9c4c10a9"}, "path": {"dev": {"major": "0", "minor":
   "75"}, "type": "namespace", "pathname":
   "/var/lib/Quixote/Magazine/httpd/rootfs/dev"}}}} {"event": {"context": "14",
   "number": "344", "process": "runc:[2:INIT]", "type": "file_fcntl", "ttd":
   "3052", "p_ttd": "3052", "task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6",
   "p_task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6", "ts":
   "847778102"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1fdffffffff"}, "file_fcntl": {"file": {"flags": "2097152", "inode":
   {"uid": "0", "gid": "0", "mode": "040755", "s_magic": "0x1021994", "s_id":
   "tmpfs", "s_uuid": "e57e8eaab02749c7a48b835d9c4c10a9"}, "path": {"dev":
   {"major": "0", "minor": "75"}, "type": "namespace", "pathname":
   "/var/lib/Quixote/Magazine/httpd/rootfs/dev"}, "digest":
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}, "cmd":
   "3"}} {"event": {"context": "14", "number": "358", "process":
   "runc:[2:INIT]", "type": "file_fcntl", "ttd": "3052", "p_ttd": "3052",
   "task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6",
   "p_task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6", "ts":
   "848047872"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1fdffffffff"}, "file_fcntl": {"file": {"flags": "98304", "inode": {"uid":
   "0", "gid": "0", "mode": "040755", "s_magic": "0x1021994", "s_id": "tmpfs",
   "s_uuid": "e57e8eaab02749c7a48b835d9c4c10a9"}, "path": {"dev": {"major": "0",
   "minor": "75"}, "type": "namespace", "pathname":
   "/var/lib/Quixote/Magazine/httpd/rootfs/dev"}, "digest":
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}, "cmd":
   "3"}} {"event": {"context": "14", "number": "359", "process":
   "runc:[2:INIT]", "type": "inode_mkdir", "ttd": "3052", "p_ttd": "3052",
   "task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6",
   "p_task_id":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6", "ts":
   "848064933"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1fdffffffff"}, "inode_mkdir": {"dir": {"uid": "0", "gid": "0", "mode":
   "040755", "s_magic": "0x1021994", "s_id": "tmpfs", "s_uuid":
   "e57e8eaab02749c7a48b835d9c4c10a9"}, "dentry": {"path": {"dev": {"major":
   "0", "minor": "75"}, "owner":
   "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6",
   "instance": "1", "type": "namespace", "pathname": "/pts"}}, "mode": "0755"}}
   ...
   ...
   ...

We tried to backpropagate the events and relaunch the workload (in the first
terminal).

.. code-block:: console

   # quixote -w httpd -o httpd.model
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
   AH00558: httpd: Could not reliably determine the server’s fully qualified domain
   name, using 127.0.0.1. Set the ’ServerName’ directive globally to suppress
   this message
   [Tue Jun 03 06:37:04.248420 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache
   /2.4.63 (Unix) configured -- resuming normal operations
   [Tue Jun 03 06:37:04.249136 2025] [core:notice] [pid 1:tid 1] AH00094: Command
   line: ’httpd -D FOREGROUND’
   127.0.0.1 - - [03/Jun/2025:06:37:36 +0000] "GET / HTTP/1.1" 304 -
   ^C[Tue Jun 03 06:39:02.019698 2025] [mpm_event:notice] [pid 1:tid 1] AH00491:
   caught SIGTERM, shutting down
   Wrote security model to: httpd.model
   # quixote -w httpd -m httpd.model -e
   time="2025-06-03T06:39:17Z" level=warning msg="unable to terminate initProcess"
   error="operation not permitted"
   ...
   ...
   ...
   # quixote-console -w httpd -M -u > httpd.model
   # quixote -w httpd -m httpd.model -e
   # quixote -w httpd -m httpd.model -e
   httpd: Could not open configuration file /usr/local/apache2/conf/httpd.conf:
   Operation not permitted time="2025-06-03T07:21:20Z" level=warning msg="unable
   to destroy container: unable to remove container state dir: unlinkat
   /run/runc/httpd/state.json: operation not permitted"
   #

Again, we got denied access. This time when inspeced in the ``quixote-console``
we got less forensic events.
   


.. code-block:: console

   # quixote-console -w httpd -F | wc -l
   4

For illustration, we will show one of the generated events.

.. code-block:: console

	{
	  "event": {
		"context": "34",
		"number": "1129",
		"process": "httpd",
		"type": "socket_connect",
		"ttd": "2064",
		"p_ttd": "2061",
		"task_id": "44923b933d77a6fbc903ba3488c6b7ffdc6e7838ddea60fb5b3ec310b71ac454",
		"p_task_id": "0c405f59cd464e9085e3355b2e15609b3d5ce8c1b3571ccb5de017bdded9f2d6",
		"ts": "993627013"
	  },
	  "COE": {
		"uid": "0",
		"euid": "0",
		"suid": "0",
		"gid": "0",
		"egid": "0",
		"sgid": "0",
		"fsuid": "0",
		"fsgid": "0",
		"capeff": "0x200004eb"
	  },
	  "socket_connect": {
		"sock": {
		  "family": "10",
		  "type": "2",
		  "protocol": "17",
		  "owner": "44923b933d77a6fbc903ba3488c6b7ffdc6e7838ddea60fb5b3ec310b71ac454"
		},
		"addr": {
		  "af_inet6": {
			"port": "0",
			"flow": "0",
			"scope": "1201569384",
			"address": "0000000000000000ffffff7f00000000"
		  }
		}
	  }
	}

It shows that the denial was caused by the web server trying to connext to an
IPv6 address.
