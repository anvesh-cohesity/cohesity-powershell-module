function Get-CohesityStorageDomain {
    <#
        .SYNOPSIS
        Request to fetch all storage domain (view box) filtered by specified parameters.
        .DESCRIPTION
        The Get-CohesityStorageDomain function is used to fetch list of all storage domain (view box) information using REST API or specific storage domain information based on specified parameters. If no parameters are specified, all storage domains (view boxes) on the Cohesity Cluster are returned. Specifying parameters filters the results that are returned.
        .EXAMPLE
        Get-CohesityStorageDomain
        List all storage domain (view box).
        .EXAMPLE
        Get-CohesityStorageDomain -Ids [<DomainIds]
        Returns the storage domain (view box) that are filtered out by specified id.
        .EXAMPLE
        Get-CohesityStorageDomain -Name [<DomainName>]
        Returns the storage domain (view box) that are filtered out by specified name.
        .EXAMPLE
        Get-CohesityStorageDomain -FetchStats true
        Specifies whether to include usage and performance statistics information along with the list of storage domain (view box).
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string[]]$Ids = $null,
        [Parameter(Mandatory = $false)]
        [string[]]$Name = $null,
        [Parameter(Mandatory = $false)][ValidateSet("true", "false")]
        [string]$FetchStats
    )

    Begin {
        if (-not (Test-Path -Path "$HOME/.cohesity")) {
            throw "Failed to authenticate. Please connect to the Cohesity Cluster using 'Connect-CohesityCluster'"
        }
        $session = Get-Content -Path $HOME/.cohesity | ConvertFrom-Json

        $server = $session.ClusterUri

        $token = $session.Accesstoken.Accesstoken
    }

    Process {
        # Form query parameters
        $Parameters = [ordered]@{}
        $Parameters.Add('allUnderHierarchy', $true)
        if ($null -ne $Ids) {
            $Parameters.Add('ids', $Ids -join ',')
        }
        if ($null -ne $Name) {
            $Parameters.Add('names', $Name -join ',')
        }
        if ($FetchStats) {
            $Parameters.Add('fetchStats', $FetchStats)
        }

        $queryString = $null
        if ($null -ne $Parameters.Keys) {
            $queryString = '?' + ($Parameters.Keys.ForEach({"$_=$($Parameters.$_)"}) -join '&')
        }

        # Construct URL & header
        $url = $server + '/irisservices/api/v1/public/viewBoxes'
        $url = $url + $queryString
        $headers = @{'Authorization' = 'Bearer ' + $token }

        $StorageDomainList = Invoke-RestApi -Method 'Get' -Uri $url -Headers $headers
        $StorageDomainList

        if ($null -eq $StorageDomainList) {
            if ($Global:CohesityAPIError) {
                if ($Global:CohesityAPIError.StatusCode -eq 'NotFound') {
                    $errorMsg = "Storage domain (View Box) doesn't exist."
                    Write-Warning $errorMsg
                } else {
                    $errorMsg = "Failed to fetch Storage Domain (View Box) information with an error : " + $Global:CohesityAPIError
                }
            } else {
                $errorMsg = "Storage domain (View Box) doesn't exist."
                Write-Warning $errorMsg
            }
            CSLog -Message $errorMsg
        }
    } # End of process
} # End of function
