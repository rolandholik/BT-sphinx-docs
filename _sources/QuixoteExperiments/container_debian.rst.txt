
Container mode - Debian
=======================

.. _container_debian:

In document, we experimented with modeling of Debian Trixie container. We used 2
terminals, first (Terminal n.1) for running the workload and second (Terminal
n.2) for its interrogation. All models end trajectories generated during the
experiments can be downloaded by clicking on the redirect links.

Debain Trixie
~~~~~~~~~~~~~

.. warning::
   On some, seemingly random, occasions we got error where a message like

   .. code-block:: console

      time="2026-05-31T18:55:57Z" level=warning msg="unable to get oom kill count" error="openat2 /sys/fs/cgroup/user.slice/user-1000.slice/trixie/memory.events: operation not permitted"
      time="2026-05-29T18:59:05Z" level=warning msg="unable to terminate initProcess" error="operation not permitted"
      time="2026-05-29T18:59:05Z" level=warning msg="unable to destroy container: unable to remove container's cgroup: rmdir /sys/fs/cgroup/user.slice/user-1000.slice/trixie: operation not permitted"
      time="2026-05-29T18:59:05Z" level=error msg="runc run failed: unable to start container process: unable to apply cgroup configuration: failed to write 6086: openat2 /sys/fs/cgroup/user.slice/user-1000.slice/trixie/cgroup.procs: operation not permitted"

   got displayed after executing the container and the execution got stuck. We
   were able to resolve this by running the following sequence, in that exact
   order:

   .. code-block:: console

      # runc delete trixie
      # runc kill trixie

   It was a strange unreproducible behavior, that did not occur on a not
   enforced, unsealed workloads.

Preparation
...........

Before beginning with out modeling experiment, we created a small script, we
will try to create a model for (*fileops.sh*).

.. code-block:: shell

   #!/bin/bash

   # Create a working directory
   mkdir -p /tmp/demo_dir
   echo "Created /tmp/demo_dir"
   
   # Create a file
   echo "Hello from the container" > /tmp/demo_dir/file.txt
   echo "Created file.txt"
   
   # Read the file
   echo "Contents of file.txt:"
   cat /tmp/demo_dir/file.txt
   
   # Copy the file
   cp /tmp/demo_dir/file.txt /tmp/demo_dir/file_copy.txt
   echo "Copied file to file_copy.txt"
   
   # Move the file
   mv /tmp/demo_dir/file_copy.txt /tmp/demo_dir/file_moved.txt
   echo "Moved file_copy.txt to file_moved.txt"
   
   # Append to the file
   echo "Appending a line..." >> /tmp/demo_dir/file.txt
   
   # Show updated content
   echo "Updated file.txt:"
   cat /tmp/demo_dir/file.txt
   
   # Delete the moved file
   rm /tmp/demo_dir/file_moved.txt
   echo "Deleted file_moved.txt"
   
   echo "=== Done ==="

:download:`Download fileops.sh <../_static/container/container-trixie/fileops.sh>`

We copied the script to the Quixote bundle directory and made the script
executable.

.. code-block:: console

   # cp fileops.sh /var/lib/Quixote/Magazine/trixie/rootfs/fileops.sh
   # chmod +x fileops.sh


Modeling
........

We started by launching the container, exiting the container and executing the
script.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -o trixie.model
   root@umoci-default:/# ./fileops.sh 
   Created /tmp/demo_dir
   Created file.txt
   Contents of file.txt:
   Hello from the container
   Copied file to file_copy.txt
   Moved file_copy.txt to file_moved.txt
   Updated file.txt:
   Hello from the container
   Appending a line...
   Deleted file_moved.txt
   === Done ===
   root@umoci-default:/# exit
   exit
   Wrote security model to: trixie.model

:download:`Download model<../_static/container/container-trixie/trixie.model>`

With the model created we tried to run it in enforced mode.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model -e
   root@umoci-default:/# ./fileops.sh 
   Created /tmp/demo_dir
   Created file.txt
   Contents of file.txt:
   Hello from the container
   Copied file to file_copy.txt
   Moved file_copy.txt to file_moved.txt
   Updated file.txt:
   Hello from the container
   Appending a line...
   Deleted file_moved.txt
   === Done === 

The script executed successfully, without generating any violations.

So we tried if the result was reproducible, restarted the container and ran the
script again.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model -e
   root@umoci-default:/# ./fileops.sh
   bash: fork: Operation not permitted
   root@umoci-default:/#

We were denied permission.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F > saved.file

:download:`Download forensics <../_static/container/container-trixie/trixie_1.json>`

This show us, that the issue was *.bash_history* which got appended after
exiting the previous attempt.

Since this issue will occur every time, when a bash shell in the container
restarts, we decided to create a pseudonym for the file.

.. code-block:: console
   :caption: Terminal n.2

   # generate-pseudonym -i -T trixie_1.json
   pseudonym 17a0dce53b9018e2559b9180c5434668a0dfde6ca4e7010ad02821eb6418fa37

We exited the container and appended the pseudonym to the model.

:download:`Download forensics <../_static/container/container-trixie/trixie.model.p>`

We tried to run the container with the updated model.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.p -e
   root@umoci-default:/# ./fileops.sh
   bash: fork: Operation not permitted
   root@umoci-default:/#

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F > saved.file

:download:`Download forensics <../_static/container/container-trixie/trixie_2.json>`

The same violation remains. This gives us 2 options, either update the model before
each container execution, so that the *.bash_history* file in the model would
match the one in the model. Or disable logging of bash shell history for the
container.

We decided for the latter option. So we added ``unset HISTFILE`` to
/root/.bashrc in the container *rootfs*.

.. code-block:: console
   :caption: Terminal n.1

   echo "unset HISTFILE" >> /var/lib/Quixote/Magazine/trixie/rootfs/root/.bashrc 

We re-ran the container.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.p -e
   root@umoci-default:/# ./fileops.sh
   bash: fork: Operation not permitted
   root@umoci-default:/#

The violation was expected, since we changed the bash config. We backpropagated
the violation into the model.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F > saved.file
   # quixote-console -w trixie -M -u > trixie.model.up

:download:`Download forensics <../_static/container/container-trixie/trixie_3.json>`

:download:`Download model <../_static/container/container-trixie/trixie.model.up>`

We re-ran the container with the updated model.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up -e
   root@umoci-default:/# ./fileops.sh
   Created /tmp/demo_dir
   Created file.txt
   Contents of file.txt:
   Hello from the container
   Copied file to file_copy.txt
   Moved file_copy.txt to file_moved.txt
   Updated file.txt:
   Hello from the container
   Appending a line...
   Deleted file_moved.txt
   === Done ===
   root@umoci-default:/#

It worked!

We exited the container and made changes to the script to simulate an attack.

We created file ``malicious.sh`` at the root of the container's rootfs.

.. code-block:: shell

   #!/bin/bash

   echo "Malicious"

:download:`Download malicious.sh <../_static/container/container-trixie/malicious.sh>`

And modified the script to use this file.

.. code-block:: shell
   
   #!/bin/bash

   # Create a working directory
   mkdir -p /tmp/demo_dir
   echo "Created /tmp/demo_dir"
   
   # Create a file
   echo "Hello from the container" > /tmp/demo_dir/file.txt
   echo "Created file.txt"
   
   # Read the file
   echo "Contents of file.txt:"
   cat /tmp/demo_dir/file.txt
   
   # Copy the file
   cp /malicious.sh /tmp/demo_dir/file_copy.txt
   echo "Copied file to file_copy.txt"
   
   bash /tmp/demo_dir/file_copy.txt

:download:`Download fileops.sh <../_static/container/container-trixie/fileops2.sh>`

We relaunched the container and executed the new script.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up -e
   root@umoci-default:/# ./fileops.sh
   bash: ./fileops.sh: Operation not permitted
   root@umoci-default:/#

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file

:download:`Download forensics <../_static/container/container-trixie/trixie_4.json>`

The violations show that the ``fileops.sh`` violated the model, as expected.

This example showed us how ``quixote`` policy could save a workload from
commiting malicious actions.

We continued by appending the violations to the model.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -M -u trixie.model.up2

And executed the model in relaunched container.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up2 -e
   root@umoci-default:/# ./fileops.sh
   root@umoci-default:/# 

We don’t see what happened from the terminal output directly, however, there
were violations in the ``quixote-console`` output.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file

:download:`Download forensics <../_static/container/container-trixie/trixie_5.json>`

Inspection of the directory, where the malicious file was supposed to be copied
showed that the malicious file indeed didn't get copied.

.. code-block:: console
   :caption: Terminal n.2

   # ls /var/lib/Quixote/Magazine/trixie/rootfs/tmp/demo_dir/
   file.txt
   
Next, we launched the container in sealed (not enforced) mode.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up3
   root@umoci-default:/# ./fileops.sh
   Created /tmp/demo_dir
   Created file.txt
   Contents of file.txt:
   Hello from the container
   Copied file to file_copy.txt
   Malicious
   root@umoci-default:/# 

And tired to adopt the model to the new ``fileops.sh`` script.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file
   # quixote-console -w trixie -M -u > trixie.model.up4

:download:`Download forensics <../_static/container/container-trixie/trixie_6.json>`

:download:`Download forensics <../_static/container/container-trixie/trixie.model.up4>`

Then we relaunched the container with the updated model (enforced) and executed
the ``fileops.sh``.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up4 -e
   root@umoci-default:/# ./fileops.sh
   Created /tmp/demo_dir
   ./fileops.sh: line 8: /tmp/demo_dir/file.txt: Operation not permitted
   Created file.txt
   Contents of file.txt:
   ./fileops.sh: fork: Operation not permitted
   root@umoci-default:/#

Inspection of the violations showed that the workload was denied to open the
*file.txt*.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file

:download:`Download forensics <../_static/container/container-trixie/trixie_7.json>`

We persisted and backpropagated the violation.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -M -u trixie.model.up5

:download:`Download forensics <../_static/container/container-trixie/trixie.model.up5>`

We relaunched the container with the updated model.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up5 -e
   root@umoci-default:/# ./fileops.sh
   Created /tmp/demo_dir
   Created file.txt
   Contents of file.txt:
   Hello from the container
   cp: cannot open '/malicious.sh' for reading: Operation not permitted
   Copied file to file_copy.txt

This time we got denial on copying the ``malicious.sh``. We backpropagated the
violation.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file
   # quixote-console -w trixie -M -u trixie.model.up6

:download:`Download forensics <../_static/container/container-trixie/trixie.model.up6>`
:download:`Download forensics <../_static/container/container-trixie/trixie_8.json>`

We relaunched the container.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up6 -e
   root@umoci-default:/# ./fileops.sh
   Created /tmp/demo_dir
   Created file.txt
   Contents of file.txt:
   Hello from the container
   cp: cannot create regular file '/tmp/demo_dir/file_copy.txt': Operation not permitted
   Copied file to file_copy.txt
   Malicious

This time we were denied file creation.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file
   # quixote-console -w trixie -M -u trixie.model.up7

:download:`Download forensics <../_static/container/container-trixie/trixie.model.up7>`
:download:`Download forensics <../_static/container/container-trixie/trixie_9.json>`

We relaunched the container.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up7 -e

The container didn't fully launch and got stuck before even dropping to the
shell.

.. code-block:: console
   :caption: Terminal n.2

   # quixote-console -w trixie -F saved.file

:download:`Download forensics <../_static/container/container-trixie/trixie_10.json>`

The violations seem to be ``runc`` related.

We exited the container and tried to execute the container in non-enforced,
sealed mode one more time.

.. code-block:: console
   :caption: Terminal n.1

   # quixote -w trixie -m trixie.model.up7

Many violations got generated. This is where we concluded our experiment because
of persisting behaviour we couldn't explain.
