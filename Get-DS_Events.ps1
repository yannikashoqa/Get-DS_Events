
Function CheckPSVersion {
	$PS_Version =	$PSVersionTable.PSVersion.Major
	If ($PS_Version -lt $PSVersionRequired){
		Write-Host "[ERROR]	Pwershell version is $PS_Version. Powershell version $PSVersionRequired is required."
		Exit
	}
}


Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$ErrorActionPreference = 'Stop'

$Config             = (Get-Content "$PSScriptRoot\DS-Config.json" -Raw) | ConvertFrom-Json
$Manager            = $Config.MANAGER
$Port               = $Config.PORT
$Tenant             = $Config.TENANT
$UserName           = $Config.USER_NAME
$Password           = $Config.PASSWORD
$REPORTNAME         = $Config.REPORTNAME
$HOSTFILTERTYPE     = $Config.HOSTFILTERTYPE
$TIMEFILTERTYPE     = $Config.TIMEFILTERTYPE
$REPORTTYPE         = $Config.REPORTTYPE

$WSDL       = "/webservice/Manager?WSDL"
$DSM_URI    = "https://" + $Manager + ":" + $Port + $WSDL
$objManager = New-WebServiceProxy -uri $DSM_URI -namespace WebServiceProxy -class DSMClass
$REPORTFILE = $REPORTNAME + ".csv"

$PSVersionRequired = "3"
$StartTime  = $(get-date)

CheckPSVersion
Write-Host "[INFO]	Connecting to DSM server $DSM_URI"
try{
	if (!$Tenant) {
		$sID = $objManager.authenticate($UserName,$Password)
	}
	else {
		$sID = $objManager.authenticateTenant($Tenant,$UserName,$Password)
	}
	Remove-Variable UserName
	Remove-Variable Password
	Remove-Variable Tenant
	Write-Host "[INFO]	Connection to DSM server $DSM_URI was SUCCESSFUL"
}
catch{
	Write-Host "[ERROR]	Failed to logon to $DSM_URI.	$_"
	Remove-Variable UserName
	Remove-Variable Password
	Remove-Variable Tenant
	Exit
}

if ((Test-Path $REPORTFILE) -eq $true){
    $BackupDate         = get-date -format MMddyyyy-HHmm
    $BackupReportName   = $REPORTNAME + "_" + $BackupDate + ".csv"
    copy-item -Path $REPORTFILE -Destination $BackupReportName
    Remove-item $REPORTFILE
}

$TimeFilter = New-Object -TypeName WebServiceProxy.TimeFilterTransport
switch ($TIMEFILTERTYPE){
    0   {   #LAST_HOUR
            $TimeFilter.set_type("$TIMEFILTERTYPE")
        }

    1   {   #LAST_24_HOURS
            $TimeFilter.set_type("$TIMEFILTERTYPE")
        }

    2   {   #LAST_7_DAYS
            $TimeFilter.set_type("$TIMEFILTERTYPE")
        }

    5   {   #LAST 30 DAYS
            $TimeFilter.set_type("3")
            $RangeFrom = (Get-Date).AddDays(-30).ToShortDateString()
            $RangeTo = (Get-Date).ToShortDateString()
            $TimeFilter.set_rangeFrom($RangeFrom)
            $TimeFilter.set_rangeTo($RangeTo)
        }
    6   {   #LAST 60 DAYS
            $TimeFilter.set_type("3")
            $RangeFrom = (Get-Date).AddDays(-60).ToShortDateString()
            $RangeTo = (Get-Date).ToShortDateString()
            $TimeFilter.set_rangeFrom($RangeFrom)
            $TimeFilter.set_rangeTo($RangeTo)
        }
    7   {   #LAST 90 DAYS
            $TimeFilter.set_type("3")
            $RangeFrom = (Get-Date).AddDays(-90).ToShortDateString()
            $RangeTo = (Get-Date).ToShortDateString()
            $TimeFilter.set_rangeFrom($RangeFrom)
            $TimeFilter.set_rangeTo($RangeTo)
        }
}

$HostFilter = New-Object -TypeName WebServiceProxy.HostFilterTransport
$HostFilter.set_type("$HOSTFILTERTYPE")

$EventIdFilter = New-Object -TypeName WebServiceProxy.IDFilterTransport #For 32Bit
$EventIdFilter2 = New-Object -TypeName WebServiceProxy.IDFilterTransport2  #For 64Bit

Switch ($REPORTTYPE){
    SYS {   #System Events
            #systemEventRetrieve(TimeFilterTransport timeFilter, HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, boolean includeNonHostEvents, String sID)
            $includeNonHostEvents = $false
            $SYS_Events = $objManager.systemEventRetrieve2($TimeFilter, $HostFilter, $EventIdFilter2.operator, $includeNonHostEvents, $sID)
            $SYS_Events.get_systemEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }

    AM  {   #LAST_24_HOURS
            #antiMalwareEventRetrieve(TimeFilterTransport timeFilter HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, String sID)
            $AM_Events = $objManager.antiMalwareEventRetrieve2($TimeFilter, $HostFilter, $EventIdFilter.operator, $sID)
            $AM_Events.get_antiMalwareEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }

    WEB  {  #LAST_24_HOURS
            #webReputationEventRetrieve(TimeFilterTransport timeFilter, HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, String sID)
            $WebRep_Events = $objManager.webReputationEventRetrieve($TimeFilter, $HostFilter, $EventIdFilter.operator, $sID)
            $WebRep_Events.get_webReputationEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }

    FW  {   #LAST_24_HOURS
            #firewallEventRetrieve(TimeFilterTransport timeFilter, HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, String sID)
            $FW_Events = $objManager.firewallEventRetrieve($TimeFilter, $HostFilter, $EventIdFilter.operator, $sID)
            $FW_Events.get_firewallEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }

    IPS  {  #LAST_24_HOURS
            #DPIEventRetrieve(TimeFilterTransport timeFilter, HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, String sID)
            $DPI_Events = $objManager.DPIEventRetrieve($TimeFilter, $HostFilter, $EventIdFilter.operator, $sID)
            $DPI_Events.get_DPIEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }

    IM  {   #LAST_24_HOURS
            #integrityEventRetrieve(TimeFilterTransport timeFilter, HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, String sID)
            $IM_Events = $objManager.integrityEventRetrieve($TimeFilter, $HostFilter, $EventIdFilter.operator, $sID)
            $IM_Events.get_integrityEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }

    LI  {   #LAST_24_HOURS
            #logInspectionEventRetrieve(TimeFilterTransport timeFilter, HostFilterTransport hostFilter, IDFilterTransport eventIdFilter, String sID)
            $LI_Events = $objManager.logInspectionEventRetrieve($TimeFilter, $HostFilter, $EventIdFilter.operator, $sID)
            $LI_Events.get_logInspectionEvents() | Export-Csv -Path ([IO.Path]::Combine($PSScriptRoot, $REPORTFILE))
    }
}



$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)

Write-Host "Report Generation is Complete.  It took $totalTime"


