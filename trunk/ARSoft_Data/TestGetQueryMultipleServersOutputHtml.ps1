./import-module.ps1
get-content instancias.txt | get-dataset -command "query.sql" -database "master" | Merge-dataset | Get-DataTable | Export-DataTable -outputfile "TestResults\ResultTestGetQueryMultipleServersOutputHtml.htm"
