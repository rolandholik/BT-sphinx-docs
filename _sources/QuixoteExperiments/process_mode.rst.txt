
Process mode
============

.. _process_mode:

Our experiment was inspired by the example from official documentation:
https://github.com/Quixote-Project/TSEM/blob/TSEM-6.12/Documentation/admin-guide/LSM/tsem.rst.
We used 2 terminals, first (Terminal n.1) for running the workload and second
(Terminal n.2) for its interrogation. All models end trajectories generated
during the experiments can be downloaded by clicking on the redirect links.

We started by creating the security map.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -o test.model

Then we inspected its trajectory in a second terminal session using
``quixote-console``.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w test -T > saved.file

The output showed, that the workload generated unique 155 security events.

:download:`Download trajectory <../_static/process/process_1.json>`

We executed ``grep rocinante /etc/passwd`` and exited the shell:

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -o test.model
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   Wrote security model to: test.model

The model for our workload got saved into ``test.model``.

:download:`Download model <../_static/process/test.model>`

Then we tired to enforce the model.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model -e
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   # cat /etc/passwd
   bash: fork: Operation not permitted
   # grep rocinante /etc/passwd
   bash: fork: Operation not permitted

The model worked as long as we held to the modeled ``grep rocinante
/etc/passwd`` command. When we tried to print contents of *etc/passwd* using
``cat``, we got our first permission denial --- *bash: fork: Operation not
permitted*. The same denial occurred even when running the previously allowed
``grep /etc/passwd`` again.

We tired to examine the security violations using ``quixote-console`` and got
the following output:

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -F > saved.file
   # cat saved.file
   {
     "event": {
       "context": "2",
       "number": "299",
       "process": "bash",
       "type": "inode_getattr",
       "ttd": "1104",
       "p_ttd": "1103",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "251712378776"
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
     "inode_getattr": {
       "path": {
         "inode": {
           "uid": "0",
           "gid": "0",
           "mode": "0100755",
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
           "pathname": "/usr/bin/cat"
         }
       }
     }
   }
   {
     "event": {
       "context": "2",
       "number": "304",
       "process": "bash",
       "type": "file_open",
       "ttd": "1104",
       "p_ttd": "1103",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "251712533564"
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


:download:`Download forensics <../_static/process/process_2.json>`

The output depicts the denied ``cat`` executable and an event likely generated
by cat when trying to read locale configuration.

After exiting the shell and running the enforced model again, we got the denial
``bash: fork: Operation not permitted`` right after launch.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model -e
   bash: fork: Operation not permitted
   # grep rocinante /etc/passwd
   bash: fork: Operation not permitted
   #

And the following violations got generated:

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -F > saved.file
   # cat saved.file
   {
     "event": {
       "context": "14",
       "number": "88",
       "process": "bash",
       "type": "file_open",
       "ttd": "1267",
       "p_ttd": "1266",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "36940888"
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
         "digest": "7eb7770e5e25a62f3fa7c3c7185a7c5780803470e9c46ab401e7e57f95f85ffe"
       }
     }
   }
   {
     "event": {
       "context": "14",
       "number": "91",
       "process": "bash",
       "type": "file_open",
       "ttd": "1267",
       "p_ttd": "1266",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "37068610"
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

:download:`Download forensics <../_static/process/process_3.json>`

Now the issue seems to be *.bash_history* that got updated with last commands
after closing the shell in the Terminal n.1.

So we tried to backpropagate the violations to the original security map:

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w test -M -u > test.model.up

:download:`Download model <../_static/process/test.model.up>`

And relaunched the modeled workload.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up -e
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   # grep deCervantes /etc/hosts
   grep: /etc/hosts: Operation not permitted
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   # grep ext4 /etc/fstab
   grep: /etc/fstab: Operation not permitted
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   # cat /etc/passwd
   bash: fork: Operation not permitted
   # grep rocinante /etc/passwd
   grep rocinante /etc/passwd
   bash: fork: Operation not permitted
   #

The model worked again. When executing ``grep`` the paths that were not part
of the security map got denied, but ``grep /etc/passwd`` was still permitted.
Then we tired to ``cat /etc/passwd`` again and got 5 violations.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -F > saved.file

:download:`Download forensics <../_static/process/process_4.json>`

The violations include all the paths we tried to grep, but for some reason, also
the ``cat`` binary again.

Before exiting the workload shell, we saved the model with the violations
backpropagated.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -M -u > test.model.up2 

:download:`Download model <../_static/process/test.model.up2>`

And relaunched the modeled workload.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -o test.model.up
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #

Firstly, without the latest 5 violations, then with the 5 violations backpropagated.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up2 -e
   bash: fork: Operation not permitted
   #

Interestingly, the modeled workload without the backpropagated violations worked
and the model with the violations backpropagated didn't. Running the
backpropagated model, we got 1 violation, that we saved into a file.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -F > saved.file
   # cat saved.file
   {
     "event": {
       "context": "17",
       "number": "88",
       "process": "bash",
       "type": "file_open",
       "ttd": "1369",
       "p_ttd": "1368",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "36988407"
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
         "digest": "513aa9615c7c57e37308d750282423d829d76c698b462b661c4e3191a2d631e6"
       }
     }
   }

:download:`Download forensics <../_static/process/process_5.json>`

Since the violation is the accessing of the *.bash_history* again. This seems
to be the right time to utilize the pseudonym functionality of :term:`TSEM`.

.. code-block:: console
   :caption: Terminal n.2

   # generate-pseudonym -i -T saved.file
   pseudonym 17a0dce53b9018e2559b9180c5434668a0dfde6ca4e7010ad02821eb6418fa37
   # cp test.model.up2 test.model.up2p
   # vim test.model.up2p
   #

:download:`Download model <../_static/process/test.model.up2p>`

We re-ran the modeled workload.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up2p -e
   bash: fork: Operation not permitted
   #

We were met with the same violation. Note, that even the digest of the files is
the same.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -F > saved.file
   # cat.saved.file
   {
     "event": {
       "context": "17",
       "number": "88",
       "process": "bash",
       "type": "file_open",
       "ttd": "1369",
       "p_ttd": "1368",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "36988407"
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
         "digest": "513aa9615c7c57e37308d750282423d829d76c698b462b661c4e3191a2d631e6"
       }
     }
   }

:download:`Download forensics <../_static/process/process_6.json>`

We tried to backpropagate again before exit.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w test -M -u > test.model.up2p2
   #

We appended the pseudonym to the model again.

:download:`Download model <../_static/process/test.model.up2p2>`

Then we re-ran the workload with the updated security map.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up2p2 -e
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #

It seemed to have worked.

We re-ran the modeled workload with the updated model again.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up2p2 -e
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   # grep ext4 /etc/fstab
   UUID=e896110b-42b2-4dbc-a89c-7caa36961685 /               ext4    errors=remount-ro 0
   # grep deCervantes /etc/hosts
   127.0.1.1	deCervantes
   # cat /etc/passwd
   bash: /usr/bin/cat: Operation not permitted
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   # cat /etc/shadow
   bash: /usr/bin/cat: Operation not permitted
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   #

Re-run once again.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up2p2 -e
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #
   exit
   #

We tried to re-ran the modeled workload without the pseudonym.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -P -w test -m test.model.up3 -e
   # grep rocinante /etc/passwd
   rocinante:x:1000:1000:rocinante,,,:/home/rocinante:/bin/bash
   #

:download:`Download model <../_static/process/test.model.up3>`

The model started correctly. The pseudonym doesn't seem to have helped.

Our terminal glitched out, so we had to drop from the ``sudo su`` environment
and go back. Then we re-ran the workload.

.. code-block:: console
   :caption: Terminal n.1

   $ sudo su
   # quixote -P -w test -m test.model.up3 -e
   bash: fork: Operation not permitted
   #

We got denial. So we inspected the violation.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -F > saved.file
   # cat saved.file
   {
     "event": {
       "context": "32",
       "number": "88",
       "process": "bash",
       "type": "file_open",
       "ttd": "2057",
       "p_ttd": "2056",
       "task_id": "094e29687d185cf4eaa48ddebfcda205465ad78df543e361621ea0acf2d4f986",
       "p_task_id": "8b4453f1259f134be62e96853362c8e11698b01063e91527a26c8c8ecad55cfb",
       "ts": "35510019"
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
         "digest": "751bbd42b307cccaaf9673f9721ef70f22676ae31c056df162b86d057f873181"
       }
     }
   }

:download:`Download forensics <../_static/process/process_7.json>`

The violation was the *.bash_history* again. It was because the file had a new
digest and the last backpropagation didn't cover it.
