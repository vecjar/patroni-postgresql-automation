@description('Array of Virtual Machine names')
param vmNames array

@description('Admin username for the VMs')
param adminUsername string

@description('Authentication type')
param authenticationType string

@description('Admin password or SSH key')
@secure()
param adminPasswordOrKey string

@description('Location for the VMs')
param location string

@description('VM size')
param vmSize string

@description('Security type for VMs')
param securityType string

@description('Virtual Network ID')
param vnetId string

@description('Subnet ID')
param subnetId string

@description('Network Security Group ID')
param nsgId string

// Image reference for Oracle Linux 9
var imageReference = {
  publisher: 'Oracle'
  offer: 'Oracle-Linux'
  sku: 'ol94-lvm-gen2'
  version: '9.4.5'
}

// OS Disk type and settings
var osDiskType = 'Standard_LRS'

// Linux configuration for SSH authentication
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

// Security profile for the VM
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

// Loop to create Public IP addresses
@batchSize(1)
resource publicIPs 'Microsoft.Network/publicIPAddresses@2023-09-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-publicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}]

// Loop to create Network Interfaces and associate Public IP addresses
@batchSize(1)
resource networkInterfaces 'Microsoft.Network/networkInterfaces@2023-09-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmName}-NICConfig'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPs[i].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
    enableIPForwarding: true
  }
}]

// Loop to create VMs
@batchSize(1)
resource vms 'Microsoft.Compute/virtualMachines@2023-09-01' = [for (vmName, i) in vmNames: {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces[i].id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: (securityType == 'TrustedLaunch') ? securityProfileJson : null
  }
}]

// Output the network interface IDs after creation
output networkInterfaceIds array = [
  for (vmName, i) in vmNames: networkInterfaces[i].id
]

output publicIPIds array = [
  for (vmName, i) in vmNames: publicIPs[i].id
]
