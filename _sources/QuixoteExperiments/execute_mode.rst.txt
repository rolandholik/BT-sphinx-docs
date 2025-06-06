
Execute mode
============

.. _execute_mode:

In execute mode we tried to create a model for ``vim`` --- the text editor.


First, we opened the editor in the modeled workload.

.. code-block:: console

   # quixote -w vimtest -o vimtest.model -X -- vim testfile.txt

This opened the vim editor.

.. code-block:: console

   1 test
   ~
   ~
   ~
   "testfile.txt" 1L, 5B                            1,1 All

After closing the editor, the model got saved to ``vimtext.model``.

.. code-block:: console

   # quixote -w vimtest -o vimtest.model -X -- vim testfile.txt
   Wrote security model to: vimtest.model


Then we tried executing the model in enforced mode.

.. code-block:: console

   # quixote -w vimtest -o vimtest.model -X -- vim testfile.txt
   Wrote security model to: vimtest.model
   # quixote -w vimtest -m vimtest.model -e -X -- vim testfile.txt
   Vim: Caught deadly signal SEGV
   Vim: Finished.

We got segmentation fault.

To see what caused the segmentation fault, we relaunched the workload and
inspected the its forensic violations using ``quixote-console``.

.. code-block:: console

   # quixote-console -w vimtest -F | jq
   {
     "event": {
       "context": "3",
       "number": "324",
       "process": "vim",
       "type": "file_open",
       "ttd": "38256",
       "p_ttd": "38255",
       "task_id": "41368eef19100357953bfc6a01f5521e703d23d3c148a73ab0dda83938bb8756",
       "p_task_id": "647110c3e238dca7ec813f0998fa58cd91c2a60d8e19f5bbe048f9566f1cb189",
       "ts": "326520852"
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
           "mode": "0100711",
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
           "pathname": "/root/.viminfo"
         },
         "digest": "f1ad09b640716c0464598839f4262b02d4626af76a70458c37eb90323f051636"
       }
     }
   }

As we can see from the log above, the forensic event, that caused the
segmentation fault was the editor trying to access ``/root/.viminfo``.

We generated pseudonym for the path and appended it to the original model.

.. code-block:: console

   # generate-pseudonym -P -i /root/.viminfo
   pseudonym 27a1f6c74b751a0fca48a35afeebbbc75f78f8422d346618282c1b6d013e658f

When we tried to execute the update model, we got segmentation fault again.

.. code-block:: console

   # quixote -w vimtest -o vimtest.model -X -- vim testfile.txt
   Wrote security model to: vimtest.model
   # quixote -w vimtest -m vimtest.model -e -X -- vim testfile.txt
   Vim: Caught deadly signal SEGV
   Vim: Finished.
   # quixote -w vimtest -m vimtest.model -e -X -- vim testfile.txt
   Vim: Caught deadly signal SEGV
   Vim: Finished.
