function Get-LogsAndExportToCSV {

    param (

        [string] $workspaceId,

        [string] $clientId,

        [string] $clientSecret,

        [string] $tenantId,

        [string] $startTime,

        [string] $endTime,

        [string] $csvFilePath

    )

 

    $resource = https://api.loganalytics.io

    $authority = https://login.microsoftonline.com/$tenantId/oauth2/token

    $authBody = @{

        resource = $resource

        client_id = $clientId

        client_secret = $clientSecret

        grant_type = 'client_credentials'

    }

    $authResponse = Invoke-RestMethod -Method Post -Uri $authority -Body $authBody -ErrorAction Stop

    $token = $authResponse.access_token

    $headers = @{

        'Content-Type' = 'application/json'

        Accept = 'application/json'

        Authorization = "Bearer $token"

    }

 

    $intervalMinutes = 60  # Adjust as needed based on your query and API response

    $currentTime = [datetime]::Parse($startTime)

    $endTime = [datetime]::Parse($endTime)

    $allLogs = @()

 

    while ($currentTime -lt $endTime) {

        $nextTime = $currentTime.AddMinutes($intervalMinutes)

        if ($nextTime -gt $endTime) {

            $nextTime = $endTime

        }

 

        $query = "let startDateTime = datetime('$currentTime'); let endDateTime = datetime('$nextTime'); $kqlQuery"

        $body = @{

            query = $query

            timespan = "$currentTime/$nextTime"

        } | ConvertTo-Json

 

        $url = https://api.loganalytics.io/v1/workspaces/$workspaceId/query

        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

 

        $logs = $response.tables[0].rows | ForEach-Object {

            $columnName = "TimeGenerated" 

                                             $columnValue = $_[0] 

                                             if ($columnName -eq "TimeGenerated") { 

                                                            $columnValue = [datetime]$columnValue 

                                                            $columnValue = $columnValue.ToString("yyyy-MM-dd, HH:mm:ss.fff") 

                                             } 

                                               

                                             $timestamp = $columnValue

            [PSCustomObject]@{

                TimeGenerated = $timestamp

                ContainerName = $_[1]

                SpanId = $_[2]

            }

        }

 

        $allLogs += $logs

        $currentTime = $nextTime

    }

 

    # Export all logs to CSV

    $allLogs | Export-Csv -Path $csvFilePath -NoTypeInformation

}

 

$workspaceId = "$env:WORKSPACE_ID"

$clientId = "$env:CLIENT_ID"

$clientSecret = "$env:CLIENT_SECRET"

$tenantId = "$env:TENANT_ID"

$startTime = "$env:START_TIME"

$endTime = "$env:END_TIME"

$kqlQuery = "$env:KQL_QUERY"

$csvFilePath = "query_results.csv"

Get-LogsAndExportToCSV -workspaceId $workspaceId -clientId $clientId -clientSecret $clientSecret -tenantId $tenantId -startTime $startTime -endTime $endTime -csvFilePath $csvFilePath