#! /bin/sh

( cd "dependency" ; ./run-test.sh )
( cd "refresh" ; ./run-test.sh )
( cd "refresh-embedded" ; ./run-test.sh )

