  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ hg init client
  $ hg init server
  $ rbmanage rbserver create
  $ rbmanage rbserver repo test-repo http://localhost:$HGPORT/
  $ rbmanage rbserver start $HGPORT1
  $ serverconfig server/.hg/hgrc $HGPORT1
  $ clientconfig client/.hg/hgrc

  $ hg serve -R server -d -p $HGPORT --pid-file hg.pid
  $ cat hg.pid >> $DAEMON_PIDS

Set up repo

  $ cd client
  $ echo foo > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ echo foo2 > foo
  $ hg commit -m 'second commit'

  $ hg phase --public -r 0

Do the initial review

  $ hg push -r 1 --reviewid 123 http://localhost:$HGPORT
  pushing to http://localhost:$HGPORT/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 1 files
  submitting 1 changesets for review
  
  changeset:  1:cd3395bd3f8a
  summary:    second commit
  review:     http://localhost:$HGPORT1/r/2 (pending)
  
  review id:  bz://123/mynick
  review url: http://localhost:$HGPORT1/r/1 (pending)

Pushing with a different review ID will create a "duplicate" review

  $ hg push -r 1 --reviewid 456 http://localhost:$HGPORT
  pushing to http://localhost:$HGPORT/
  searching for changes
  no changes found
  submitting 1 changesets for review
  
  changeset:  1:cd3395bd3f8a
  summary:    second commit
  review:     http://localhost:$HGPORT1/r/4 (pending)
  
  review id:  bz://456/mynick
  review url: http://localhost:$HGPORT1/r/3 (pending)
  [1]

  $ cat .hg/reviews
  u http://localhost:$HGPORT1
  r http://localhost:$HGPORT/
  p bz://123/mynick 1
  p bz://456/mynick 3
  c cd3395bd3f8a2108fb3178d6b1ec6077ca2bdbee 2
  c cd3395bd3f8a2108fb3178d6b1ec6077ca2bdbee 4
  pc cd3395bd3f8a2108fb3178d6b1ec6077ca2bdbee 1
  pc cd3395bd3f8a2108fb3178d6b1ec6077ca2bdbee 3

  $ hg log --template "{reviews % '{get(review, \"url\")}\n'}"
  http://localhost:$HGPORT1/r/2
  http://localhost:$HGPORT1/r/4