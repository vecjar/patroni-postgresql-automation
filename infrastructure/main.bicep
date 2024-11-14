@description('The names of your Virtual Machines.')
param vmNames array = [
  'simpleLinuxVM1'
  'simpleLinuxVM2'
  'simpleLinuxVM3'
]

@description('Username for the Virtual Machines.')
param adminUsername string = 'azureadmin'

@description('Type of authentication to use on the Virtual Machines. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machines. SSH key is recommended.')
@secure()
param adminPasswordOrKey string = '185duXr$5'

@description('The Ubuntu version for the VMs. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VMs')
param vmSize string = 'Standard_D2s_v3'

@description('Security Type of the Virtual Machines.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

// Flag to use existing VMs or create new ones
@description('Flag to use existing VMs or create new ones.')
param useExistingVMs bool = false  // Set this to 'false' to create new VMs

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
    ubuntuOSVersion: ubuntuOSVersion
    location: location
    vmSize: vmSize
    securityType: securityType
    vnetId: vnetModule.outputs.vnetId
    subnetId: vnetModule.outputs.subnetId
    nsgId: nsgModule.outputs.nsgId
  }
}
