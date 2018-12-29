if node['platform'] == 'windows'
 default[:repo_url]= "https://codeload.github.com/neoandrey/nodejs-kayxlavcomms/zip/master"
 default[:repo_user]= "neoandrey@yahoo.com"
 default[:local_repo_archive]=  "C:\\tmp\\nodejs-kayxlavcomms-master.zip"
 default[:local_repo_expansion_folder]=  "C:\\tmp\\nodejs\\nodejs-kayxlavcomms-master\\"
 default[:repo_expansion_folder]="C:\\tmp\\nodejs\\"
 default[:site_folder]= "C:\\tmp\\nodejs\\kayxlavcomms\\"
 default[:config_file_location]= "C:\\tmp\\nodejs\\kayxlavcomms\\config\\settings.json"
 default[:server_host_name]= "127.0.0.1"
 default[:server_port_number]= 9000
 default[:reload_port]= 9001
 default[:site_title]= "Backup and Restore Management Platform"
 default[:site_name]=  "Bakup and Restore Toolkit"
 default[:mongo_host_name] = "127.0.0.1"
 default[:mongo_port_number]= "27017"
 default[:refresh_structure]=true
 default[:mongo_collection_name]="kayxlavcoms"
 default[:start_command]=' start cmd /k C:\Progra~1\MongoDB\Server\3.4\bin\mongod.exe --dbpath ..\..\..\..\..\MongoDB\datafiles\ --logpath=..\..\..\..\..\MongoDB\logs\mongolog.log  -v --logRotate rename  --logappend -f  ..\..\..\..\..\MongoDB\mongod.conf && cd ' + default[:local_repo_expansion_folder] + ' && start cmd /k npm start && taskkill /im ruby.exe /f'
 default[:start_app_only]=false
 default[:force_deploy]=false
end 
 
 if node['platform'] != 'windows' 
 default[:repo_url]= "https://codeload.github.com/neoandrey/nodejs-kayxlavcomms/zip/master"
 default[:repo_user]= "neoandrey@yahoo.com"
 default[:local_repo_archive]=  "/tmp/nodejs-kayxlavcomms-master.zip"
 default[:local_repo_expansion_folder]=  "/tmp/nodejs/nodejs-kayxlavcomms-master/"
 default[:repo_expansion_folder]="/tmp/nodejs/"
 default[:site_folder]= "/opt/nodejs/kayxlavcomms/"
 default[:config_file_location]= "/opt/nodejs/kayxlavcomms/config/settings.json"
 default[:server_host_name]= "127.0.0.1"
 default[:server_port_number]= 9000
 default[:reload_port]= 9001
 default[:site_title]= "Backup and Restore Management Platform"
 default[:site_name]=  "Bakup and Restore Toolkit"
 default[:mongo_host_name] = "mongo"
 default[:mongo_port_number]= "27017"
 default[:refresh_structure]=true
 default[:mongo_collection_name]="kayxlavcoms"
 default[:start_command]="cd /opt/nodejs/kayxlavcomms/ && npm start"
 default[:start_app_only]=false
 default[:force_deploy]=false
 end