#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# eGloo specific distribution settings

set -o pipefail
set -e
set -x

SPARK_HOME="$(cd "`dirname "$0"`/.."; pwd)"
MVN="$SPARK_HOME/build/mvn"

# Defaults
HADOOP_PROFILE=hadoop-2.6
HADOOP_VERSION=2.7.0
YARN_VERSION=$HADOOP_VERSION
SCALA=2.11
GIT_REV=$(git rev-parse --short HEAD)
BUILD="manual-${GIT_REV}"

for opt in "$@"
do
    case $opt in
        --build)
        BUILD="b${opt}-${GIT_REV}";;
        --test)
        TEST=true;;
        --scala)
        SCALA=$opt;;
    esac
done

./dev/change-scala-version.sh $SCALA

NAME="--name ${HADOOP_VERSION}-${BUILD}"

# MAKE_ARGS="-Pyarn -P${HADOOP_PROFILE} -Dhadoop.version=${HADOOP_VERSION} -Dscala-${SCALA}"
MAKE_ARGS="-e -Pyarn -Phadoop-provided -Dscala-${SCALA}"
MAKE_ARGS+=" -Phive -Phive-thriftserver -Pspark-ganglia-lgpl"
MAKE_ARGS+=" -Psparkr -Pnetlib-lgpl"

# ./dev/make-distribution.sh --tgz --with-tachyon $NAME $MAKE_ARGS
./dev/make-distribution.sh --tgz $NAME $MAKE_ARGS

if [ ! -z "$TEST" ]; then
  CMD="$MVN $MAKE_ARGS test"
  echo "Running tests..."
  $CMD
fi
