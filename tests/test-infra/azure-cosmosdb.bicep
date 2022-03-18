@description('Prefix for all the resources')
param namePrefix string

@description('The location of the resources')
param location string = resourceGroup().location

var databaseAccountName = '${namePrefix}db'

/* Cosmos DB Account */
resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: databaseAccountName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Strong'
    }
    locations: [
      {
        locationName: location
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
  }

  /* Database in Cosmos DB */
  resource database 'sqlDatabases@2021-04-15' = {
    name: 'dapre2e'
    properties: {
      resource: {
        id: 'dapre2e'
      }
      options: {
        throughput: 600
      }
    }

    /* Container "items" */
    resource itemsContainer 'containers@2021-04-15' = {
      name: 'items'
      properties: {
        resource: {
          id: 'items'
          partitionKey: {
            paths: [
              '/partitionKey'
            ]
            kind: 'Hash'
          }
        }
        options: {
          throughput: 600
        }
      }
    }
  
    /* Container "items-query" */
    resource itemsQueryContainer 'containers@2021-04-15' = {
      name: 'items-query'
      properties: {
        resource: {
          id: 'items-query'
          partitionKey: {
            paths: [
              '/partitionKey'
            ]
            kind: 'Hash'
          }
        }
        options: {
          throughput: 600
        }
      }
    }
  }

  /* RBAC role: Data Reader */
  resource dataReaderRole 'sqlRoleDefinitions@2021-10-15' = {
    name: '00000000-0000-0000-0000-000000000001'
    properties: {
      roleName: 'Cosmos DB Built-in Data Reader'
      type: 'BuiltInRole'
      assignableScopes: [
        databaseAccount.id
      ]
      permissions: [
        {
          dataActions: [
            'Microsoft.DocumentDB/databaseAccounts/readMetadata'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/readChangeFeed'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read'
          ]
        }
      ]
    }
  }

  /* RBAC role: Data Contributor */
  resource dataContributorRole 'sqlRoleDefinitions@2021-10-15' = {
    name: '00000000-0000-0000-0000-000000000002'
    properties: {
      roleName: 'Cosmos DB Built-in Data Contributor'
      type: 'BuiltInRole'
      assignableScopes: [
        databaseAccount.id
      ]
      permissions: [
        {
          dataActions: [
            'Microsoft.DocumentDB/databaseAccounts/readMetadata'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
          ]
        }
      ]
    }
  }
}

output accountId string = databaseAccount.id
output accountName string = databaseAccount.name
output dataReaderRoleId string = databaseAccount::dataReaderRole.id
output dataContributorRoleId string = databaseAccount::dataContributorRole.id
