#require docker

  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh

  $ commonenv rb-test-bugzilla-review-interaction

  $ cd client
  $ echo foo > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ hg phase --public -r .

  $ bugzilla create-user author@example.com password 'Some Contributor'
  created user 2
  $ bugzilla create-user reviewer@example.com password 'Mozilla Reviewer [:reviewer]'
  created user 3

Create a review request from a regular user

  $ exportbzauth author@example.com password
  $ bugzilla create-bug TestProduct TestComponent 'First Bug'

  $ echo initial > foo
  $ hg commit -m 'Bug 1 - Initial commit to review'
  $ hg --config bugzilla.username=author@example.com push http://localhost:$HGPORT/ > /dev/null

Adding a reviewer should result in a r? flag being set

  $ rbmanage add-reviewer $HGPORT1 1 --user reviewer
  1 people listed on review request
  $ rbmanage publish $HGPORT1 1

  $ bugzilla dump-bug 1
  Bug 1:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://example.com/r/1/
      description: 'MozReview Request: bz://1/mynick'
      flags:
      - id: 1
        name: review
        requestee: reviewer@example.com
        setter: author@example.com
        status: '?'
      id: 1
      summary: 'MozReview Request: bz://1/mynick'
    comments:
    - id: 1
      text: ''
    - id: 2
      text: 'Created attachment 1
  
        MozReview Request: bz://1/mynick'
    - id: 3
      text: '/r/2 - Bug 1 - Initial commit to review
  
  
        Pull down this commit:
  
  
        hg pull review -r 57755461e85f1e3e66738ec2d57f325249897409'
    summary: First Bug

Adding a "Ship It" review will grant r+

  $ exportbzauth reviewer@example.com password
  $ rbmanage create-review $HGPORT1 1 --body-top LGTM --public --ship-it
  created review 1

  $ bugzilla dump-bug 1
  Bug 1:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://example.com/r/1/
      description: 'MozReview Request: bz://1/mynick'
      flags:
      - id: 1
        name: review
        requestee: reviewer@example.com
        setter: author@example.com
        status: '?'
      - id: 2
        name: review
        requestee: null
        setter: reviewer@example.com
        status: +
      id: 1
      summary: 'MozReview Request: bz://1/mynick'
    comments:
    - id: 1
      text: ''
    - id: 2
      text: 'Created attachment 1
  
        MozReview Request: bz://1/mynick'
    - id: 3
      text: '/r/2 - Bug 1 - Initial commit to review
  
  
        Pull down this commit:
  
  
        hg pull review -r 57755461e85f1e3e66738ec2d57f325249897409'
    - id: 4
      text: 'http://example.com/r/1/#review1
  
  
        LGTM'
    summary: First Bug

  $ cd ..

Cleanup

  $ rbmanage stop rbserver
  $ dockercontrol stop-bmo rb-test-bugzilla-review-interaction
  stopped 2 containers