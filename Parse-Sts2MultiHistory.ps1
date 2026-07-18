param(
    [string] $profileName = 'profile1',
    [int] $minAscension = 0
)

### CHANGE THIS VALUE TO YOUR STEAM ID.
# on windows that's at C:\Program Files (x86)\Steam\userdata\ and will be a folder there. If your account is the only one there, great! you're done looking, just copy that string of digits and overwrite the 0 below. If you share a computer with someone else who has a different account, I **think** there should be seperate folders, but don't actually know.
$steamId = 36517658

$csvName = "STS2_Multi_Run_Summary.csv"
$summaryCsvName = "STS2_Multi_Data_Summary.csv"
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
        $json = Get-Content -Path $file.FullName | ConvertFrom-Json | Where-Object { $_.players.Count -gt 1 } | Select-Object ascension, win, build_id -ExpandProperty players | Select-Object -Property ascension, character, win, relics, build_id
        
        if ($json) {
            $characters = $(foreach ($c in $json.character) { (Get-Culture).TextInfo.ToTitleCase($c.Replace('CHARACTER.', '').ToLower()) }) | Sort-Object

            $characters = $characters -join ","
            $win = $json.win -contains $true

            [PSCustomObject] @{
                File      = $_.Name
                Ascension = $json.ascension[0]
                Result    = If ($win) { "Win" } Else { "Loss" }
                Version   = $json.build_id[0]
                Character = $characters
            }

        }
    } ) | Export-Csv -Path $savedRuns.Path -Append -NoTypeInformation

Import-Csv -Path $savedRuns.Path  | Where-Object { $_.Ascension -in $desiredAscenions } | Group-Object -Property Ascension, Result, Character -NoElement | ForEach-Object {
    $summary = $_.Name -split ", "
    [PSCustomObject]@{
        Ascension = [int]$summary[0]
        Result    = $summary[1]
        Character = $summary[2].Replace(',', ', ')
        Count     = $_.Count
    }
} | Sort-Object  Ascension, Result, Character, Count
