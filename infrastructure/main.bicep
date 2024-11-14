@description('The names of your Virtual Machines.')
param vmNames array = [
  'simpleLinuxVM1'
  'simpleLinuxVM2'
  'simpleLinuxVM3'
]

@description('Username for the Virtual Machines.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machines. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machines. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

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

// Module for Virtual Machines
module vmModule './modules/virtualMachines.bicep' = {
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
