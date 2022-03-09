@description('Prefix for all the resources')
param namePrefix string

@description('The location of the resources')
param location string

@description('If enabled, add a Windows node')
param enableWindows bool = false

// Disk size (in GB) for each of the agent pool nodes
// 0 applies the default
var osDiskSizeGB = 0

// Version of Kubernetes
var kubernetesVersion = '1.22.6'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: '${namePrefix}acr'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
  tags: {}
}

resource roleAssignContainerRegistry 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(containerRegistry.id, '${namePrefix}-aks', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: reference('${namePrefix}-aks', '2021-07-01').identityProfile.kubeletidentity.objectId
  }
  scope: containerRegistry
  dependsOn:[
    aks
  ]
}

// Network profile when the cluster has Windows nodes
var networkProfileWindows = {
  networkPlugin: 'azure'
  serviceCidr: '10.0.0.0/16'
  dnsServiceIP: '10.0.0.10'
  dockerBridgeCidr: '172.17.0.1/16'
}

// Network profile when the cluster has only Linux nodes
var networkProfileLinux = {
  networkPlugin: 'kubenet'
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  location: location
  name: '${namePrefix}-aks'
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: '${namePrefix}-dns'
    agentPoolProfiles: concat([
        {
          name: 'agentpool'
          osDiskSizeGB: osDiskSizeGB
          enableAutoScaling: true
          minCount: 2
          maxCount: 3
          vmSize: 'Standard_DS2_v2'
          osType: 'Linux'
          type: 'VirtualMachineScaleSets'
          mode: 'System'
          maxPods: 110
          availabilityZones: [
            '1'
            '2'
            '3'
          ]
          enableNodePublicIP: false
          vnetSubnetID: enableWindows ? aksVNet::defaultSubnet.id : null
          tags: {}
        }
      ], enableWindows ? [
        {
          name: 'winpol'
          osDiskSizeGB: osDiskSizeGB
          enableAutoScaling: true
          minCount: 1
          maxCount: 3
          vmSize: 'Standard_DS2_v2'
          osType: 'Windows'
          type: 'VirtualMachineScaleSets'
          mode: 'User'
          maxPods: 50
          availabilityZones: [
            '1'
            '2'
            '3'
          ]
          nodeLabels: {}
          nodeTaints: []
          enableNodePublicIP: false
          vnetSubnetID: aksVNet::defaultSubnet.id
          tags: {}
        }
      ] : [])
    networkProfile: union({
        loadBalancerSku: 'standard'
      }, enableWindows ? networkProfileWindows : networkProfileLinux)
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: true
      }
      azurepolicy: {
        enabled: false
      }
      azureKeyvaultSecretsProvider: {
        enabled: false
      }
    }
  }
  tags: {}
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource aksVNet 'Microsoft.Network/virtualNetworks@2020-11-01' = if (enableWindows) {
  location: location
  name: '${namePrefix}-vnet'
  properties: {
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.240.0.0/16'
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
  }
  tags: {}

  resource defaultSubnet 'subnets' existing = {
    name: 'default'
  }
}

resource roleAssignVNet 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (enableWindows) {
  name: guid('${aksVNet.id}/subnets/default', '${namePrefix}-vnet', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
    principalId: aks.identity.principalId
  }
  scope: aksVNet::defaultSubnet
}

output controlPlaneFQDN string = aks.properties.fqdn
