#require mozreviewdocker

  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ commonenv

Enable obsolescence so we can test code paths which use it.

  $ cat >> client/.hg/hgrc << EOF
  > [experimental]
  > evolution = all
  > EOF

Create an initial commit.

  $ cd client
  $ echo foo > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ hg phase --public -r .

Add some potential reviewers.

  $ mozreview create-user romulus@example.com password 'Romulus :romulus'
  Created user 6
  $ mozreview create-user remus@example.com password 'Remus :remus'
  Created user 7

We create a user with a name which contains another user name as a prefix to
exercise the code path where multiple users are returned for a query.

  $ mozreview create-user remus2@example.com password 'Remus2 :remus2'
  Created user 8

We create a user who has decided to capitalize their ircnick.

  $ mozreview create-user ryanvm@example.com password 'Ryan :RyanVM'
  Created user 9

Try a bunch of different ways of specifying a reviewer

  $ bugzilla create-bug TestProduct TestComponent 'First Bug'
  $ echo initial > foo
  $ hg commit -m 'Bug 1 - some stuff; r?romulus'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; r?romulus, r?remus'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; r?romulus,r?remus'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; r?romulus, remus'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; r?romulus,remus'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; (r?romulus)'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; (r?romulus,remus)'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; [r?romulus]'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; [r?remus, r?romulus]'
  $ echo blah >> foo
  $ hg commit -m 'Bug 1 - More stuff; r?romulus, r=test-only'
  $ hg push
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  (adding commit id to 10 changesets)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 11 changesets with 11 changes to 1 files
  remote: recorded push in pushlog
  submitting 10 changesets for review
  unrecognized reviewer: test-only
  
  changeset:  11:fcf566e4c32a
  summary:    Bug 1 - some stuff; r?romulus
  review:     http://*:$HGPORT1/r/2 (draft) (glob)
  
  changeset:  12:c62a829e2f0a
  summary:    Bug 1 - More stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/3 (draft) (glob)
  
  changeset:  13:955576a13e6c
  summary:    Bug 1 - More stuff; r?romulus,r?remus
  review:     http://*:$HGPORT1/r/4 (draft) (glob)
  
  changeset:  14:696e908c00aa
  summary:    Bug 1 - More stuff; r?romulus, remus
  review:     http://*:$HGPORT1/r/5 (draft) (glob)
  
  changeset:  15:92e037a5e92f
  summary:    Bug 1 - More stuff; r?romulus,remus
  review:     http://*:$HGPORT1/r/6 (draft) (glob)
  
  changeset:  16:a7c3071c6b54
  summary:    Bug 1 - More stuff; (r?romulus)
  review:     http://*:$HGPORT1/r/7 (draft) (glob)
  
  changeset:  17:7b03b2560ab0
  summary:    Bug 1 - More stuff; (r?romulus,remus)
  review:     http://*:$HGPORT1/r/8 (draft) (glob)
  
  changeset:  18:42c4d67a510e
  summary:    Bug 1 - More stuff; [r?romulus]
  review:     http://*:$HGPORT1/r/9 (draft) (glob)
  
  changeset:  19:2bc874a070ce
  summary:    Bug 1 - More stuff; [r?remus, r?romulus]
  review:     http://*:$HGPORT1/r/10 (draft) (glob)
  
  changeset:  20:bb63798ced0f
  summary:    Bug 1 - More stuff; r?romulus, r=test-only
  review:     http://*:$HGPORT1/r/11 (draft) (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  (visit review url to publish these review requests so others can see them)

  $ rbmanage list-reviewers 2 --draft
  romulus

  $ rbmanage list-reviewers 3 --draft
  remus, romulus

  $ rbmanage list-reviewers 4 --draft
  remus, romulus

  $ rbmanage list-reviewers 5 --draft
  remus, romulus

  $ rbmanage list-reviewers 6 --draft
  remus, romulus

  $ rbmanage list-reviewers 7 --draft
  romulus

  $ rbmanage list-reviewers 8 --draft
  remus, romulus

  $ rbmanage list-reviewers 9 --draft
  romulus

  $ rbmanage list-reviewers 10 --draft
  remus, romulus

  $ rbmanage list-reviewers 11 --draft
  romulus

The review state file should have reviewers recorded

  $ cat .hg/reviewboard/review/10.state
  public False
  reviewers remus,romulus
  status pending

Publishing series during push works

  $ hg push --config reviewboard.autopublish=true
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  no changes found
  submitting 10 changesets for review
  
  changeset:  11:fcf566e4c32a
  summary:    Bug 1 - some stuff; r?romulus
  review:     http://*:$HGPORT1/r/2 (draft) (glob)
  
  changeset:  12:c62a829e2f0a
  summary:    Bug 1 - More stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/3 (draft) (glob)
  
  changeset:  13:955576a13e6c
  summary:    Bug 1 - More stuff; r?romulus,r?remus
  review:     http://*:$HGPORT1/r/4 (draft) (glob)
  
  changeset:  14:696e908c00aa
  summary:    Bug 1 - More stuff; r?romulus, remus
  review:     http://*:$HGPORT1/r/5 (draft) (glob)
  
  changeset:  15:92e037a5e92f
  summary:    Bug 1 - More stuff; r?romulus,remus
  review:     http://*:$HGPORT1/r/6 (draft) (glob)
  
  changeset:  16:a7c3071c6b54
  summary:    Bug 1 - More stuff; (r?romulus)
  review:     http://*:$HGPORT1/r/7 (draft) (glob)
  
  changeset:  17:7b03b2560ab0
  summary:    Bug 1 - More stuff; (r?romulus,remus)
  review:     http://*:$HGPORT1/r/8 (draft) (glob)
  
  changeset:  18:42c4d67a510e
  summary:    Bug 1 - More stuff; [r?romulus]
  review:     http://*:$HGPORT1/r/9 (draft) (glob)
  
  changeset:  19:2bc874a070ce
  summary:    Bug 1 - More stuff; [r?remus, r?romulus]
  review:     http://*:$HGPORT1/r/10 (draft) (glob)
  
  changeset:  20:bb63798ced0f
  summary:    Bug 1 - More stuff; r?romulus, r=test-only
  review:     http://*:$HGPORT1/r/11 (draft) (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  
  publish these review requests now (Yn)? y
  (published review request 1)
  [1]

  $ rbmanage dumpreview 10
  id: 10
  status: pending
  public: true
  bugs:
  - '1'
  commit: null
  submitter: default+5
  summary: Bug 1 - More stuff; [r?remus, r?romulus]
  description: Bug 1 - More stuff; [r?remus, r?romulus]
  target_people:
  - remus
  - romulus
  extra_data:
    p2rb: true
    p2rb.commit_id: 2bc874a070cef1ff62b63e28f3d40a81655fec77
    p2rb.first_public_ancestor: 3a9f6899ef84c99841f546030b036d0124a863cf
    p2rb.identifier: bz://1/mynick
    p2rb.is_squashed: false
  approved: false
  approval_failure: A suitable reviewer has not given a "Ship It!"

Amending a commit should also work. This exercises the update_review_request
code path.

  $ echo blah >> foo
  $ hg commit --amend -m 'Bug 1 - Even more stuff; r?romulus, r?remus'
  $ hg push --config reviewboard.autopublish=true
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 10 changesets for review
  
  changeset:  11:fcf566e4c32a
  summary:    Bug 1 - some stuff; r?romulus
  review:     http://*:$HGPORT1/r/2 (glob)
  
  changeset:  12:c62a829e2f0a
  summary:    Bug 1 - More stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/3 (glob)
  
  changeset:  13:955576a13e6c
  summary:    Bug 1 - More stuff; r?romulus,r?remus
  review:     http://*:$HGPORT1/r/4 (glob)
  
  changeset:  14:696e908c00aa
  summary:    Bug 1 - More stuff; r?romulus, remus
  review:     http://*:$HGPORT1/r/5 (glob)
  
  changeset:  15:92e037a5e92f
  summary:    Bug 1 - More stuff; r?romulus,remus
  review:     http://*:$HGPORT1/r/6 (glob)
  
  changeset:  16:a7c3071c6b54
  summary:    Bug 1 - More stuff; (r?romulus)
  review:     http://*:$HGPORT1/r/7 (glob)
  
  changeset:  17:7b03b2560ab0
  summary:    Bug 1 - More stuff; (r?romulus,remus)
  review:     http://*:$HGPORT1/r/8 (glob)
  
  changeset:  18:42c4d67a510e
  summary:    Bug 1 - More stuff; [r?romulus]
  review:     http://*:$HGPORT1/r/9 (glob)
  
  changeset:  19:2bc874a070ce
  summary:    Bug 1 - More stuff; [r?remus, r?romulus]
  review:     http://*:$HGPORT1/r/10 (glob)
  
  changeset:  22:4edf42122107
  summary:    Bug 1 - Even more stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/11 (draft) (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  
  publish these review requests now (Yn)? y
  (published review request 1)
 
  $ rbmanage list-reviewers 11
  remus, romulus

We should not overwrite manually added reviewers when the revision is pushed
again.

  $ rbmanage add-reviewer 11 --user admin+1
  3 people listed on review request
  $ rbmanage list-reviewers 11 --draft
  admin+1, remus, romulus
  $ hg push --config reviewboard.autopublish=true
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  no changes found
  submitting 10 changesets for review
  
  changeset:  11:fcf566e4c32a
  summary:    Bug 1 - some stuff; r?romulus
  review:     http://*:$HGPORT1/r/2 (glob)
  
  changeset:  12:c62a829e2f0a
  summary:    Bug 1 - More stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/3 (glob)
  
  changeset:  13:955576a13e6c
  summary:    Bug 1 - More stuff; r?romulus,r?remus
  review:     http://*:$HGPORT1/r/4 (glob)
  
  changeset:  14:696e908c00aa
  summary:    Bug 1 - More stuff; r?romulus, remus
  review:     http://*:$HGPORT1/r/5 (glob)
  
  changeset:  15:92e037a5e92f
  summary:    Bug 1 - More stuff; r?romulus,remus
  review:     http://*:$HGPORT1/r/6 (glob)
  
  changeset:  16:a7c3071c6b54
  summary:    Bug 1 - More stuff; (r?romulus)
  review:     http://*:$HGPORT1/r/7 (glob)
  
  changeset:  17:7b03b2560ab0
  summary:    Bug 1 - More stuff; (r?romulus,remus)
  review:     http://*:$HGPORT1/r/8 (glob)
  
  changeset:  18:42c4d67a510e
  summary:    Bug 1 - More stuff; [r?romulus]
  review:     http://*:$HGPORT1/r/9 (glob)
  
  changeset:  19:2bc874a070ce
  summary:    Bug 1 - More stuff; [r?remus, r?romulus]
  review:     http://*:$HGPORT1/r/10 (glob)
  
  changeset:  22:4edf42122107
  summary:    Bug 1 - Even more stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/11 (draft) (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  
  publish these review requests now (Yn)? y
  (published review request 1)
  [1]
  $ rbmanage list-reviewers 11
  admin+1, remus, romulus

We should not overwrite manually added reviewers if the revision is amended
and pushed with no reviewers specified.

  $ rbmanage list-reviewers 11
  admin+1, remus, romulus
  $ echo blah >> foo
  $ hg commit --amend -m 'Bug 1 - Amended stuff'
  $ hg push --config reviewboard.autopublish=true
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 10 changesets for review
  
  changeset:  11:fcf566e4c32a
  summary:    Bug 1 - some stuff; r?romulus
  review:     http://*:$HGPORT1/r/2 (glob)
  
  changeset:  12:c62a829e2f0a
  summary:    Bug 1 - More stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/3 (glob)
  
  changeset:  13:955576a13e6c
  summary:    Bug 1 - More stuff; r?romulus,r?remus
  review:     http://*:$HGPORT1/r/4 (glob)
  
  changeset:  14:696e908c00aa
  summary:    Bug 1 - More stuff; r?romulus, remus
  review:     http://*:$HGPORT1/r/5 (glob)
  
  changeset:  15:92e037a5e92f
  summary:    Bug 1 - More stuff; r?romulus,remus
  review:     http://*:$HGPORT1/r/6 (glob)
  
  changeset:  16:a7c3071c6b54
  summary:    Bug 1 - More stuff; (r?romulus)
  review:     http://*:$HGPORT1/r/7 (glob)
  
  changeset:  17:7b03b2560ab0
  summary:    Bug 1 - More stuff; (r?romulus,remus)
  review:     http://*:$HGPORT1/r/8 (glob)
  
  changeset:  18:42c4d67a510e
  summary:    Bug 1 - More stuff; [r?romulus]
  review:     http://*:$HGPORT1/r/9 (glob)
  
  changeset:  19:2bc874a070ce
  summary:    Bug 1 - More stuff; [r?remus, r?romulus]
  review:     http://*:$HGPORT1/r/10 (glob)
  
  changeset:  24:6f4a14de0f3d
  summary:    Bug 1 - Amended stuff
  review:     http://*:$HGPORT1/r/11 (draft) (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  
  publish these review requests now (Yn)? y
  (published review request 1)

  $ rbmanage list-reviewers 11
  admin+1, remus, romulus

Amending a commit with reviewers specified will reset the reviewers back to
those specified in the commit summary.

  $ echo blah >> foo
  $ hg commit --amend -m 'Bug 1 - Amended stuff; r?romulus, r?remus'
  $ hg push --config reviewboard.autopublish=true
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  submitting 10 changesets for review
  
  changeset:  11:fcf566e4c32a
  summary:    Bug 1 - some stuff; r?romulus
  review:     http://*:$HGPORT1/r/2 (glob)
  
  changeset:  12:c62a829e2f0a
  summary:    Bug 1 - More stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/3 (glob)
  
  changeset:  13:955576a13e6c
  summary:    Bug 1 - More stuff; r?romulus,r?remus
  review:     http://*:$HGPORT1/r/4 (glob)
  
  changeset:  14:696e908c00aa
  summary:    Bug 1 - More stuff; r?romulus, remus
  review:     http://*:$HGPORT1/r/5 (glob)
  
  changeset:  15:92e037a5e92f
  summary:    Bug 1 - More stuff; r?romulus,remus
  review:     http://*:$HGPORT1/r/6 (glob)
  
  changeset:  16:a7c3071c6b54
  summary:    Bug 1 - More stuff; (r?romulus)
  review:     http://*:$HGPORT1/r/7 (glob)
  
  changeset:  17:7b03b2560ab0
  summary:    Bug 1 - More stuff; (r?romulus,remus)
  review:     http://*:$HGPORT1/r/8 (glob)
  
  changeset:  18:42c4d67a510e
  summary:    Bug 1 - More stuff; [r?romulus]
  review:     http://*:$HGPORT1/r/9 (glob)
  
  changeset:  19:2bc874a070ce
  summary:    Bug 1 - More stuff; [r?remus, r?romulus]
  review:     http://*:$HGPORT1/r/10 (glob)
  
  changeset:  26:3d7e903b90b0
  summary:    Bug 1 - Amended stuff; r?romulus, r?remus
  review:     http://*:$HGPORT1/r/11 (draft) (glob)
  
  review id:  bz://1/mynick
  review url: http://*:$HGPORT1/r/1 (draft) (glob)
  
  publish these review requests now (Yn)? y
  (published review request 1)

  $ rbmanage list-reviewers 11
  remus, romulus

Unrecognized reviewers should be ignored

  $ hg phase --public -r .
  $ bugzilla create-bug TestProduct TestComponent 'Second Bug'
  $ echo blah >> foo
  $ hg commit -m 'Bug 2 - different stuff; r?cthulhu'
  $ hg push --config reviewboard.autopublish=true --reviewid 2
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  submitting 1 changesets for review
  unrecognized reviewer: cthulhu
  
  changeset:  27:3e01c2b3cff2
  summary:    Bug 2 - different stuff; r?cthulhu
  review:     http://*:$HGPORT1/r/13 (draft) (glob)
  
  review id:  bz://2/mynick
  review url: http://*:$HGPORT1/r/12 (draft) (glob)
  (review requests lack reviewers; visit review url to assign reviewers)
  
  publish these review requests now (Yn)? y
  (published review request 12)
  $ rbmanage list-reviewers 12
  

Reviewer identification should be case insensitive.

  $ echo blah >> foo
  $ hg commit -m 'Bug 2 - better stuff; r?ryanvm'
  $ hg push --config reviewboard.autopublish=true -c 28
  pushing to ssh://*:$HGPORT6/test-repo (glob)
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  submitting 1 changesets for review
  
  changeset:  28:46d3dc1774f5
  summary:    Bug 2 - better stuff; r?ryanvm
  review:     http://*:$HGPORT1/r/13 (draft) (glob)
  
  review id:  bz://2/mynick
  review url: http://*:$HGPORT1/r/12 (draft) (glob)
  
  publish these review requests now (Yn)? y
  (published review request 12)

  $ rbmanage list-reviewers 13
  RyanVM


Cleanup

  $ mozreview stop
  stopped 10 containers
