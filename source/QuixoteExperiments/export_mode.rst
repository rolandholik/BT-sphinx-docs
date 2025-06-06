
Export mode
===========

.. _export_mode:

In export mode we exported events from an Apache web server container
(subordinate namespace) and from the root namespace to our :term:`MQTT` broker.

Subordinate namespace
~~~~~~~~~~~~~~~~~~~~~

First we exported events from the Apache web server container. Below is the
output from the terminal, where we launched the workload from which we did the
exporting.

.. code-block:: console

 	# quixote-export -w httpd -b broker.dm -t exporthttpd
	AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
	AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1. Set the 'ServerName' directive globally to suppress this message
	AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
	AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1. Set the 'ServerName' directive globally to suppress this message
	[Wed Jun 04 16:07:44.658290 2025] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache/2.4.63 (Unix) configured -- resuming normal operations
	[Wed Jun 04 16:07:44.667372 2025] [core:notice] [pid 1:tid 1] AH00094: Command line: 'httpd -D FOREGROUND'


In the second terminal we examined the message, we have sent to the broker using
``mosquitto_sub`` --- a command line :term:`MQTT` client installed on our host
system.

.. code-block:: console

    # mosquitto_sub -h broker.dm -t exporthttpd -u rocinante -P test {"export":
    {"type": "async_event"}, "event": {"pid": "46701", "tnum": "46711",
    "context": "10", "number": "1612", "process": "httpd", "type": "capable",
    "ttd": "38421", "p_ttd": "38418", "task_id":
    "d47015c8348a55fcd57794bb38b5c9f0f3137a41a60258231f88f5e6a47aff5f",
    "p_task_id":
    "4d85649a939b4479aa0cd638eca1f06c687c645c71e0a2a1a00822d86d22d5c2", "ts":
    "355354768501"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
    "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
    "0x200004eb"}, "capable": {"cap": "5", "opts": "0"}}

    {"export": {"type": "async_event"}, "event": {"pid": "46701", "tnum":
    "46711", "context": "10", "number": "1613", "process": "httpd", "type":
    "task_kill", "ttd": "38421", "p_ttd": "38418", "task_id":
    "d47015c8348a55fcd57794bb38b5c9f0f3137a41a60258231f88f5e6a47aff5f",
    "p_task_id":
    "4d85649a939b4479aa0cd638eca1f06c687c645c71e0a2a1a00822d86d22d5c2", "ts":
    "355354781081"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
    "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
    "0x200004eb"}, "task_kill": {"target":
    "d47015c8348a55fcd57794bb38b5c9f0f3137a41a60258231f88f5e6a47aff5f", "sig":
    "15", "cross_ns": "0"}}
	...
	...
	...


Root namespace
~~~~~~~~~~~~~~
Next, we exported events from the root modeling namespace. Before doing so, we
had to reboot our Ubuntu system with ``tsem_mode=root_export_only`` kernel
command line option. This can be done by adding following to the
``/etc/default/grub``.

.. code-block:: console

   GRUB_CMDLINE_LINUX_DEFAULT="tsem_mode=root_export_only"

After setting the kernel command line option, we rebooted the system. It took
significantly longer, than reboot with ``tsem_mode`` set to ``no_root_modelin``.
The difference, in this case, was approximately 80 seconds.

When the system finaly booted, we were able to do the event exporting.

.. code-block:: console

   # quixote-export -R -w test -b broker.dm -t rootexport
   #

The ``quixote-export`` exported all the events from the root namespace of our
system and dropped back into the shell, we started from --- to export events
generated after we launched ``quixote-export``, we would have to relaunch it.

In a second terminal, of our host system, we executed the ``mosquitto_sub``
utility.

.. code-block:: console

   # mosquitto_sub -h broker.dm -t rootexport -u rocinante -P test > rootexport.traj
   # cat rootexport.traj | wc -l
   823472

On the side of :term:`MQTT` client, we received 823,472 event descriptions.

.. code-block:: console
   {"export": {"type": "event"}, "event": {"pid": "213", "tnum": "222",
   "context": "0", "number": "29224", "process": "systemd-udevd", "type":
   "file_open", "ttd": "14", "p_ttd": "14", "task_id":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2",
   "p_task_id":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2", "ts":
   "1681046464"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1ffffffffff"}, "file_open": {"file": {"flags": "33024", "inode": {"uid":
   "0", "gid": "0", "mode": "0100644", "s_magic": "0x62656572", "s_id": "sysfs",
   "s_uuid": "42275e4bd2164a89911463e8c7d26ba6"}, "path": {"dev": {"major": "0",
   "minor": "22"}, "type": "root", "pathname":
   "/sys/devices/virtual/tty/tty16/uevent"}, "digest":
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}}}
   {"export": {"type": "event"}, "event": {"pid": "208", "tnum": "217",
   "context": "0", "number": "29225", "process": "systemd-udevd", "type":
   "inode_create", "ttd": "14", "p_ttd": "14", "task_id":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2",
   "p_task_id":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2", "ts":
   "1681049040"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1ffffffffff"}, "inode_create": {"dir": {"uid": "0", "gid": "0", "mode":
   "040755", "s_magic": "0x1021994", "s_id": "tmpfs", "s_uuid":
   "8c7c18fe675349cd9d29e669b231a7bc"}, "dentry": {"path": {"dev": {"major":
   "0", "minor": "25"}, "owner":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2",
   "instance": "90", "type": "root", "pathname": "/udev/data/.#c4:13HBjJnk"}},
   "mode": "0100600"}} {"export": {"type": "event"}, "event": {"pid": "213",
   "tnum": "222", "context": "0", "number": "29226", "process": "systemd-udevd",
   "type": "inode_getattr", "ttd": "14", "p_ttd": "14", "task_id":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2",
   "p_task_id":
   "c00d36d583e479ca6b13bbed2c61d78d07f8e633b6a6f7d2695ff13f14ef84b2", "ts":
   "1681050982"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0",
   "egid": "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff":
   "0x1ffffffffff"}, "inode_getattr": {"path": {"inode": {"uid": "0", "gid":
   "0", "mode": "0100644", "s_magic": "0x62656572", "s_id": "sysfs", "s_uuid":
   "42275e4bd2164a89911463e8c7d26ba6"}, "path": {"dev": {"major": "0", "minor":
   "22"}, "type": "root", "pathname":
   "/sys/devices/virtual/tty/tty16/uevent"}}}}

