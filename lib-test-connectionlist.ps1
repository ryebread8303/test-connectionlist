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
    
    .PARAMETER TimeoutInSeconds
    Specifies the number of seconds the command will wait for a response.
    
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
    
    .NOTES
    Author: O'Ryan Hedrick
    Date: 09/19/2018
#>
function Test-ConnectionList {
[CmdletBinding()]
Param(            
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]            
    $HostName,
    $PingCount = 2,
    $TimeoutInSeconds = 2
    )

    begin{
        # this function is used to create the ping jobs
        function ping-host {
            write-verbose "pinging $HostName"
            $TestConnectionBlock = {param($hostname,$Count,$Delay) test-connection "$hostname" -count $Count -delay $Delay -quiet}
            $jobname = "$hostname"
            $pingargs = @($hostname,$PingCount,$TimeoutInSeconds)
            start-job -scriptblock $TestConnectionBlock -name $jobname -argumentlist $pingargs | Out-Null
        }
        $joblist = @()
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
    # *** ping each host on the list. Use jobs so that all machines can be pinged at once. ***
    ping-host $hostname
    $joblist += "$hostname"
    write-debug "the job list is now $joblist"
    } # end process block

    End{
    write-debug "jobs are $joblist"
    # wait until jobs are done
    $joblist | ForEach-Object{
    Write-Verbose "Waiting on $_"
    Wait-Job -name $_ | Out-Null
    }
    Write-Verbose "All jobs done"
    # retreive the results of each job and add to table
    $joblist | ForEach-Object{
        $result = Receive-Job -name $_
        $row = $table.NewRow()
        $row.HostName = $_
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