@description('Name of the Cosmos DB database account resource')
param databaseAccountName string

@description('ID of the role to assign')
param databaseRoleId string

@description('ID of the principal')
param principalId string

@description('ID of the scope (database account or database or collection)')
param scope string

resource rbacAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-04-01-preview' = {
  name: '${databaseAccountName}/${guid(databaseAccountName, databaseRoleId, principalId)}'
  properties: {
    roleDefinitionId: databaseRoleId
    principalId: principalId
    scope: scope
  }
}
