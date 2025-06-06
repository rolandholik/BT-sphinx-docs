
Process mode
============

.. _process_mode:

Just for comparison, we tried to replicate the example from official
documentation: https://github.com/Quixote-Project/TSEM/blob/TSEM-6.12/Documentation/admin-guide/LSM/tsem.rst.

We started by creating the model.

.. code-block:: console

   # quixote -P -w test -o test.model

Then we inspected its trajectory in a second terminal session using
``quixote-console``.

.. code-block:: console

   quixote-console -w test -T 

We got the output with the generated events:

.. code-block:: console

   {"event": {"context": "3", "number": "1", "process": "quixote", "type":
   "capable", "ttd": "2257", "p_ttd": "2257", "task_id":
   "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189",
   "p_task_id":
   "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189", "ts":
   "680001"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0", "egid":
   "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff": "0x1ffffffffff"},
   "capable": {"cap": "8", "opts": "0"}} {"event": {"context": "3", "number":
   "2", "process": "quixote", "type": "task_prctl", "ttd": "2257", "p_ttd":
   "2257", "task_id":
   "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189",
   "p_task_id":
   "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189", "ts":
   "721570"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0", "egid":
   "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff": "0x1ffffffffff"},
   "task_prctl": {"option": "24", "arg2": "33", "arg3": "0", "arg4": "0",
   "arg5": "0"}} {"event": {"context": "3", "number": "3", "process": "quixote",
   "type": "file_open", "ttd": "2257", "p_ttd": "2257", "task_id":
   "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189",
   "p_task_id":
   "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189", "ts":
   "869603"}, "COE": {"uid": "0", "euid": "0", "suid": "0", "gid": "0", "egid":
   "0", "sgid": "0", "fsuid": "0", "fsgid": "0", "capeff": "0x1ffffffffff"},
   "file_open": {"file": {"flags": "32800", "inode": {"uid": "0", "gid": "0",
   "mode": "0100755", "s_magic": "0xef53", "s_id": "sda3", "s_uuid":
   "e896110b42b24dbca89c7caa36961685"}, "path": {"dev": {"major": "8", "minor":
   "3"}, "type": "root", "pathname": "/usr/bin/bash"}, "digest":
   "59474588a312b6b6e73e5a42a59bf71e62b55416b6c9d5e4a6e1c630c2a9ecd4"}}}
   ...
   ...
   ...

We executed ``grep rocinante /etc/passwd`` and exited the shell:

.. code-block:: console

   # quixote -P -w test -o test.model
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   Wrote security model to: test.model

The model for our workload got saved into ``test.model``.

Then we tired to enforce the model and got the following permission denial:

.. code-block:: console

   # quixote -P -w test -o test.model
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   Wrote security model to: test.model
   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted
   # grep rocinante /etc/passwd
   bash: fork: Operation not permitted

We tired to examine, what went wrong using ``quixote-console`` and got the
following output:

.. code-block:: console

   # quixote-console -w test -F | jq
   {
     "event": {
       "context": "5",
       "number": "86",
       "process": "bash",
       "type": "file_open",
       "ttd": "2572",
       "p_ttd": "2571",
       "task_id": "a19fd658e8d728107045f0f9f6546e9bbe2de4aa19d24095053c93ad4df6792f",
       "p_task_id": "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189",
       "ts": "153958885"
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
       "capeff": "0x1fdffffffff"
     },
     "file_open": {
       "file": {
         "flags": "32768",
         "inode": {
           "uid": "0",
           "gid": "0",
           "mode": "0100600",
           "s_magic": "0xef53",
           "s_id": "sda3",
           "s_uuid": "e896110b42b24dbca89c7caa36961685"
         },
         "path": {
           "dev": {
             "major": "8",
             "minor": "3"
           },
           "type": "root",
           "pathname": "/root/.bash_history"
         },
         "digest": "948b402ade828c471fefce85e9ad4d51e3e6fe9402f5bbbbd4d9b2e09f375473"
       }
     }
   }
   {
     "event": {
       "context": "5",
       "number": "89",
       "process": "bash",
       "type": "file_open",
       "ttd": "2572",
       "p_ttd": "2571",
       "task_id": "a19fd658e8d728107045f0f9f6546e9bbe2de4aa19d24095053c93ad4df6792f",
       "p_task_id": "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189",
       "ts": "154265146"
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
       "capeff": "0x1fdffffffff"
     },
     "file_open": {
       "file": {
         "flags": "32768",
         "inode": {
           "uid": "0",
           "gid": "0",
           "mode": "0100644",
           "s_magic": "0xef53",
           "s_id": "sda3",
           "s_uuid": "e896110b42b24dbca89c7caa36961685"
         },
         "path": {
           "dev": {
             "major": "8",
             "minor": "3"
           },
           "type": "root",
           "pathname": "/etc/locale.alias"
         },
         "digest": "8138bbaea6a31dbcd47cca87d5f0a30980d352888374ec894f6dae473b215bde"
       }
     }
   }

This indicates that, the denial was caused by ``bash`` process interacting
with ``/root/.bash_hostory`` and ``/etc/locale.alias``.

We tried to backpropagate the events.

.. code-block:: console

   # quixote-console -w test -M -u > test.model

And re-ran the workload:

.. code-block:: console

   # quixote -P -w test -o test.model
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   Wrote security model to: test.model
   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted
   # grep rocinante /etc/passwd
   bash: fork: Operation not permitted
   exit
   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted

We were yet again met with permission denial. Therefore we tried to generate
pseudonym for the paths and appended them to the ``test.model`` file.

.. code-block:: console

   # generate-pseudonym -P -i /etc/locale.alias
   # pseudonym e3436cf59b887299c3ab9ae0cd6e3106a457955a8fb22c85ec02005e86f125b9
   # generate-pseudonym -i -P /root/.bash_hostory
   # pseudonym afa1b7a0a3a9da80f7ebad6263798506b6b88bb3410510ac3425c96cc87dcaf3

Then we tried to enforce the model again.

.. code-block:: console

   # quixote -P -w test -o test.model
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   Wrote security model to: test.model
   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted
   # grep rocinante /etc/passwd
   bash: fork: Operation not permitted
   exit
   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted
   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted

We were again faced with permission denial.
