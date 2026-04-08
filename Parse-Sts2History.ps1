param(
    [string] $profileName = 'profile1',
    [int] $minAscension = 0
)

$csvName = "STS2_Run_Summary.csv"
$summaryCsvName = "STS2_Data_Summary.csv"
$desiredAscenions = $minAscension..10 | ForEach-Object { $PSItem.ToString() }

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
        $tempPath = "C:\Program Files (x86)\Steam\userdata\36517658\2868840\remote\$profileName\saves\history"
    }
    
    if ($IsMacOS) {
        $tempPath = "~/Library/Application Support/Steam/userdata/36517658/2868840/remote/$profileName/saves/history"
    }

    return $tempPath
}


$stsPath = Get-HistoryPath
$savedRuns = Initialize-DataStorage
$lastAccess = [DateTime]::MinValue

if ($savedRuns -And $savedRuns.Data.Length -and $savedRuns.Data.Length -GT 0) {
    $lastAccess = $savedRuns.LastWrite
}

Get-ChildItem -Path $stsPath 
| Where-Object -Property LastWriteTime -GT $lastAccess 
| ForEach-Object -Parallel {
    $json = Get-Content $_ 
    | ConvertFrom-Json 
    | Where-Object { $_.players.Count -eq 1 } 
    | Select-Object ascension, win, build_id -ExpandProperty players
    | Select-Object -Property ascension, character, win, relics, build_id 

    if ($json) {
        [PSCustomObject] @{
            File      = $_.Name
            Ascension = $json.ascension
            Result    = $json.win ? "Win" : "Loss"
            Character = (Get-Culture).TextInfo.ToTitleCase($json.character.Substring($json.character.IndexOf('.') + 1).ToLower())
            Version   = $json.build_id
            Relics    = $json.Relics | Select-Object -ExpandProperty id | Join-String { (Get-Culture).TextInfo.ToTitleCase($_.Substring($_.IndexOf('.') + 1 ).ToLower()).Replace('_', ' ') } -Separator ', '
        } 
    }
} -ThrottleLimit 4
| Export-Csv -Path $savedRuns.Path -Append -NoTypeInformation

Import-Csv -Path $savedRuns.Path  | Where-Object { $_.Ascension -in $desiredAscenions } | Group-Object -Property Ascension, Character, Result -NoElement | ForEach-Object {
    $summary = $_.Name.Split(', ')
    [PSCustomObject]@{
        Character = $summary[1]
        Ascension = [int]$summary[0]
        Result    = $summary[2]
        Count     = $_.Count
    }
} | Sort-Object  Ascension, Character, Result, Count
