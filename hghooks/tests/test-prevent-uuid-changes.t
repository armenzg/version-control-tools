  $ hg init server
  $ cat >> server/.hg/hgrc << EOF
  > [hooks]
  > pretxnchangegroup.prevent_uuid_changes = python:mozhghooks.prevent_uuid_changes.hook
  > EOF

  $ hg init client
  $ cd client
  $ echo "uuid(abc123)" > original.idl
  $ hg commit -A -m 'Add original.idl; ba=me'
  adding original.idl
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  You've signaled approval for the binary change(s) in your push, thanks for the extra caution.

Editing a UUID without ba= should fail

  $ echo "uuid(def456)" > original.idl
  $ hg commit -m 'Changing UUID'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  
  
  ************************** ERROR ****************************
  
  *** IDL file original.idl altered in changeset 5475ca91db3f***
  
  Changes to IDL files in this repo require you to provide binary change approval in your top comment in the form of ba=... (or, more accurately, ba\S*=...)
  This is to ensure that UUID changes (or method changes missing corresponding UUID change) are caught early, before release.
  
  *************************************************************
  
  
  transaction abort!
  rollback completed
  abort: pretxnchangegroup.prevent_uuid_changes hook failed
  [255]

Editing a UUID with ba= should pass

  $ hg -q commit --amend -m 'Changing UUID; ba=me'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  You've signaled approval for the binary change(s) in your push, thanks for the extra caution.

Editing .idl file with UUID with other files and no ba= should fail

  $ echo "uuid(something here)" > testfile1.idl
  $ hg commit -A -m 'adding testfile1'
  adding testfile1.idl
  $ echo "checkin2" > testfile2.txt
  $ hg commit -A -m 'testfile2'
  adding testfile2.txt
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  
  
  ************************** ERROR ****************************
  
  *** IDL file testfile1.idl altered in changeset ddac17c4b26e***
  
  Changes to IDL files in this repo require you to provide binary change approval in your top comment in the form of ba=... (or, more accurately, ba\S*=...)
  This is to ensure that UUID changes (or method changes missing corresponding UUID change) are caught early, before release.
  
  *************************************************************
  
  
  transaction abort!
  rollback completed
  abort: pretxnchangegroup.prevent_uuid_changes hook failed
  [255]

Adding ba= anywhere in the push will get through the hook

  $ hg -q commit --amend -m 'Unrelated commit; ba=approver'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  You've signaled approval for the binary change(s) in your push, thanks for the extra caution.

uuid( in a non-idl file shouldn't be screened by the hook

  $ echo "uuid(ignored)" > ignored.txt
  $ hg commit -A -m 'adding ignored.txt'
  adding ignored.txt
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

Removing uuid() from an .idl file without ba= should fail

  $ echo "not idl" > original.idl
  $ hg commit -m 'removing uuid'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  
  
  ************************** ERROR ****************************
  
  *** IDL file original.idl altered in changeset 72d6c9de6844***
  
  Changes to IDL files in this repo require you to provide binary change approval in your top comment in the form of ba=... (or, more accurately, ba\S*=...)
  This is to ensure that UUID changes (or method changes missing corresponding UUID change) are caught early, before release.
  
  *************************************************************
  
  
  transaction abort!
  rollback completed
  abort: pretxnchangegroup.prevent_uuid_changes hook failed
  [255]

Removing UUID with ba= approval should pass

  $ hg -q commit --amend -m 'Removing UUID; ba=me'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  You've signaled approval for the binary change(s) in your push, thanks for the extra caution.

Removing an .idl with UUID without approval should fail

  $ echo "uuid(123)" > existing.idl
  $ hg commit -A -m 'adding existing.idl; ba=me'
  adding existing.idl
  $ hg push ../server >/dev/null
  $ hg rm existing.idl
  $ hg commit -m 'Removing existing'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  
  
  ************************** ERROR ****************************
  
  *** IDL file existing.idl altered in changeset d6eafdbb87e1***
  
  Changes to IDL files in this repo require you to provide binary change approval in your top comment in the form of ba=... (or, more accurately, ba\S*=...)
  This is to ensure that UUID changes (or method changes missing corresponding UUID change) are caught early, before release.
  
  *************************************************************
  
  
  transaction abort!
  rollback completed
  abort: pretxnchangegroup.prevent_uuid_changes hook failed
  [255]

Removing an .idl with UUID with approval should pass

  $ hg -q commit --amend -m 'Removing existing; ba=me'
  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  You've signaled approval for the binary change(s) in your push, thanks for the extra caution.

  $ cd ..

Stripping should not trigger hook

  $ hg init striptest
  $ cd striptest
  $ echo 'uuid(abc123)' > original.idl
  $ hg -q commit -A -m initial
  $ echo 'uuid(def456)' > original.idl
  $ hg commit -m 'Changing UUID; ba=me'
  $ hg -q up -r 0
  $ echo 'uuid(bad789)' > original.idl
  $ hg commit -m 'Bad UUID'
  created new head

  $ cat >> .hg/hgrc << EOF
  > [extensions]
  > strip =
  > 
  > [hooks]
  > pretxnchangegroup.prevent_uuid_changes = python:mozhghooks.prevent_uuid_changes.hook
  > EOF

  $ hg strip -r 1 --no-backup
  $ hg log -T '{rev} {desc}\n'
  1 Bad UUID
  0 initial
