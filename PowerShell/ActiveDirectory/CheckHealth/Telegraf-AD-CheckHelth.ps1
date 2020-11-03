#############################################################################
#       Author: Vikas Sukhija
#       Reviewer:    
#       Date: 22/01/2020
#       Reviewed by: Jordi Malla
#       Satus: ping,DNS,DFSR,IsmServ,kdc,NetLogon,NTDS Test(NetLogons,Replications,Services,Advertising,FsmoCheck)
#       Update: Change status and test and rewrite code
#       Description: AD Health Status
#############################################################################
###########################Define Variables##################################
$timeout = "60"
$CheckedServices = 'DNS','DFSR','IsmServ','kdc','NetLogon','NTDS'
$Tests = 'NetLogons', 'Replications', 'Services', 'Advertising', 'FsmoCheck' 
$DC = (Get-ADDomainController).HostName
$Text_TestPassed = "superó󠬡 prueba"

################Ping Test######
if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) {
	Write-Host "ad_helthCheck,host=$DC,test=Ping estat=2"
	##################### Service Status ###############################
	foreach($CheckService in $CheckedServices){
		$serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name $($args[1]) -ErrorAction SilentlyContinue} -ArgumentList $DC,$CheckService
		wait-job $serviceStatus -timeout $timeout | Out-Null
		if($serviceStatus.state -like "Running")
		{
			Write-Host "ad_helthCheck,host=$DC,service=$serviceStatus.name estat=1"
			stop-job $serviceStatus
		}
		else
		{
			$serviceStatus1 = Receive-job $serviceStatus
			$svcName = $serviceStatus1.name
			if ($serviceStatus1.status -eq "Running") {
				Write-Host "ad_helthCheck,host=$DC,service=$svcName estat=2" 
			}
			else 
			{ 
				Write-Host "ad_helthCheck,host=$DC,service=$svcName estat=0"
			} 
		}
	}
	####################### Tests Status #######################################
	foreach($Test in $Tests){
		add-type -AssemblyName microsoft.visualbasic 
		$cmp = "microsoft.visualbasic.strings" -as [type]
		$sysvol = start-job -scriptblock {dcdiag /test:$($args[1]) /s:$($args[0])} -ArgumentList $DC,$Test
		wait-job $sysvol -timeout $timeout | Out-Null
		if($sysvol.state -like "Running")
		{
			Write-Host "ad_helthCheck,host=$DC,test=$Test estat=1"
			stop-job $sysvol
		}
		else
		{
			$sysvol1 = Receive-job $sysvol
			if($cmp::instr($sysvol1, "$Text_TestPassed $Test"))
			{
				Write-Host "ad_helthCheck,host=$DC,test=$Test estat=2"
			}
			else
			{
				Write-Host "ad_helthCheck,host=$DC,test=$Test estat=0"
			}
		}
	}
} 
else
{
	Write-Host "ad_helthCheck,host=$DC,test=Ping estat=0"
}            
