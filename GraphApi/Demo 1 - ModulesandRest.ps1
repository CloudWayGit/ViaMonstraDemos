# Native Rest
#Geth the auth token and builds the header using MSAL.PS
$Auth = Get-MsalToken -ClientID '14d82eec-204b-4c2f-b7e8-296a70dab67e' -Interactive -TenantID 'contoso.com'
$Autheader = @{Authorization = $Auth.CreateAuthorizationHeader()}
#Define a Graph URI
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=operatingSystem eq 'iOS'&select=id, deviceName"

#Query the Graph API
$Result = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $Autheader).value
$Result

#Using the Graph SDK
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All"
$Result = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'iOS'" | Select-Object id, deviceName
$Result

#Using the AZ module
Connect-AzAccount -Tenant "contoso.com" 
$MyToken = Get-AzAccessToken -ResourceTypeName MSGraph 
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = "bearer $($myToken.token)"
}
#Define a Graph URI
$GraphURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=operatingSystem eq 'iOS'&select=id, deviceName"

#Query the Graph API
$Result = (Invoke-RestMethod -Method Get -Uri $GraphURI -Headers $AuthenticationHeader).value
$Result