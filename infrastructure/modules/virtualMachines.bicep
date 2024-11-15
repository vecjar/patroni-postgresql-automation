@description('Array of Virtual Machine names')
param vmNames array

@description('Admin username for the VMs')
param adminUsername string

@description('Authentication type')
param authenticationType string

@description('Admin password or SSH key')
@secure()
param adminPasswordOrKey string

@description('Ubuntu version for the VMs')
param ubuntuOSVersion string = '22_04-lts'  // Default to 22.04, or set '24_04-lts' for 24.04

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

// Image reference for Ubuntu versions
var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2404': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-lunar'
    sku: '24_04-lts-gen2'
    version: 'latest'
  }
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
      imageReference: imageReference[ubuntuOSVersion]
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

// Loop to create Network Interfaces and Public IP addresses
@batchSize(1)
resource networkInterfaces 'Microsoft.Network/networkInterfaces@2023-09-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}NetInt'
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
            id: publicIPAddresses[i].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
    enableIPForwarding: true // Enable IP forwarding here
  }
}]

// Loop to create Public IP addresses
@batchSize(1)
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2023-09-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}PublicIP'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${uniqueString(resourceGroup().id)}')
    }
    idleTimeoutInMinutes: 4
  }
}]
