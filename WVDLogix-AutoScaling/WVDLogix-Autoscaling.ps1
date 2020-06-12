<#Author       : Patrick Köhler
# Creation Date: 07.06.2020
# Name:          WVDTimebasedScale
# Description:   This script helps to save money during off-peak hours and helps to run all required scripts / commandlets and operations in this one script. It has been developed to simplify the deployment process and 
#                The so called "Time-based Automation" is built on the WVDScaling provided by (C) Microsoft
#                Creation of Azure resources have been taken and optimized from: https://raw.githubusercontent.com/Azure/RDS-Templates/wvd_scaling/wvd-templates/wvd-scaling-script
#                Info: The script has been tested in different scenarios and environments. Nevertheless I will personally take no responsibility for any misconfiguration / change in your environments. 
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 07.06.2020                     0.1        Intial Version
# 11.06.2020                     0.2        Added prompts & RunAsAccount creation
#*********************************************************************************
#
#>

#Requires -RunAsAdministrator

######################################
# Prerequisites and Download process #
######################################

Set-Executionpolicy -ExecutionPolicy Unrestricted -Force
Login-AzAccount
$WorkingFolderLocation = Read-Host -Prompt "Please type a path, where the scripts shall be executed in"
Set-Location -Path $WorkingFolderLocation
$Uri = "https://raw.githubusercontent.com/Azure/RDS-Templates/wvd_scaling/wvd-templates/wvd-scaling-script/CreateOrUpdateAzAutoAccount.ps1"
$Uri2 = "https://raw.githubusercontent.com/Azure/RDS-Templates/wvd_scaling/wvd-templates/wvd-scaling-script/CreateOrUpdateAzLogicApp.ps1"
$Uri3 = "https://raw.githubusercontent.com/wvdlogix/WVDLOGIX-Scripts/master/WVDLogix-AutoScaling/Misc/New-RunAsAccount.ps1"
Invoke-WebRequest -Uri $Uri -OutFile ".\CreateOrUpdateAzAutoAccount.ps1"
Invoke-WebRequest -Uri $Uri2 -OutFile ".\CreateOrUpdateAzLogicApp.ps1"
Invoke-WebRequest -Uri $Uri3 -OutFile ".\New-RunAsAccount.ps1"

######################################
#          VARIABLES                 #
######################################
$Subscription = Get-AzSubscription
$aadTenantId = (Get-AzContext).Tenant.Id
$AutomationRGName = Get-AzResourceGroup | Out-GridView -PassThru -Title "Select the resource group for the new Azure Logic App"
$AutomationLocation = Get-AzLocation | Select Location,DisplayName | Out-GridView -PassThru -Title "Select the resource group for the new Azure Logic App" 
$AutomationAccountName = Read-Host -Prompt "Enter the name of Automation Account name"
$LogAnalyticsWS = Read-Host -Prompt "Enter the name of your Log Analytics Workspace - by leaving this empty the automation will be implemented without logging"
$SSCertPWD = Read-Host -AsSecureString "Provide a strong password for creating your Run-As Account - The certificate will use this password for decryption" 

######################################
#          PARAMETERS                #
######################################
$Params = @{
    "AADTenantId"           = $aadTenantId                           
    "SubscriptionId"        = $Subscription.Id                       
    "UseARMAPI"             = $true
    "ResourceGroupName"     = $AutomationRGName.ResourceGroupName    
    "AutomationAccountName" = $AutomationAccountName                 
    "Location"              = $AutomationLocation.Location           
    "WorkspaceName"         = $LogAnalyticsWS                        
}

.\CreateOrUpdateAzAutoAccount.ps1 @Params

######################################
# CREATE Automation Run As Account   #
######################################

.\New-RunAsAccount.ps1 -ResourceGroup $AutomationRGName.ResourceGroupName -AutomationAccountName $AutomationAccountName -SubscriptionID $Subscription.Id -ApplicationDisplayName "$AutomationAccountName-RunAs" -SelfSignedCertPlainPassword $SSCertPWD -CreateClassicRunAsAccount $false

######################################
# CREATE LOGICAPP with PARAMETERS    #
######################################
$WebhookURI = Read-Host -Prompt "Enter the URI of the WebHook returned by when you created the Azure Automation Account"
$maintenanceTagName = Read-Host -Prompt "Enter the name of the Tag associated with VMs you don't want to be managed by this scaling tool"
$wvdHostpool = Get-AzWvdHostPool | Out-GridView -PassThru -Title "Select the host pool you'd like to scale"
$hostPoolName = $wvdHostpool.Name
$hostPoolResourceGroupName = (Get-AzResource -ResourceId $wvdHostpool.Id).ResourceGroupName

$recurrenceInterval = Read-Host -Prompt "Please fill out how often the job shall be repeated, values in minutes, e.g. '15'"
$beginPeakTime = Read-Host -Prompt "Enter the start time for peak hours in local time, e.g. 9:00"
$endPeakTime = Read-Host -Prompt "Enter the end time for peak hours in local time, e.g. 18:00"
$timeDifference = Read-Host -Prompt "Enter the time difference between local time and UTC in hours, e.g. for CET: +2:00"
$sessionThresholdPerCPU = Read-Host -Prompt "Enter the maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours"
$minimumNumberOfRdsh = Read-Host -Prompt "Enter the minimum number of session host VMs to keep running during off-peak hours"
$limitSecondsToForceLogOffUser = Read-Host -Prompt "Enter the number of seconds to wait before automatically signing out users. If set to 0, any session host VM that has user sessions, will be left untouched"
$logOffMessageTitle = Read-Host -Prompt "Enter the title of the message sent to the user before they are forced to sign out"
$logOffMessageBody = Read-Host -Prompt "Enter the body of the message sent to the user before they are forced to sign out"

$automationAccount = Get-AzAutomationAccount -ResourceGroupName $AutomationRGName.ResourceGroupName
$automationAccountConnection = Get-AzAutomationConnection -ResourceGroupName $AutomationRGName.ResourceGroupName -AutomationAccountName $AutomationAccountName | Out-GridView -PassThru -Title "Select the Azure RunAs connection asset"
$connectionAssetName = $automationAccountConnection.Name

$Params = @{
     "UseARMAPI"                     = $true
     "ResourceGroupName"             = $AutomationRGName.ResourceGroupName      
     "Location"                      = $AutomationLocation.Location             
     "HostPoolName"                  = $hostPoolName
     "HostPoolResourceGroupName"     = $hostPoolResourceGroupName               
     "LogAnalyticsWorkspaceId"       = ""                                       
     "LogAnalyticsPrimaryKey"        = ""                                       
     "ConnectionAssetName"           = $connectionAssetName                     
     "RecurrenceInterval"            = $recurrenceInterval                      
     "BeginPeakTime"                 = $beginPeakTime                           
     "EndPeakTime"                   = $endPeakTime                             
     "TimeDifference"                = $timeDifference                         
     "SessionThresholdPerCPU"        = $sessionThresholdPerCPU                 
     "MinimumNumberOfRDSH"           = $minimumNumberOfRdsh                     
     "MaintenanceTagName"            = $maintenanceTagName                     
     "LimitSecondsToForceLogOffUser" = $limitSecondsToForceLogOffUser           
     "LogOffMessageTitle"            = $logOffMessageTitle                     
     "LogOffMessageBody"             = $logOffMessageBody                      
     "WebhookURI"                    = $WebhookURI
}

.\CreateOrUpdateAzLogicApp.ps1 @Params