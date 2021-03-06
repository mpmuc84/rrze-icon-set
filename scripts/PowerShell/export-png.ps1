Param(
    #Force to overwrite existing files
    [bool]$ForceWrite = $false,
    #Warn if files not overwritten
    [bool]$WarnNotUseForce = $false,
    #workingDir can be set via script parameter
    [string]$workingDir = "",
    #Where is inkscape installed
    [string]$Inkscape = "C:\Program Files\Inkscape\inkscape.exe",
    #set file for error.log
    [string]$errorLog = "$home\error.log")

$WarningPreference = "continue"

#Allow this script to be executed
#Set-ExecutionPolicy Unrestricted CurrentUser

#make sure that counters are always zero at starttime
$i = 0
$svgCount = 0

#Core function that writes the exported png-files
function Export-PNG ($file, $fileOut, $dimension) {
    try {
        #call inkscape and wait export to finish otherwise a lot of processes are spawned and computer running this script has a heavy load
        & $Inkscape --export-png $fileOut --export-width $dimension --export-height $dimension --export-area-drawing $file  | Out-Null
    }
    catch {
        Write-Warning "Error occured: $_" | Out-File -FilePath $errorLog -Encoding utf8 -Append #-NoClobber #maybe not overwrite existing file
    }
}

#Select a folder
function Select-Folder($message='Select a folder ...', $path = "$home") { 
    $object = New-Object -comObject Shell.Application  
     
    $folder = $object.BrowseForFolder(0, $message, 0, $path) 
    if ($folder -ne $null) { 
        $folder.self.Path 
    } 
} 
 
#Function to test the correct configuration of Inkscape
function Test-inkscape {
    if (-not (Test-Path $Inkscape)) {
        Write-Error -Message "ERROR: Inkscape not found! Please correct configuration." -Category ObjectNotFound -TargetObject $inkscape | Out-File -FilePath $errorLog -Encoding utf8 -Append #-NoClobber #maybe not overwrite existing file
        exit
    }
    Else {
        return
    }
}

#Test if a file is existing and continue only if $ForceWrite is TRUE
function Test-ExistingOrForce ($fileOut) {
    If ((-not (Test-Path $fileOut)) -or ($ForceWrite)) {
        return
    }
    Else {
        if ($WarnNotUseForce) {
            Write-Warning -Message "ERROR: $fileOut already existing! Please set force to overwrite." | Out-File $errorLog #-Encoding utf8 -Append #-NoClobber #maybe not overwrite existing file
            }
        Continue
    }
}

function CountSVG {
    Get-ChildItem $workingDir -recurse -filter "*.svg"| ForEach-Object{
        #we need the current file with it's full path 
        $file = $_.FullName
        #Write-Host $file
    
        $svgFileDirectory = (Get-Item $file).Directory.parent.BaseName
        #Write-Host $svgFileDirectory
    
        #Write-Host $svgCount
    
        if (($svgFileDirectory -eq "16x16") -or ($svgFileDirectory -eq "22x22")) {
            #Write-Host $file
            $global:svgCount++
            #Write-Host $svgCount
            }
            elseif ($svgFileDirectory -eq "scalable") {
                #dimensions created from scalable = (32, 48, 72, 150, 720)
                $global:svgCount = $global:svgCount + 5
                }
                else {
                    Write-Warning "Are you sure $file belongs where it is currently stored???" 
                    }
    }

}

#Calculate and show progress
function Progress-Made ($fileOut) {
    #Increment counter for progress calculation
    $global:i++ 
    
    #Calculate progress in percent and round it for beautifying reasons
    $progress = [System.Math]::Round(($global:i / $svgCount) * 100)
    
    #Show progress
    Write-Progress -activity "Generating $fileOut" -status "$global:i / $svgCount = $progress %" -PercentComplete ($progress)
}

#MAIN
function Main {

$workingDir = Select-Folder -mess 'Please select the RRZE Icon Set folder!' #-path "$home\Documents\GitHub\"
#Write-Host $workingDir

#Count the svg files in the defined $workingDir
CountSVG

#Inkscape configured right? If not terminate with Error message.
Test-inkscape

#search for all svg files
Get-ChildItem $workingDir -recurse -filter "*.svg"| ForEach-Object{
    #define fileOout based on source filename 
    $file = $_.FullName
    
    $svgFileDirectory = (Get-Item $file).Directory.parent.BaseName
    #Write-Host $svgFileDirectory
               
    switch ($svgFileDirectory)
    {
        "16x16" { 
            $dimension = 16
            $fileOut = [System.IO.Path]::ChangeExtension($file, "png")
            Test-ExistingOrForce $fileOut
            #Write-Host $fileOut
            Export-PNG $file $fileOut $dimension
            Progress-Made $fileOut
        }
        
        "22x22" {
            $dimension = 22
            $fileOut = [System.IO.Path]::ChangeExtension($file, "png")
            Test-ExistingOrForce $fileOut
            #Write-Host $fileOut 
            Export-PNG $file $fileOut $dimension
            Progress-Made $fileOut
        }       
        
        "scalable" {
            foreach ($dimension in 32,48,72,150,720) {
                $fileOut = (Get-Item $file).Directory.parent.parent.Fullname+"\"+$dimension+"x"+$dimension+"\"+(Get-Item $file).Directory.Basename+"\"+(Get-Item $file).BaseName+".png"
                Test-ExistingOrForce $fileOut
                #Write-Host $fileOut
                Export-PNG $file $fileOut $dimension
                Progress-Made $fileOut
                }
         }
    }
  }
 
invoke-item $workingDir
#Summary and quit
Write-Host "$i png files generated. Good bye."
}

Main


#compare Count in scalable with count in dimension directories - indicator for missing icons



#Reset ExecutionPolicy to be safe again
# Set-ExecutionPolicy Restricted CurrentUser

#delete test files
#(Get-ChildItem $workingDir -recurse -filter "*.2.png")|ForEach-Object {del $_.FullName}