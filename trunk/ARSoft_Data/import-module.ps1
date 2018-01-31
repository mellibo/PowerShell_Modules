$p = (Get-Location).TosTring() + ";" + [Environment]::GetEnvironmentVariable("PSModulePath")
[Environment]::SetEnvironmentVariable("PSModulePath",$p)
[Environment]::GetEnvironmentVariable("PSModulePath")

import-module ARSoft_Sql -verbose


#$cn = get-connection "(local)"
#$cmd = get-command $cn "SELECT Left(cast(@xml as varchar(max)),10) "
[System.XML.XMLDocument]$xml=New-Object System.XML.XMLDocument 
[System.XML.XMLElement]$root=$xml.CreateElement("context")
$xml.appendChild($root)| Out-Null

[System.XML.XMLElement]$alert=$xml.CreateElement("alert")
$root.appendChild($alert)| Out-Null


#$cmd = get-command $cn "SELECT @xml" $parameter

# $cmd.Parameters.Add($parameter)| Out-Null

$parameter = GEt-SqlXmlParameter "@xml" $xml
#$cn.Open()
$sql = "SET @xml.modify('         
insert <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>   
into (/context/alert)[1]')
SELECT @xml 
"

$r = Get-SqlReader "(local)" $sql "master" -parameters @($parameter) 
#$r = $cmd.ExecuteReader()
#$r |gm

#Write-Host $r.GetType().Name

$r.Read()| Out-Null

$ret = $r[0]
$ret

[System.XML.XMLDocument]$xml2=New-Object System.XML.XMLDocument 
$xml2.LoadXml($r[0])
$xml2.OuterXml

$r.Close()

