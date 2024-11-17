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

@description('Name for the public IP')
param publicIpName string

@description('Name for the backend pool')
param backendPoolName string

@description('Name for the health probe')
param healthProbeName string

@description('Name for the load balancer')
param loadBalancerName string


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
module vmModule './modules/virtualMachines.bicep' =  {
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

// Ensure public IP is created before load balancer
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Module for Network Load Balancer
module nlbModule './modules/networkLoadBalancer.bicep' = {
  name: 'nlbDeployment'
  params: {
    location: location
    publicIpName: publicIpName
    subnetId: vnetModule.outputs.subnetId
    backendPoolName: backendPoolName
    healthProbeName: healthProbeName
    loadBalancerName: loadBalancerName
    networkInterfaceIds: vmModule.outputs.networkInterfaceIds
  }
  dependsOn: [
    vmModule
    publicIp
  ]
}

// Output the virtual network, subnet IDs, and network interface IDs for verification
output vnetId string = vnetModule.outputs.vnetId
output subnetId string = vnetModule.outputs.subnetId
output networkInterfaceIds array = vmModule.outputs.networkInterfaceIds
