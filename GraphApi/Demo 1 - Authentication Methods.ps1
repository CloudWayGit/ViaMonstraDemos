# Define demo variables
$ApplicationClientId = ''
$TenantId = ''
$ApplicationClientSecret = '' # Application Secret Value

# Demo 1

# Authorization Code flow (Interactive)
# Using native Microsoft Graph Powershell application 
# Connect using Connect-MgGraph 
Connect-MgGraph
# Check Scopes
Get-MgContext | Select-Object -ExpandProperty Scopes

# Get managed devices using Microsoft Graph SDK
$Result = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" | Select-Object id, deviceName,complianceState, userPrincipalName
$Result
Disconnect-MgGraph


#Connect with ClientID only (App Registration - Public Client)
# Using Connect-MgGraph

Connect-MgGraph -ClientId $ApplicationClientId -TenantId $TenantId -Scopes "User.Read.All"
Get-MgContext | Select-Object -ExpandProperty Scopes

# Add scopes for reading managed devices from Intune  
Connect-MgGraph -ClientId $ApplicationClientId -TenantId $TenantId -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
Get-MgContext | Select-Object -ExpandProperty Scopes

# Get managed devices using Microsoft Graph SDK
$Result = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" | Select-Object id, deviceName,complianceState, userPrincipalName
$Result

Disconnect-MgGraph


# Connect with ClientID and Secret (App-Only)
# Convert the Client Secret to a Secure String
$SecureClientSecret = ConvertTo-SecureString -String $ApplicationClientSecret -AsPlainText -Force
# Create a PSCredential Object Using the Client ID and Secure Client Secret
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationClientId, $SecureClientSecret
# Connect to Microsoft Graph Using the Tenant ID and Client Secret Credential
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential
#Check Scope
Get-MgContext | Select-Object -ExpandProperty Scopes
# Get managed devices using Microsoft Graph SDK
$Result = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" | Select-Object id, deviceName,complianceState, userPrincipalName

Disconnect-MgGraph
#  
# Lets add the following APP Only permissions in Azure Portal 
# DeviceManagementConfiguration.ReadWrite.All
# DeviceManagementManagedDevices.ReadWrite.All
# DeviceManagementServiceConfig.ReadWrite.All
# User.ReadWrite.All
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential
Get-MgContext | Select-Object -ExpandProperty Scopes

# Get managed devices using Microsoft Graph SDK
$Result = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" | Select-Object id, deviceName,complianceState, userPrincipalName
$Result

#Disconnect-MgGraph

# Device Code
# Not recommended to be used anymore - easily phished
# Should be blocked by Conditional Access policies in production
# Requires another flag to be set on the App Registration "Allow public client flows"
# Connect-MgGraph -ClientId $ApplicationClientId -TenantId $TenantId -DeviceCode


# As mentioned we can extract the token from the current session to use for REST API calls and then only need the Microsoft.Graph.Authentication module
# The Microsoft.Graph.Authentication module also contains a REST API cmdlet called Invoke-MgGraphRequest 
# Show Extract Token method again

#Extract token from current session for REST API calls
$Request = @{
  Method = "GET"
  URI = "/v1.0/users"
  OutputType = "HttpResponseMessage"
}
$Response = Invoke-GraphRequest @Request
$Headers = $Response.RequestMessage.Headers
$Token = $Headers.Authorization.Parameter
$Token | Set-Clipboard

# Create proper header with the extracted token
$AuthenticationHeaders = @{
    Authorization = "Bearer $Token"
    'Content-Type' = 'application/json'
}

$AuthenticationHeaders

# Disconnect from Microsoft Graph
Disconnect-MgGraph

#Now lets connect using pure REST API with Client Secret without any modules
# Get Access Token using Client Secret
$body = @{
    "client_id" = $ApplicationClientId
    "client_secret" = $ApplicationClientSecret
    "scope" = "https://graph.microsoft.com/.default"
    "grant_type" = "client_credentials"
}

$AuthenticationUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$Auth = Invoke-RestMethod -Method Post -Uri $AuthenticationUri -Body $body -ContentType "application/x-www-form-urlencoded"

$AuthenticationHeader = @{
    Authorization = "Bearer $($Auth.access_token)"
    "Content-Type" = "application/json"
}
$AuthenticationHeader

# Now we have the authentication header to use for REST API calls without any modules
# Example call to get all windows devices in Intune
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows' &`$select=id, deviceName, complianceState"
$Devices = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
Write-Output $Devices