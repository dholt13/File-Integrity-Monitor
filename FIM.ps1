Write-Host "Hello, what would you like to do today?`n"
Write-Host "   1) Begin mointoring files with saved Baseline?"
Write-Host "   2) Create a new Baseline?"

$response = Read-Host -Prompt "Please enter 1 or 2"

Function Calculate-File-Hash($file){
    $file = Get-FileHash -Path $file -Algorithm SHA512
    return $file
}

Function If-Baseline-Already-Exist(){
    $baseline = Test-Path -Path .\baseline.txt 

    if ($baseline) {
        Remove-Item -Path .\baseline.txt
    }
}

Function Write-Baseline-To-File($file){
    foreach ($f in $file) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}


if ($response -eq '1'){
    # Create a dictionary to load file | hash
    $hashDictionary = @{}

    $pathAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $pathAndHashes) {
        $hashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }
    
    #Check continuosly see if the baseline changed

    while ($true) {
        Start-Sleep -Seconds 1

        $file = Get-ChildItem -Path .\Files

        foreach ($f in $file) {
           $hash = Calculate-File-Hash $f.FullName

           # Print the current date and time to logs.txt file
           $CurrentDate = Get-Date
           $CurrentDate | Out-File -FilePath .\logs.txt

           # Check to see if a file has been created and notifies the user
           if ($hashDictionary[$hash.Path] -eq $null) {
               "$($hash.Path) has been created!" | Out-File -FilePath .\logs.txt -Append
           } 
           # Check to see if a file hasn't been and notifies the user
           elseif ($hashDictionary[$hash.Path] -eq $hash.Hash) {
               "$($hash.Path) hasn't been changed" | Out-File -FilePath .\logs.txt -Append 
           }
           # Check to see if a file has been changed and notifies the user
           else {
               "$($hash.Path) has been changed" | Out-File -FilePath .\logs.txt -Append
           }
        }

        foreach ($key in $hashDictionary.Keys) {
            $baselineFileStillExist = Test-Path -Path $key
            if (-Not $baselineFileStillExist) {
                "$($key) has been deleted!" | Out-File -FilePath .\logs.txt -Append
            }
        }
         
    }
}
elseif ($response -eq '2') {
    If-Baseline-Already-Exist
    
    $file = Get-ChildItem -Path .\Files

    Write-Baseline-To-File($file)
}
else {
    Write-Host "You have enter an invalid response."
}
