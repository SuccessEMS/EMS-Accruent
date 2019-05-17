Param (
    $AwsEnv
)
Try 
{
	[xml] $helpConfig =  gc ".\HelpBuild.xml"


$workdir = $PSScriptRoot 

	foreach ($project in $helpConfig.projects.project)
	{

           
		# Check for env
		if ($AwsEnv -eq 'stage'){
		   $AccessKey = $Env:stage_aws_key
		   $Secret = $Env:stage_aws_secret_key
		   $bucket = $project.stagebucket
		} elseif ($AwsEnv -eq 'prod'){
		   $AccessKey = $Env:prod_aws_key
		   $Secret = $Env:prod_aws_secret_key
		   $bucket = $project.prodbucket
		}

		Write-Host "Set-AWSCredentials -AccessKey $AccessKey -SecretKey $Secret -StoreAs $AwsEnv"
		Set-AWSCredentials -AccessKey $AccessKey -SecretKey $Secret -StoreAs $AwsEnv
	   
	   foreach ($target in $project.targets.target)
	   {
		   $name = $target.name
		   #$outputdir = "$workdir\Output\$env:UserName\$name"
		   $outputdir = "$workdir\Output\system\$name"
	           $prefix = $target.dest
		   $repo = $project.repo
	       Write-Host Uploading files for repo $repo to  s3 bucket $bucket in folder $prefix
		   Write-Host Working in local directory $outputdir
		   Set-Location -Path $outputdir

		   #Delete all existing files before uploading new ones
           Write-Host Deleting current files for repo: $repo under s3 bucket $bucket/$prefix
           Get-S3Object -BucketName $bucket -KeyPrefix $prefix -ProfileName $AwsEnv | % { Remove-S3Object -BucketName $bucket -Key $_.Key -Force:$true -ProfileName $AwsEnv }

		   #Upload files at root of directory
		   $files = Get-ChildItem -File 
		   foreach ($file in $files){
			 Write-Host "Uploading file: $file"
			 Write-Host "Write-S3Object -BucketName $bucket -File $file -Key "$prefix/$file" -CannedACLName public-read -ErrorAction Stop"
			 Write-S3Object -BucketName $bucket -File $file -Key "$prefix/$file" -CannedACLName public-read -ErrorAction Stop -ProfileName $AwsEnv 
		   }

		   #Upload folders in root of directory 
		   $folders = Get-ChildItem -Directory
		   foreach ($folder in $folders){
			 Write-Host "Uploading folder: $folder"
			 Write-Host "Write-S3Object -BucketName $bucket -Folder $folder -KeyPrefix "$prefix/$folder" -Recurse -ErrorAction Stop"
			 Write-S3Object -BucketName $bucket -Folder $folder -KeyPrefix "$prefix/$folder" -Recurse -ErrorAction Stop -ProfileName $AwsEnv 
		   }

	 }
   }
}
Catch
{
        $ErrorMessage = $_.Exception.Message
        Write-Host "Failed to upload: $ErrorMessage"
        exit(1)
}
