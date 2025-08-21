// Proyecto Personal DevOps - Infraestructura Simulada con Bicep
// Este archivo simula la configuración de Azure pero no se aplica realmente

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('Nombre del grupo de recursos')
param resourceGroupName string = resourceGroup().name

@description('Nombre de la máquina virtual')
param vmName string = 'vm-sandbox-devops'

@description('Tamaño de la máquina virtual')
@allowed([
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_B2s'
])
param vmSize string = 'Standard_D2s_v3'

@description('Nombre de usuario administrador')
param adminUsername string = 'sandboxadmin'

@description('Contraseña del usuario administrador')
@secure()
param adminPassword string

@description('Nombre del Key Vault')
param keyVaultName string = 'kv-sandbox-devops'

@description('Tags para los recursos')
param tags object = {
  Environment: 'Sandbox'
  Project: 'DevOps-Practice'
  Owner: 'DevOps-Team'
  CostCenter: 'Training'
}

// Variables
var vnetName = 'vnet-sandbox'
var subnetName = 'subnet-sandbox'
var nsgName = 'nsg-sandbox'
var pipName = 'pip-sandbox-vm'
var nicName = 'nic-sandbox-vm'
var osDiskName = 'disk-sandbox-vm-os'
var dataDiskName = 'disk-sandbox-vm-data'

// Red virtual
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 1002
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'SQLServer'
        properties: {
          priority: 1003
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
    ]
  }
}

// IP pública
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: pipName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'sandbox-vm-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Interfaz de red
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

// Disco del sistema operativo
resource osDisk 'Microsoft.Compute/disks@2023-09-01' = {
  name: osDiskName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 30
  }
}

// Disco de datos
resource dataDisk 'Microsoft.Compute/disks@2023-09-01' = {
  name: dataDiskName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 50
  }
}

// Máquina virtual
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(loadTextContent('cloud-init.sh'))
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          id: osDisk.id
        }
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          name: dataDiskName
          createOption: 'Attach'
          managedDisk: {
            id: dataDisk.id
          }
          lun: 0
          caching: 'ReadWrite'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
  }
}

// Cuenta de almacenamiento para diagnósticos
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-09-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-09-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: '00000000-0000-0000-0000-000000000001'
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'delete'
            'update'
            'import'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          certificates: [
            'get'
            'list'
            'create'
            'delete'
            'update'
            'import'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
        }
      }
    ]
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Secreto para la contraseña de administrador
resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-09-01' = {
  parent: keyVault
  name: 'admin-password'
  properties: {
    value: adminPassword
    contentType: 'text/plain'
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output resourceGroupLocation string = resourceGroup().location
output virtualNetworkName string = vnet.name
output virtualNetworkAddressSpace array = vnet.properties.addressSpace.addressPrefixes
output subnetName string = vnet.properties.subnets[0].name
output subnetAddressPrefix string = vnet.properties.subnets[0].properties.addressPrefix
output publicIPAddress string = publicIP.properties.ipAddress
output publicIPFQDN string = publicIP.properties.dnsSettings.fqdn
output vmName string = vm.name
output vmSize string = vm.properties.hardwareProfile.vmSize
output vmPrivateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output vmAdminUsername string = vm.properties.osProfile.adminUsername
output keyVaultName string = keyVault.name
output keyVaultURI string = keyVault.properties.vaultUri
output nsgName string = nsg.name
output osDiskName string = osDisk.name
output dataDiskName string = dataDisk.name
output connectionStrings object = {
  ssh: 'ssh ${vm.properties.osProfile.adminUsername}@${publicIP.properties.ipAddress}'
  rdp: 'mstsc /v:${publicIP.properties.ipAddress}'
  web: 'http://${publicIP.properties.ipAddress}'
}
output tags object = tags
