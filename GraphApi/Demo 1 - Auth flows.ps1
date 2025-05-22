# Demo 1, authentication flows
#
# Authorization Code flow (Interactive)
# Using native Microsoft Graph Powershell application 
# Using MSAL.PS to get the token 
$Parameters = @{
    TenantId = ""
    ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
    RedirectUri = "http://localhost"
}
$AccessToken = Get-MsalToken @Parameters
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = $AccessToken.CreateAuthorizationHeader()
    "ExpiresOn" = $AccessToken.ExpiresOn.LocalDateTime
}
$AuthenticationHeader
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=operatingSystem eq 'Windows' &select=id, deviceName, complianceState"

$Devices = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
$Devices 

#
# Client Credentials (Secret) flow (Unattended)
# - Using custom app registration
# Using MSAL.PS to get the token 
$Parameters = @{
    TenantId = ""
    ClientId = ""
    ClientSecret = ("<your secret>" | ConvertTo-SecureString -AsPlainText -Force)
    RedirectUri = "http://localhost"
}
$AccessToken = Get-MsalToken @Parameters
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = $AccessToken.CreateAuthorizationHeader()
    "ExpiresOn" = $AccessToken.ExpiresOn.LocalDateTime
}
$AuthenticationHeader
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=operatingSystem eq 'Windows' &select=id, deviceName, complianceState"

$Devices = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
$Devices 

#
# Device Code
# Not recommended to be used anymore - easily phished
# Should be blocked by Conditional Access policies in production
# Using MSAL.PS to get the token 
$Parameters = @{
    TenantId = ""
    ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
    RedirectUri = "http://localhost"
    DeviceCode = $true
}

$AccessToken = Get-MsalToken @Parameters
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = $AccessToken.CreateAuthorizationHeader()
    "ExpiresOn" = $AccessToken.ExpiresOn.LocalDateTime
}
$AuthenticationHeader

$Devices = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
$Devices 

#
#  Client Credentials (Managed System Identity in Function App)
#
$APIVersion = "2017-09-01"
$ResourceUri = "https://graph.microsoft.com"
$Uri = $env:MSI_ENDPOINT + "?resource=$($ResourceUri)&api-version=$($APIVersion)"
$Response = Invoke-RestMethod -Uri $URI -Method "Get" -Headers @{ "Secret" = "$($env:MSI_SECRET)" }
$AuthenticationHeader = @{
    "Authorization" = "Bearer $($Response.access_token)"
    "ExpiresOn" = $Response.expires_on
}