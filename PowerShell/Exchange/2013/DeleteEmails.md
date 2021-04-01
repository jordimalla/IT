#Powershell command to delete emails from concrete user and date
Search-Mailbox -Identity <DNUser> -SearchQuery "Received<=3/30/2021" -deletecontent

#URL
#https://docs.microsoft.com/en-us/powershell/module/exchange/search-mailbox?view=exchange-ps
