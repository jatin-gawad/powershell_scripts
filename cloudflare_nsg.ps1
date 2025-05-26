# Login to Azure
Login-AzAccount

# Set your Azure subscription context
$subscriptionId = "cea0340a-3739-4fb9-9d2c-cdbcb5d6e7ec"
Set-AzContext -SubscriptionId $subscriptionId

# Define variables
$resourceGroupName = "wig-maxwell-ecm-prd-cac-rg-01"
$nsgName = "wig-maxwell-ecm-prd-cac-nsg-01-app"

# Fetch Cloudflare IP ranges
$ipv4Ranges = (Invoke-RestMethod "https://www.cloudflare.com/ips-v4") -split "`n" | Where-Object { $_.Trim() -ne "" }
$ipv6Ranges = (Invoke-RestMethod "https://www.cloudflare.com/ips-v6") -split "`n" | Where-Object { $_.Trim() -ne "" }

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName

# Add IPv4 ranges to NSG
$ipv4Priority = 111
foreach ($ip in $ipv4Ranges) {
    $ruleName = "Allow-Cloudflare-IPv4-" + ($ip -replace "/", "-")
    $nsg | Add-AzNetworkSecurityRuleConfig -Name $ruleName `
        -Description "Allow traffic from Cloudflare IPv4" `
        -Access Allow `
        -Protocol * `
        -Direction Inbound `
        -Priority $ipv4Priority `
        -SourceAddressPrefix $ip `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange *
    $ipv4Priority++   
        
}

# Add IPv6 ranges to NSG
$ipv6Priority = 141
foreach ($ip in $ipv6Ranges) {
    $ruleName = "Allow-Cloudflare-IPv6-" + $ipv6Priority
    $nsg | Add-AzNetworkSecurityRuleConfig -Name $ruleName `
        -Description "Allow traffic from Cloudflare IPv6" `
        -Access Allow `
        -Protocol * `
        -Direction Inbound `
        -Priority $ipv6Priority `
        -SourceAddressPrefix $ip `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange *
    $ipv6Priority++ 
}

# Update the NSG with new rules
$nsg | Set-AzNetworkSecurityGroup

Write-Host "Cloudflare IP ranges have been added to the NSG."