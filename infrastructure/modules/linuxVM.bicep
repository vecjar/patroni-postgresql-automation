param location string
param vmName string
param adminUsername string
@secure()
param adminPassword string

@description('Address space for the VNet')
param addressSpace string = '10.0.0.0/16'

@description('Subnet address prefix')
param subnetPrefix string = '10.0.1.0/24'

@description('Provide the name of the Virtual Network (VNet)')
param vnetName string = 'myVNet'  // Replace with actual VNet name if it exists

@description('Provide the name of the Subnet within the VNet')
param subnetName string = 'mySubnet'  // Replace with actual Subnet name if it exists

// Flag to indicate if new VNet and Subnet should be created
param createVNet bool = true  // Set to 'false' to reuse existing VNet/Subnet

// Reference the existing Virtual Network (if it exists)
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = if (!createVNet) {
  name: vnetName
} 

// Reference the existing Subnet (if it exists)
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = if (!createVNet) {
  name: subnetName
  parent: vnet
} 

// If createVNet is true, deploy the VNet and Subnet
resource vnetCreate 'Microsoft.Network/virtualNetworks@2021-02-01' = if (createVNet) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpace]
    }
  }
}

// If createVNet is true, deploy the Subnet
resource subnetCreate 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = if (createVNet) {
  name: subnetName
  parent: vnetCreate
  properties: {
    addressPrefix: subnetPrefix
  }
}

// NIC Resource (will use existing NIC if it exists, or create a new one if not)
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = if (createVNet) {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: subnetCreate.id  // Reference the subnet created above
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableIPForwarding: true  // Enable IP forwarding at the NIC level
  }
}

// Reference existing NIC if createVNet is false
resource existingNic 'Microsoft.Network/networkInterfaces@2021-02-01' existing = if (!createVNet) {
  name: '${vmName}-nic'  // Assuming NIC is named according to VM name
}

// Virtual Machine Creation (will use existing VM if it exists, or create a new one if not)
resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = if (createVNet) {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v3'  // 4 vCPUs, 8 GB memory
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 30  // 30 GB OS disk size
      }
      imageReference: {
        publisher: 'Canonical' // Replace this to provision Oracle Linux, CentOS, or any other
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id  // Reference the NIC created above
        }
      ]
    }
  }
}

// Reference existing VM if createVNet is false
resource existingVM 'Microsoft.Compute/virtualMachines@2021-07-01' existing = if (!createVNet) {
  name: vmName
}
