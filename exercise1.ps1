#Import-Module Az

#Login-AzAccount

#Define the following parameters for the virtual machine.
$vmAdminUsername = "KesyloKingloic"
$vmAdminPassword = ConvertTo-SecureString "KesyloKing@password" -AsPlainText -Force
 
#Define the following parameters for the Azure resources.
$azureLocation              = "EastUS2"
$azureResourceGroup         = "Exercise1-RG"
$azureVmName                = @("VM-01","VM-02")
$azureVmOsDiskName          = "DISK-"
$azureVmSize                = "Standard_D2s_v3"
$azureVmnetwork             = "192.168.1.0/24"
 
#Define the networking information.
$azureNicName               = "NIC-"
 
#Define the existing VNet information.
$azureVnetName              = "Exercise1-Vnet"
$azureVnetSubnetName        = "Exercise1-Subnet"
 
#Define the VM marketplace image details.
$azureVmPublisherName = "MicrosoftWindowsServer"
$azureVmOffer = "WindowsServer"
$azureVmSkus = "2019-Datacenter"

# check if ressource group exists
Get-AzResourceGroup -Name $azureResourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    # ResourceGroup doesn't exist
    New-AzResourceGroup -ResourceGroupName $azureResourceGroup -Location $azureLocation
}


$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name $azureVnetSubnetName `
  -AddressPrefix $azureVmnetwork

$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $azureResourceGroup `
  -Location $azureLocation `
  -Name $azureVnetName `
  -AddressPrefix $azureVmnetwork `
  -Subnet $subnetConfig

#Get the subnet details for the specified virtual network + subnet combination.
$azureVnetSubnet = (Get-AzVirtualNetwork -Name $azureVnetName -ResourceGroupName $azureResourceGroup).Subnets | Where-Object {$_.Name -eq $azureVnetSubnetName}
 
#Create the public IP address.
$azurePublicIp1 = New-AzPublicIpAddress -Name "PubIP1" -ResourceGroupName $azureResourceGroup -Location $azureLocation -AllocationMethod Static

$azurePublicIp2 = New-AzPublicIpAddress -Name "PubIP2" -ResourceGroupName $azureResourceGroup -Location $azureLocation -AllocationMethod Static

$publicIPs = @()
$publicIPs += $azurePublicIp1
$publicIPs += $azurePublicIp2

#Store the credentials for the local admin account.
$vmCredential = New-Object System.Management.Automation.PSCredential ($vmAdminUsername, $vmAdminPassword)


$nsgRule = New-AzNetworkSecurityRuleConfig `
  -Name AllowICMP `
  -Protocol Icmp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange * `
  -Access Allow

# Create a network security group using the rule
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $azureResourceGroup `
  -Location $azureLocation `
  -Name NetworkSecurityGroup `
  -SecurityRules $nsgRule



for($i = 0; $i -le $azureVmName.count -1; $i++)  
{
 
 # create NICs
 $NIC = New-AzNetworkInterface -Name ($azureNicName+$azureVmName[$i]) `
                               -ResourceGroupName $azureResourceGroup `
                               -Location $azureLocation `
                               -SubnetId $azureVnetSubnet.Id `
                               -PublicIpAddressId $publicIPs[$i].Id `
                               -NetworkSecurityGroupId $nsg.Id

 
 $VirtualMachine = New-AzVMConfig -VMName $azureVmName[$i] `
                                  -VMSize $azureVmSize

 $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
                                           -Windows `
                                           -ComputerName $azureVmName[$i] `
                                           -Credential $vmCredential `
                                           -ProvisionVMAgent  `
                                           -EnableAutoUpdate
 
 $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine `
                                            -Id $NIC.Id

 $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
                                       -PublisherName $azureVmPublisherName `
                                       -Offer $azureVmOffer `
                                       -Skus $azureVmSkus `
                                       -Version "latest"
                                       
 $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine `
                                  -StorageAccountType "Premium_LRS" `
                                  -Caching ReadWrite `
                                  -Name ($azureVmOsDiskName+$azureVmName[$i])`
                                  -CreateOption FromImage
 
 New-AzVM -ResourceGroupName $azureResourceGroup `
          -Location $azureLocation `
          -VM $VirtualMachine `
          -Verbose
}


