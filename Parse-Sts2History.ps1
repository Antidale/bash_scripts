param(
    [string] $profileName = 'profile1',
    [int] $minAscension = 0
)

### CHANGE THIS VALUE TO YOUR STEAM ID.
# on windows that's at C:\Program Files (x86)\Steam\userdata\ and will be a folder there. If your account is the only one there, great! you're done looking, just copy that string of digits and overwrite the 0 below. If you share a computer with someone else who has a different account, I **think** there should be seperate folders, but don't actually know.
$steamId = 36517658

$csvName = "STS2_Run_Summary.csv"
$summaryCsvName = "STS2_Data_Summary.csv"
$desiredAscenions = $minAscension..10 | ForEach-Object { $PSItem.ToString() }

if ($steamId -eq 0) {
    Write-Host "You must set the steamId in the script"
    return
}

function Initialize-DataStorage {
    
    $dbFolder = Join-Path -Path ([environment]::GetFolderPath("ApplicationData")) -ChildPath "com.antidale.sts2data"
    
    if (-Not (Test-Path -Path $dbFolder)) {
        New-Item -Path $dbFolder -ItemType Directory
    }

    $csvPath = Join-Path -Path $dbFolder -ChildPath $csvName
    $summaryDataPath = Join-Path -Path $dbFolder -ChildPath $summaryCsvName

    if (-Not (Test-Path -Path $csvPath)) {
        New-Item -Path $dbFolder -ItemType File -Name $csvName
    }

    $csvContent = Import-Csv -Path $csvPath
    $lastWrite = Get-Item -Path $csvPath
    return [PSCustomObject]@{
        Data        = $csvContent
        LastWrite   = $lastWrite.LastWriteTime
        Path        = $csvPath
        SummaryPath = $summaryDataPath
    }
}

function Get-HistoryPath {
    
    $tempPath = ''
    if ($IsWindows) {
        $tempPath = "C:\Program Files (x86)\Steam\userdata\$steamId\2868840\remote\$profileName\saves\history"
    }
    
    if ($IsMacOS) {
        $tempPath = "~/Library/Application Support/Steam/userdata/$steamId/2868840/remote/$profileName/saves/history"
    }

    if (($tempPath -eq '') -and (!$IsLinux)) {
        $tempPath = "C:\Program Files (x86)\Steam\userdata\$steamId\2868840\remote\$profileName\saves\history"
    }

    return $tempPath
}


$stsPath = Get-HistoryPath
$savedRuns = Initialize-DataStorage
$lastAccess = [DateTime]::MinValue

if ($savedRuns -And $savedRuns.Data.Length -and $savedRuns.Data.Length -GT 0) {
    $lastAccess = $savedRuns.LastWrite
}

$relevantFiles = Get-ChildItem -Path $stsPath | Where-Object -Property LastWriteTime -GT $lastAccess

$(foreach ($file in $relevantFiles) {
        $json = Get-Content -Path $file.FullName | ConvertFrom-Json | Where-Object { $_.players.Count -eq 1 } | Select-Object ascension, win, build_id -ExpandProperty players | Select-Object -Property ascension, character, win, relics, build_id 

        if ($json) {
            $relics = $json.Relics | Select-Object -ExpandProperty id

            [PSCustomObject] @{
                File      = $_.Name
                Ascension = $json.ascension
                Result    = If ($json.win) { "Win" } Else { "Loss" }
                Character = (Get-Culture).TextInfo.ToTitleCase($json.character.Substring($json.character.IndexOf('.') + 1).ToLower())
                Version   = $json.build_id
                Relics    = $(foreach ($relic in $relics) {
                        (Get-Culture).TextInfo.ToTitleCase($relic.Substring($relic.IndexOf('.') + 1 ).ToLower()).Replace('_', ' ')
                    }) -join ", "
            }

        }
    } ) | Export-Csv -Path $savedRuns.Path -Append -NoTypeInformation

Import-Csv -Path $savedRuns.Path  | Where-Object { $_.Ascension -in $desiredAscenions } | Group-Object -Property Ascension, Character, Result -NoElement | ForEach-Object {
    $summary = $_.Name -split ", "
    [PSCustomObject]@{
        Character = $summary[1]
        Ascension = [int]$summary[0]
        Result    = $summary[2]
        Count     = $_.Count
    }
} | Sort-Object  Ascension, Character, Result, Count
