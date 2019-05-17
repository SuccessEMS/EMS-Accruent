Try
{
    [xml] $helpConfig =  gc ".\HelpBuild.xml"

    foreach ($project in $helpConfig.projects.project)
    {
        $flare = $project.flarepath
        $projectPath = $project.path
        Write-Host "Buiding $projectPath"

        $projectPath = Resolve-Path "$projectPath"
        Write-Host "Project path = $projectPath"

        $projectDir = [System.IO.Path]::GetDirectoryName($projectPath)

        foreach ($target in $project.targets.target)
        {
            $targetName = $target.name
            Write-Host "Target = $targetName"
            Write-Host "& '$flare'  -project '$projectPath' -target '$targetName'"
            iex "& '$flare'  -project '$projectPath' -target '$targetName'"
        }
    }
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    Write-Host "Failed to Build Guide: $ErrorMessage"
    exit(1)
}
