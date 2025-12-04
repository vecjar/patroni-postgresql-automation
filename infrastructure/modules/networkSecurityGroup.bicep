@description('Location for the Network Security Group')
param location string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'Dev-NSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAllInbound'
        properties: {
          description: 'Allow limited inbound traffic from secure IPs'
          protocol: 'Tcp'
          sourcePortRange: '1024-65535'
          destinationPortRange: '22'
          sourceAddressPrefix: '203.0.113.5/32'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutbound'
        properties: {
          description: 'Allow outbound HTTP/HTTPS traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80-443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '198.51.100.0/24'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
