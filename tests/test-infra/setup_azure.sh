#!/usr/bin/env bash

#
# Copyright 2021 The Dapr Authors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Set environmental variables to use Cosmos DB as state store
export DAPR_TEST_STATE_STORE=cosmosdb
export DAPR_TEST_QUERY_STATE_STORE=cosmosdb_query

# Write into the GitHub Actions environment
echo "DAPR_TEST_STATE_STORE=${DAPR_TEST_STATE_STORE}" >> $GITHUB_ENV
echo "DAPR_TEST_QUERY_STATE_STORE=${DAPR_TEST_QUERY_STATE_STORE}" >> $GITHUB_ENV

# Get the credentials for Cosmos DB
COSMOSDB_MASTER_KEY=$(
  az cosmosdb keys list \
    --name "${TEST_PREFIX}db" \
    --resource-group "$TEST_RESOURCE_GROUP" \
    --query "primaryMasterKey" \
    -o tsv
)
kubectl create secret generic cosmosdb-secret \
  --namespace=$DAPR_NAMESPACE \
  --from-literal=url=https://${TEST_PREFIX}db.documents.azure.com:443/ \
  --from-literal=primaryMasterKey=${COSMOSDB_MASTER_KEY}


# TODO: SERVICE BUS
