<#
    .SYNOPSIS
    Pings a list of computers.
    
    .DESCRIPTION
    The test-connectionlist function reads hostnames from a text file, pings
    each host asynchronously, and returns a data table containing the hostname
    and whether it responded to ping. The text file should contain each hostname on a seperate line.
    
    .PARAMETER Hostname
    Specifies the hostname to ping.
    
    .PARAMETER PingCount
    Specifies the number of pings sent to each host.
    
    .EXAMPLE
    PS scriptrepo:\> get-content .\iplist.txt | test-connectionlist

    HOSTNAME                                                                                                    ONLINE                                                                                                     
    --------                                                                                                    ------                                                                                                     
    8.8.8.8                                                                                                     False                                                                                                      
    www.google.com                                                                                              False                                                                                                      
    19.130.33.1                                                                                                 True                                                                                                       
    127.0.0.1                                                                                                   True  
    
    .INPUTS
    Piped list of ip addresses or hostnames as strings.
    
    .OUTPUTS
    Test-Connectionlist will return a table constructed using System.Data.DataTable
    
    .LINK
    Test-Connection
    
    .LINK
    Start-Job
#>
function Test-ConnectionList {
[CmdletBinding()]
Param(            
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]            
    $HostName,
    $PingCount = 2
    )

    begin{
        $joblist = @()
        $hostnames = @()
        write-debug "the jobs list starts as $joblist"
        # *** create table of hostnames and whether the host responded to ping ***
        $table = $null
        $tabname = "Ping Results Table"
        $table = New-Object system.Data.DataTable “$tabName”
        $col1 = New-Object system.Data.DataColumn HOSTNAME,([string])
        $col2 = New-Object system.Data.DataColumn ONLINE,([string])
        $table.columns.add($col1)
        $table.columns.add($col2)

    } # end begin block

    Process{
        # create a list of machines to ping
        Write-Verbose "Adding $hostname to list."
        $hostnames += $HostName
        } # end process block

    End{
        # *** ping each host on the list. Use jobs so that all machines can be pinged at once. ***
        $hostnames | ForEach-Object{
            write-verbose "pinging $Name $PingCount times."
            $name = $_
            $TestConnectionBlock = {param($name,$Count) test-connection "$name" -count $Count -quiet}
            $jobname = "$name"
            $pingargs = @($name,$PingCount)
            $joblist += start-job -scriptblock $TestConnectionBlock -name $jobname -argumentlist $pingargs
            write-debug "the job list is now $joblist"
        } # end foreach-object
        # wait until jobs are done
        Write-Verbose "Waiting on jobs"
        Wait-Job $joblist | Out-Null
        Write-Verbose "All jobs done"
        # retreive the results of each job and add to table
        $joblist | ForEach-Object{
            $result = Receive-Job $_
            $row = $table.NewRow()
            $row.HostName = $_.Name
            $row.Online = $result
            $table.Rows.Add($row)
        }
        # remove the jobs
        $joblist | ForEach-Object{
            Remove-Job $_
        }
        # *** sort the results, displaying offline hosts first ***
        $table | sort -property online | ft hostname,online
    } # end end block
} # end function block