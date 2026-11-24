param(
    [Parameter(Mandatory=$true)][string]$ResourceGroupName, # Name der Ressourcengruppe
    [string]$GatewaySubnetAddress = "10.1.0.0/27", # Adressbereich für das Gateway-Subnetz
    [string]$VPNGatewayName = "MyVPNGateway",      # Name des VPN-Gateways
    [string]$PublicIPName = "MyVPNGatewayPublicIP" # Name der öffentlichen IP-Adresse
)

$ErrorActionPreference = 'Stop'

# Überprüfen, ob der Benutzer bereits authentifiziert ist
if (-not (Get-AzContext)) {
    Write-Output "Benutzer ist nicht authentifiziert. Authentifiziere mit Device Code..."
    Connect-AzAccount -UseDeviceAuthentication
} else {
    Write-Output "Benutzer ist bereits authentifiziert."
}

# Überprüfen, ob genau ein virtuelles Netzwerk existiert
$vnets = @(Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -ErrorAction Stop)
if ($vnets.Count -eq 0) {
    throw "In der Ressourcengruppe '$ResourceGroupName' wurde kein VNet gefunden."
}
if ($vnets.Count -gt 1) {
    $names = $vnets.Name -join ', '
    throw "In der Ressourcengruppe '$ResourceGroupName' wurden mehrere VNets gefunden: $names"
}

$vnet = $vnets[0]
$VNetName = $vnet.Name
$Location = $vnet.Location

# Überprüfen, ob das Gateway-Subnetz existiert, und erstellen, falls nicht vorhanden
$gatewaySubnet = $vnet.Subnets | Where-Object { $_.Name -eq "GatewaySubnet" }
if (-not $gatewaySubnet) {
    Write-Output "Erstelle Gateway-Subnetz im virtuellen Netzwerk '$VNetName'..."
    $gatewaySubnetConfig = Add-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix $GatewaySubnetAddress -VirtualNetwork $vnet
    Set-AzVirtualNetwork -VirtualNetwork $vnet | Out-Null
    Write-Output "Gateway-Subnetz wurde erstellt: $GatewaySubnetAddress"
} else {
    Write-Output "Gateway-Subnetz existiert bereits: $($gatewaySubnet.AddressPrefix)"
}

# Erstellen einer öffentlichen IP-Adresse für das VPN-Gateway
Write-Output "Erstelle öffentliche IP-Adresse für das VPN-Gateway..."
$publicIP = New-AzPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $Location `
    -AllocationMethod Static -Sku Standard
Write-Output "Öffentliche IP-Adresse erstellt: $($publicIP.IpAddress)"

# Erstellen der Gateway-IP-Konfiguration
Write-Output "Erstelle Gateway-IP-Konfiguration..."
$id = Get-AzVirtualNetwork -Name $vnet.Name -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets | Where-Object { $_.Name -eq "GatewaySubnet" } | Select-Object -ExpandProperty ID
$gatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name "GatewayIPConfig" `
    -SubnetId $id `
    -PublicIpAddressId $publicIP.Id

# Erstellen des VPN-Gateways
Write-Output "Erstelle VPN-Gateway..."
$vpnGateway = New-AzVirtualNetworkGateway -Name $VPNGatewayName -ResourceGroupName $ResourceGroupName -Location $Location `
    -IpConfigurations $gatewayIPConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1Az
Write-Output "VPN-Gateway wurde erfolgreich erstellt: $VPNGatewayName"
