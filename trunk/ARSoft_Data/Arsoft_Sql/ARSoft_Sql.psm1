Function Get-SqlValue
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$instance,
        [Parameter(Mandatory=$False,Position=2)][string]$command,
        [Parameter(Mandatory=$False,Position=3)][string]$database,
        [Parameter(Mandatory=$False,Position=4)][string]$login = $null, 
        [Parameter(Mandatory=$False,Position=5)][string]$password = $null 
        )
    PROCESS 
    {
        $ds = Get-SqlDataSet -instances $instance -command $command -database $database -login $login -password $password
	$value = $ds.Tables[0].Rows[0][0]
	Write-Verbose "Get-SqlValue: $value; Instance = $instance; Command = $command; Database = $database"
        Write-Output $value
    }
}

Function Get-SqlDataSet
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$instances,
        [Parameter(Mandatory=$False,Position=2)][string]$command,
        [Parameter(Mandatory=$False,Position=3)][string]$database,
        [Parameter(Mandatory=$False,Position=4)][string]$tableName,
        [Parameter(Mandatory=$False,Position=5)][string]$login = $null, 
        [Parameter(Mandatory=$False,Position=6)][string]$password = $null,
        [Parameter(Mandatory=$False,Position=7)][System.Data.SqlClient.SqlParameter[]]$parameters = $null, 
        [Parameter(Mandatory=$False,Position=8)][string]$AppName = "" 

        )
    PROCESS 
    {
        foreach ($instance in $instances)
        {
            $SqlConnection = Get-SqlConnection $instance $database -login $login -password $password -AppName $AppName
            $SqlCmd = Get-SqlCommand $SqlConnection $command $parameters
            $SqlConnection.Open()
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $SqlCmd
            $DataSet = New-Object System.Data.DataSet
            $table = $tableName
            if ([system.String]::IsNullOrEmpty($table)) { $table = "Tabla1" }
            $ret = $SqlAdapter.Fill($DataSet, $table)
            $SqlConnection.Close()
            $SqlConnection.Dispose()
            $rows = $DataSet.Tables[$table].Rows.Count
    	    Write-Verbose "Get-SqlDataSet: rows = $rows; Instance = $instance; Command = $command; Database = $database"
            Write-Output $DataSet
        }
    }
}
 
Function Invoke-SqlCommand
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$instances,
        [Parameter(Mandatory=$False,Position=2)][string]$command,
        [Parameter(Mandatory=$False,Position=3)][string]$database,
        [Parameter(Mandatory=$False,Position=4)][string]$login = $null, 
        [Parameter(Mandatory=$False,Position=5)][string]$password = $null,
        [Parameter(Mandatory=$False,Position=6)][System.Data.SqlClient.SqlParameter[]]$parameters = [System.Data.SqlClient.SqlParameter[]]$null,
        [Parameter(Mandatory=$False,Position=7)][string]$AppName = "" 
        )
    PROCESS 
    {
        foreach ($instance in $instances)
        {
            $SqlConnection = Get-SqlConnection $instance $database -login $login -password $password -AppName $AppName
            $SqlCmd = Get-SqlCommand $SqlConnection $command $parameters
            $SqlConnection.Open()
            $rows = $SqlCmd.ExecuteNonQuery();
            $SqlConnection.Close()
            $SqlConnection.Dispose()
            Write-Output $rows
    	    Write-Verbose "Invoke-SqlCommand: rows = $rows; Instance = $instance; Command = $command; Database = $database"
        }
    }
}
 
Function Get-SqlReader
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$instances,
        [Parameter(Mandatory=$False,Position=2)][string]$command,
        [Parameter(Mandatory=$False,Position=3)][string]$database,
        [Parameter(Mandatory=$False,Position=4)][string]$login = $null, 
        [Parameter(Mandatory=$False,Position=5)][string]$password = $null,
        [Parameter(Mandatory=$False,Position=6)][System.Data.SqlClient.SqlParameter[]]$parameters = $null,
        [Parameter(Mandatory=$False,Position=7)][string]$AppName = "" 

        )
    PROCESS 
    {
        foreach ($instance in $instances)
        {
            $SqlConnection = Get-SqlConnection $instance $database -login $login -password $password -AppName $AppName
            $SqlCmd = Get-SqlCommand $SqlConnection $command $parameters
            $SqlConnection.Open()
    	    Write-Verbose "Get-SqlReader: Instance = $instance; Command = $command; Database = $database"
            $reader = [System.Data.SqlClient.SqlDataReader]$SqlCmd.ExecuteReader([System.Data.CommandBehavior]::CloseConnection)
            return ,$reader
        }
    }
}

$handler_Connection_InfoMessage=
{
param([object]$sender, [System.Data.SqlClient.SqlInfoMessageEventArgs]$e)
    WriteHost e.Message
}

Function Get-SqlConnection{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$instance,
        [Parameter(Mandatory=$False,Position=2)][string]$database,
        [Parameter(Mandatory=$False,Position=3)][string]$login = $null, 
        [Parameter(Mandatory=$False,Position=4)][string]$password = $null, 
        [Parameter(Mandatory=$False,Position=5)][string]$AppName = "" 
        )
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
            if ([system.String]::IsNullOrEmpty($database)) { $database = "master" }
            $connectionString = "Server=$instance;Database=$database;"
            if ([system.String]::IsNullOrEmpty($AppName)) { $connectionString += "App=$AppName;" }
            if ([system.String]::IsNullOrEmpty($login)) {
                $connectionString += "Integrated Security=True;"
            } else {
                $connectionString += "user id=$login;password=$password;"
            }
            $SqlConnection.ConnectionString =  $connectionString
    	    Write-Verbose "Get-SqlConnection: Instance = $instance; Database = $database"
            $a=Register-ObjectEvent $SqlConnection InfoMessage -Action { 
                    #$Event | Out-Host 
                    write-host $Event.SourceEventArgs
                    }
#            $SqlConnection.InfoMessage += $handler_Connection_InfoMessage
            $SqlConnection
}

Function Get-SqlCommand{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][System.Data.SqlClient.SqlConnection]$SqlConnection,
        [Parameter(Mandatory=$True,Position=2,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$command,
        [Parameter(Mandatory=$False,Position=3)][System.Data.SqlClient.SqlParameter[]]$parameters = $null 
        )
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $commandText = $command
            if ([System.IO.File]::Exists($command) -or $command.ToLower().EndsWith(".sql")) 
                { $commandText = Get-Content $command | Out-String}

            $SqlCmd.CommandText = $commandText
            $SqlCmd.Connection = $SqlConnection
            $SqlCmd.CommandTimeout = 0
			Write-Verbose "Get-SqlConnection: parameters = $parameters"

            foreach($par in $parameters){
                if ($par) { $SqlCmd.Parameters.Add($par) | Out-Null }
            }
            #$cn = $SqlConnection.ConnectionString
            #Write-Host "Connection: $cn   -  Command: $command"
            $SqlCmd
}

Function Get-SqlXmlParameter{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1)][string]$name,
        [Parameter(Mandatory=$True,Position=2)][System.XML.XMLDocument]$xml 
        )
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($xml.OuterXml)
        $m = new-object System.IO.MemoryStream 
        $m.Write($bytes, 0,$bytes.length)

        $p = new-object System.Data.SqlTypes.SqlXml -ArgumentList @($m)
        $parameter = new-object System.Data.SqlClient.SqlParameter -ArgumentList @("@xml", $p)
        $parameter
}

Function Get-SqlParameter{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1)][string]$name,
        [Parameter(Mandatory=$True,Position=2)][string]$value
        )
        $parameter = new-object System.Data.SqlClient.SqlParameter -ArgumentList @($name, $value)
        $parameter
}


Function Get-DataTable
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][System.Data.DataSet[]]$datasets
        )
    PROCESS 
    {
        foreach ($ds in $datasets)
        {
            $ds.Tables
        }
    } 
}

Function Get-DataRow
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][System.Data.DataTable[]]$dataTables
        )
    PROCESS 
    {
        foreach ($datatable in $dataTables)
        {
            foreach ($row in $datatable)
            {
                Write-Output $row
            }
        }
    }
}

Function Merge-Dataset
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][System.Data.DataSet[]]$datasets
        )
    BEGIN {
        $dsMerge = New-Object -typename System.Data.DataSet 
    }
    PROCESS 
    {
        foreach ($ds in $datasets)
        {
            $dsMerge.Merge($ds)
        }
    }
    END {$dsMerge}
}

Function Export-DataTable
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][System.Data.DataTable[]]$datatables,
        [Parameter(Mandatory=$False,Position=2)][string]$outputFile
        )
    BEGIN {
    }
    PROCESS 
    {
        foreach ($dt in $datatables)
        {
            $sb = New-Object -typename System.Text.StringBuilder 
            [void]$sb.Append("<table border='1' cellspacing='0'><tr>")
            foreach($col in $dt.Columns)
            {
                [void]$sb.AppendFormat("<th>{0}</th>", $col.ColumnName)
            }
            [void]$sb.Append("</tr>")
            foreach($row in $dt.Rows)
            {
                [void]$sb.Append("<tr>")
                foreach($col in $dt.Columns)
                {
                    [void]$sb.AppendFormat("<td>{0}</td>", $row[$col])
                }
                [void]$sb.Append("</tr>")
            }
            [void]$sb.Append("</table>")
            if ([System.String]::IsNullOrEmpty($outputFile)) { $outputFile = $dt.TableName }
            if (!$outputFile.ToLower().EndsWith(".htm")) { $outputFile = $outputFile + ".htm" }
            Set-Content $outputFile $sb.ToString()
        }
    }
}

Function Export-SqlToHtml
{
    [CmdletBinding()]param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$instances,
        [Parameter(Mandatory=$True,Position=2)][string]$command,
        [Parameter(Mandatory=$False,Position=3)][string]$outputFile
        )
        get-dataset $instances $command | Merge-dataset | Get-Datatable | export-datatable -outputFile $outputFile
}

<#

$ds = Get-DataSet localhost "select getdate()"
Write-Host $ds.Tables[0].TableName
Write-Host $ds.Tables[0].Rows[0][0]

GetDataset -instances localhost,localhost "select getdate()" | SELECT  {$_.Tables[0].Rows[0][0]} | format-table

GetDataset -instances localhost,localhost "select getdate()" | Get-DataTable  | format-table


#GetDataset -instances localhost,localhost "select getdate()" | Get-DataTable | SELECT { $_.GetType().Name }

#GetDataset -instances localhost,localhost "select getdate()" | Get-DataTable  | Get-DataRow | format-table

Get-Dataset -instances localhost,localhost "select getdate() as kk" | Get-DataTable | Get-DataRow



Get-Dataset -instances localhost,localhost "select getdate() as kk" | Get-DataTable | WHERE {$_.TableName -eq "Tabla1"} | Get-DataRow

Get-Dataset -instances localhost,localhost "select getdate() as kk" | Merge-Dataset | Get-DataTable | WHERE {$_.TableName -eq "Tabla1"} | Get-DataRow

Get-Dataset -instances localhost,localhost "select getdate() as kk" | SELECT { $_.GetType().Name }

Export-SqlToHtml -instances localhost,localhost "select getdate() as kk" "kk"

Export-SqlToHtml -instances localhost,localhost "EjecucionesActuales.sql"  "kk2"
invoke-sqlcommand localhost -command "exec xp_cmdshell 'dir'"

#>
 
