Connect-AzAccount
function Show-Menu
{
    param (
        [string]$Title = 'Start VM on Connect Configurator'
    )
    Clear-Host
    Write-Host "================ WVDLogix (C) Start VM on Connect Configurator ================"
    Write-Host ""
    Write-Host "Configure Start VM on Connect for all POOLED Host Pools: Press '1' for this option." -ForegroundColor Green
    Write-Host "Configure Start VM on Connect for all PERSONAL Host Pools: Press '2' for this option." -ForegroundColor Green
    Write-Host "Deactivate Start VM on Connect for all POOLED Host Pools: Press '3' for this option." -ForegroundColor Red
    Write-Host "Deactivate Start VM on Connect for all PERSONAL Host Pools: Press '4' for this option." -ForegroundColor Red
    Write-Host ""
    Write-Host "Logout from Azure: Press 'Q' to quit."
    Write-Host ""
    Write-Host "================ Visit https://wvdlogix.net for more information ==============="
    Write-Host ""
}

do 
{
Show-Menu -Title "Start VM on Connect Configurator"
$selection = Read-Host "Please make a selection"
 switch ($selection)
 {
     '1' {      
        $AllHostPools = Get-AzResource | Where-Object ResourceType -eq Microsoft.DesktopVirtualization/hostpools
        foreach ($HostPool in $AllHostPools) {
            $HostPoolValidation = Get-AzWVDHostPool -Name $HostPool.Name -ResourceGroupName $HostPool.ResourceGroupName
            if ($HostPoolValidation.HostPoolType -eq "Pooled") {
                if ($HostPoolValidation.StartVMOnConnect -eq $true) {
                    Write-Host "The HostPool "$HostPoolValidation.Name" has the feature already enabled. Continue with the next one"
                }
                else {
                    Update-AzWvdHostPool -Name $HostPool.Name -ResourceGroup $HostPool.ResourceGroupName -StartVMOnConnect:$true
                    Write-Host "Start VM on Connect has been successfully configured for Host Pool "$HostPoolValidation.Name"" -ForegroundColor Green
                }
            } else {  }
        }        
     } 
     
     '2' {
         
        $AllHostPools = Get-AzResource | Where-Object ResourceType -eq Microsoft.DesktopVirtualization/hostpools
        foreach ($HostPool in $AllHostPools) {
             $HostPoolValidation = Get-AzWVDHostPool -Name $HostPool.Name -ResourceGroupName $HostPool.ResourceGroupName
            if ($HostPoolValidation.HostPoolType -eq "Personal") {
                 if ($HostPoolValidation.StartVMOnConnect -eq $true) {
                 Write-Host "The HostPool "$HostPoolValidation.Name" has the feature already enabled. Continue with the next one"
        }
        else {
            Update-AzWvdHostPool -Name $HostPool.Name -ResourceGroup $HostPool.ResourceGroupName -StartVMOnConnect:$true
            Write-Host "Start VM on Connect has been successfully configured for Host Pool "$HostPoolValidation.Name"" -ForegroundColor Green
        }
            } else {  }
        }
     } 
          
     '3' {
         
        $AllHostPools = Get-AzResource | Where-Object ResourceType -eq Microsoft.DesktopVirtualization/hostpools
        foreach ($HostPool in $AllHostPools) {
             $HostPoolValidation = Get-AzWVDHostPool -Name $HostPool.Name -ResourceGroupName $HostPool.ResourceGroupName
            if ($HostPoolValidation.HostPoolType -eq "Pooled") {
                  if ($HostPoolValidation.StartVMOnConnect -eq $false) {
                 Write-Host "The HostPool "$HostPoolValidation.Name" has the feature already enabled. Continue with the next one"
        }
        else {
            Update-AzWvdHostPool -Name $HostPool.Name -ResourceGroup $HostPool.ResourceGroupName -StartVMOnConnect:$false
            Write-Host "Start VM on Connect has been successfully deactivated for Host Pool "$HostPoolValidation.Name"" -ForegroundColor Green
        }
        } else {  }
        }
     } 
     
     '4' {
        $AllHostPools = Get-AzResource | Where-Object ResourceType -eq Microsoft.DesktopVirtualization/hostpools
        foreach ($HostPool in $AllHostPools) {
            $HostPoolValidation = Get-AzWVDHostPool -Name $HostPool.Name -ResourceGroupName $HostPool.ResourceGroupName
            if ($HostPoolValidation.HostPoolType -eq "Personal") {
                if ($HostPoolValidation.StartVMOnConnect -eq $false) {
                    Write-Host "The HostPool "$HostPoolValidation.Name" has the feature already enabled. Continue with the next one"
                }
                else {
                    Update-AzWvdHostPool -Name $HostPool.Name -ResourceGroup $HostPool.ResourceGroupName -StartVMOnConnect:$false
                    Write-Host "Start VM on Connect has been successfully deactivated for Host Pool "$HostPoolValidation.Name"" -ForegroundColor Green
                }
            } else {  }
        }
     }

     'q' {Disconnect-AzAccount}
}
pause
} 
until ($selection -eq 'q')