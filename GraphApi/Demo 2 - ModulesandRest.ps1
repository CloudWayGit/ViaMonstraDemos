# Demo 2 

# Get the auth token and builds the header using MSAL.PS
# Uses the native Microsoft Graph PowerShell SDK APP to connect via 

$Parameters = @{
    TenantId = ""
    ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
    RedirectUri = "http://localhost"
    Interactive = $true
}
$AccessToken = Get-MsalToken @Parameters
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = $AccessToken.CreateAuthorizationHeader()
    "ExpiresOn" = $AccessToken.ExpiresOn.LocalDateTime
}
$AuthenticationHeader

#Define a Graph URI
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=operatingSystem eq 'Windows' &select=id, deviceName, complianceState"

#Query the Graph API
$Result = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
$Result

#Using the Microsoft Graph SDK Module
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
$Result = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" | Select-Object id, deviceName,complianceState
$Result

# Using Pure Rest API to authenticate with client secret 
# Automation without any modules involved. 
# Lightweight and fast.
$tenantid = ""
$clientid = ""
$ClientSecret = ""

$body = @{
    "client_id" = $clientid
    "client_secret" = $ClientSecret
    "scope" = "https://graph.microsoft.com/.default"
    "grant_type" = "client_credentials"
}

$AuthenticationUri = "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token"
$Auth = Invoke-RestMethod -Method Post -Uri $AuthenticationUri -Body $body -ContentType "application/x-www-form-urlencoded"

$AuthenticationHeader = @{
    Authorization = "Bearer $($Auth.access_token)"
    "Content-Type" = "application/json"
}
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=operatingSystem eq 'Windows' &select=id, deviceName, complianceState"
$Result = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
$Result