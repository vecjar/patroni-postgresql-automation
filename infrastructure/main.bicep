@description('The names of your Virtual Machines.')
param vmNames array

@description('Username for the Virtual Machines.')
param adminUsername string

param authenticationType string

@description('SSH Key or password for the Virtual Machines. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Location for all resources.')
param location string

@description('The size of the VMs.')
param vmSize string

@description('Security Type of the Virtual Machines.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string

@description('Flag to use existing VMs or create new ones.')
param useExistingVMs bool

// Reference existing VMs if useExistingVMs is true
resource existingVM1 'Microsoft.Compute/virtualMachines@2023-09-01' existing = if (useExistingVMs) {
  name: vmNames[0]
}

resource existingVM2 'Microsoft.Compute/virtualMachines@2023-09-01' existing = if (useExistingVMs) {
  name: vmNames[1]
}

resource existingVM3 'Microsoft.Compute/virtualMachines@2023-09-01' existing = if (useExistingVMs) {
  name: vmNames[2]
}

// Module for Virtual Network
module vnetModule './modules/virtualNetwork.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
  }
}

// Module for Network Security Group
module nsgModule './modules/networkSecurityGroup.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
  }
}

// Conditionally create VMs if they do not exist
module vmModule './modules/virtualMachines.bicep' = if (!useExistingVMs) {
  name: 'vmDeployment'
  params: {
    vmNames: vmNames
    adminUsername: adminUsername
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
    vmSize: vmSize
    securityType: securityType
    vnetId: vnetModule.outputs.vnetId
    subnetId: vnetModule.outputs.subnetId
    nsgId: nsgModule.outputs.nsgId
  }
  dependsOn: [
    vnetModule
    nsgModule
  ]
}

module nlbModule './modules/networkLoadBalancer.bicep' = {
  name: 'nlbDeployment'
  params: {
    location: location
    publicIpName: 'myPublicIP'
    subnetId: vnetModule.outputs.subnetId
    backendPoolName: 'myBackendPool'
    healthProbeName: 'myHealthProbe'
    loadBalancerName: 'myLoadBalancer'
    networkInterfaceIds: vmModule.outputs.networkInterfaceIds
  }
  dependsOn: [
    vmModule
  ]
}

// Output the virtual network and subnet IDs for verification
output vnetId string = vnetModule.outputs.vnetId
output subnetId string = vnetModule.outputs.subnetId
output networkInterfaceIds array = vmModule.outputs.networkInterfaceIds
