#!/bin/bash
set -e

function testExitCode() {
  if [ $2 -eq 0 ]
  then
    echo "Successfully passed stage: $1"
  else
    echo "Failed stage: $1"
  fi
}

function buildStage() {
    echo "----------------------- BUILDING $1 -----------------------"
    $2
    testExitCode "BUILD $1"
}

buildStage "LAMBDAS" ./PYTHONPATH=. pytest .
buildStage "GLUE SCRIPTS"
buildStage "TERRAFORM" terraform apply | yes
