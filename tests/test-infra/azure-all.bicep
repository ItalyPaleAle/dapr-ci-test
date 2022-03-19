targetScope = 'subscription'

@minLength(3)
@description('Prefix for all the resources')
param namePrefix string

@description('The location of the first set of resources')
param location1 string

@description('The location of the second set of resources')
param location2 string

// Deploy the Linux cluster in the first location
resource linuxResources 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: 'Dapr-E2E-${namePrefix}l'
  location: location1
}
module linuxCluster 'azure.bicep' = {
  name: 'linuxCluster'
  scope: linuxResources
  params: {
    namePrefix: '${namePrefix}l'
    location: location1
    enableWindows: false
  }
}

// Deploy the Windows cluster in the second location
resource WindowsResources 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: 'Dapr-E2E-${namePrefix}w'
  location: location2
}
module windowsCluster 'azure.bicep' = {
  name: 'windowsCluster'
  scope: WindowsResources
  params: {
    namePrefix: '${namePrefix}w'
    location: location2
    enableWindows: true
  }
}
