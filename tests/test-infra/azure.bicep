@minLength(3)
@maxLength(11)
@description('Prefix for all the resources')
param namePrefix string

@description('The location of the resources')
param location string = resourceGroup().location

@description('If enabled, add a Windows pool')
param enableWindows bool = false

// Deploy an AKS cluster
module aksModule './azure-aks.bicep' = {
  name: 'azure-aks'
  params: {
    namePrefix: namePrefix
    location: location
    enableWindows: enableWindows
  }
}

// Deploy a Cosmos DB account
module cosmosdbModule './azure-cosmosdb.bicep' = {
  name: 'azure-cosmosdb'
  params: {
    namePrefix: namePrefix
    location: location
  }
}

// This is temporarily turned off while we fix issues with Cosmos DB and RBAC
/*
// Deploy RBAC roles to allow the AKS cluster to access resources in the Cosmos DB account
module cosmosdbRbacModule './azure-cosmosdb-rbac.bicep' = {
  name: 'azure-cosmosdb-rbac'
  params: {
    databaseAccountName: cosmosdbModule.outputs.accountName
    databaseRoleId: cosmosdbModule.outputs.dataContributorRoleId
    principalId: aksModule.outputs.aksManagedIdentityPrincipalId
    scope: cosmosdbModule.outputs.accountId
  }
}

// Outputs
output aksIdentityClientId string = aksModule.outputs.aksManagedIdentityClientId
output aksIdentityPrincipalId string = aksModule.outputs.aksManagedIdentityPrincipalId
*/
