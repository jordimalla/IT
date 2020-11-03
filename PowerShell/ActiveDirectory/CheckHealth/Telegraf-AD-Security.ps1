$hostname=(Get-ADDomainController).domain

### OverAll AD Statistics total ###
$SearchAccount=Search-ADAccount -AccountDisabled
$ADAccountDisabled=if($SearchAccount) { $SearchAccount.count } else { "0" }

$SearchLockedOut=Search-ADAccount -LockedOut
$ADCountLockedOut=if($SearchLockedOut) { $SearchLockedOut.count } else { "0" }

$SearchPasswordExpired=Search-ADAccount -PasswordExpired
$ADCountPasswordExpired=if($SearchPasswordExpired) { $SearchPasswordExpired.count } else { "0" }

$SearchPasswordNeverExpired=Get-ADUser -filter * -properties passwordneverexpires
$pwdNeverExp=if($SearchPasswordNeverExpired) { $SearchPasswordNeverExpired.count } else { "0" }

### Password Resets Detailed per User ###
$dte = (Get-Date).AddMinutes(-10) ## aktuelle Uhrezeit -10 minuten
$PWDUSERS=Get-ADUser -filter 'passwordlastset -gt "$dte"' -properties passwordlastset, passwordneverexpires | sort-object name | select-object Name, passwordlastset
$counts="0"
if($PWDUSERS)
{
	# searching for change accounts in the las 10 min $dte --> $PWDUSERS=Get-ADUser -filter 'whenchanged -gt $dte' -properties passwordlastset, passwordneverexpires | sort-object name | select-object name,
	$counts=($PWDUSERS.name).count
	foreach($PWDUSER in $PWDUSERS)
	{
		$pwdResetTime=$PWDUSER.passwordlastset
		$pwdResetTime=([DateTimeOffset] $pwdResetTime).ToUnixTimeMilliseconds()
		$PWDUSER = $PWDUSER.name
		#remove spaces - they are not allowed in influxdb
		$group = $group -replace '\s', '-'
		$PWDUSER= $PWDUSER -replace '\s', '-'
		#$hostname = $hostname -replace '\.', '-'
		Write-Host "ad_accounts,host=$hostname,ad_value=PasswordLastSet,instance=$PWDUSER status=1,pwdLastSetTime=$pwdResetTime"
	}
}

Write-Host "ad_accounts,host=$hostname,ad_value=ADAccountDisabled total_=$ADAccountDisabled"
Write-Host "ad_accounts,host=$hostname,ad_value=ADCountLockedOut total_=$ADCountLockedOut"
Write-Host "ad_accounts,host=$hostname,ad_value=ADCountPwdExpired total_=$ADCountPasswordExpired"
Write-Host "ad_accounts,host=$hostname,ad_value=PasswordLastSet total_=$counts"
Write-Host "ad_accounts,host=$hostname,ad_value=ADpwdNeverExp total_=$pwdNeverExp"
