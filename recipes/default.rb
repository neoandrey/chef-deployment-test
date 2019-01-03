#
# Cookbook:: deployment_test
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
#git_settings = data_bag_item('site_management', 'git_settings')
#C:\tmp\ =/opt/nodejs

local_file_time = Time.now
source_file_time= Time.now
should_deploy =  node[:force_deploy] 
is_node_running = false
should_use_proxy = node[:should_use_proxy]
proxy_url   = nil
if  should_use_proxy 
	proxy_url   = node[:proxy_url]
end

if node['platform']  == 'windows' &&  should_use_proxy
	
	execute 'set_proxy' do
		command  "SETX HTTP_PROXY #{proxy_url}  &&  SETX HTTPS_PROXY #{proxy_url} &&  SETX FTP_PROXY #{proxy_url}"
	end
elseif node['platform'] != 'windows'
   include_recipe 'tar::default'
   template "/etc/environment" do
	source 'etc/environment.erb'
	variables( 
			  "proxy_url" => "#{proxy_url}"
		  )
  end
  
   template "root/.bashrc" do
	source 'home/bashrc.erb'
	variables( 
			  "proxy_url" => "#{proxy_url}"
			)
  end
  execute 'set_proxy' do
		  command  " export http_proxy=#{proxy_url} &&  export https_proxy=#{proxy_url} &&  export ftp_proxy=#{proxy_url} &&  export no_proxy=127.0.0.1,localhost,0.0.0.0"
  end
end

ruby_block 'get_app_repo_date' do
 block do
	if ::File.exist?("#{node[:local_repo_archive]}")
		local_file_time  =  File.stat(node[:local_repo_archive]).mtime 
	end
 end
end 

if node[:start_app_only]

	if  node['platform'] == 'windows' 
		ruby_block "check_if_node_is_running" do
			block do
					Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
					command = 'cmd /c  tasklist | findstr /i node.exe'
					command_out = shell_out(command)
					is_node_running =    command_out.stdout.nil? ||  command_out.stdout.empty?
			end	
			  action:run
		end
		if  !is_node_running
	#	execute 'start_node_app' do
	#		command "#{node[:start_command]}"
	#	  end
		  batch 'start_node_app' do
			code  "#{node[:start_command]}"
		  end
	
		end
	 else 
		ruby_block "check_if_node_is_running" do
			block do
					Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
					command = 'ps -aux | grep node'
					command_out = shell_out(command)
					is_node_running =  command_out.stdout.nil? ||  command_out.stdout.empty?
			end	
			  action:run
		end
	
	
		if  !is_node_running
		is_node_installed = false
		ruby_block "check_if_node_is_installed" do
			block do
					Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
					command = 'whereis node'
					command_out = shell_out(command)
					is_node_installed =    command_out.stdout.nil? ||  command_out.stdout.empty? || command_out.stdout=="node:" 
			end	 
			  action:run
			  notifies :run, "execute[install_node]", :immediately
		end
		execute 'install_node' do
				command "sudo yum remove nodejs.x86_64 -y && curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash - && sudo yum install nodejs -y && cd #{node[:site_folder]} && npm install -g nodemon"
				action :nothing
			end
	
	#	execute 'start_node_app' do
	#		command "#{node[:start_command]}"
	#	  end
		  script 'start_node_app' do
			code  "#{node[:start_command]}"
		  end
	
		end
	end
	

else
	remote_file "#{node[:local_repo_archive]}" do
	source  node[:repo_url]  #'https://codeload.github.com/neoandrey/nodejs-kayxlavcomms/zip/master'
	action :nothing
	use_conditional_get true
	end

	http_request "HEAD #{node[:repo_url]}" do
		message ''
		url node[:repo_url]
		action :head
		if ::File.exist?( "#{node[:local_repo_archive]}")
			headers 'If-Modified-Since' => File.mtime( "#{node[:local_repo_archive]}").httpdate
		end
		notifies :create, "remote_file[#{node[:local_repo_archive]}]", :immediately
	end

	ruby_block 'set_overwrite_flag' do
		block do
			source_file_time =	  File.stat("#{node[:local_repo_archive]}").mtime 
			config_file = node[:config_file_location]
			if   !File.exists?(config_file) || (source_file_time.to_i  > local_file_time.to_i) 
				should_deploy = true 
			end
		end
	end

	if   should_deploy 
		if node['platform'] == 'windows' 
			execute "extract repo #{node[:local_repo_archive]}" do
				command  "PowerShell Expand-Archive -Path \" #{node[:local_repo_archive]} \" -DestinationPath \" #{node[:repo_expansion_folder]} \"  -Force"
				not_if { !should_deploy}
			end
		else

		execute "install_unzip" do
			command  "sudo yum install -y unzip"
			not_if { !should_deploy}
		end
		directory "#{node[:repo_expansion_folder]}" do
			owner 'neo'
			group 'root'
			mode '0755'
			action :create
		  end
		 execute "extract repo: #{node[:local_repo_archive]}" do
				command  "sudo unzip -o \"#{node[:local_repo_archive]}\" -d \"#{node[:local_repo_expansion_folder]}\" "
				not_if { !should_deploy}
		end
			  
	
		if   ::File.exist?("#{node[:site_folder]}") 

					if node['platform'] == 'windows'
						execute 'copy_files_from_extracted_folder_nodejs-kayxlavcomms-master-overwrite' do
							command  "xcopy /s /d /e \"#{node[:local_repo_expansion_folder]}*.*\"  \"#{node[:site_folder]}\" "
							not_if { !should_deploy}
						end
					end
					if node['platform'] != 'windows'
					 execute 'copy_files_from_extracted_folder_nodejs_nodejs-kayxlavcomms-master' do
							command  "cp -r -p -u \"#{node[:local_repo_expansion_folder]}#{node[:repo_name]}\"/* \"#{node[:site_folder]}\""
							not_if { !should_deploy}
						end	  
					end
		else

			directory "#{node[:site_folder]}" do
			owner 'neo'
			group 'root'
			mode  '0766'
			action :create
		  end
			execute "rename_extracted_repo_folder" do
				command  "mv  \"#{node[:local_repo_expansion_folder]}#{node[:repo_name]}\"/* \"#{node[:site_folder]}\""
			
		end
		end
		template "#{node[:config_file_location]}" do
		  source 'config/settings.json.erb'
		  variables( 
					"server_host_name" => "#{node[:server_host_name]}",
					"server_port_number" => node[:server_port_number],
					"reload_port" => node[:reload_port],
					"site_title" => node[:site_title],
					"site_name" =>  node[:site_name] ,
					"mongo_host_name"  => "#{node[:mongo_host_name]}" ,
					"mongo_port_number" =>  node[:mongo_port_number] ,
					"refresh_structure" => node[:refresh_structure],
					"mongo_collection_name" =>  "#{node[:mongo_collection_name]}"
				)
		end
    end
end
end

if  node['platform'] == 'windows' 
	ruby_block "check_if_node_is_running" do
		block do
				Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
				command = 'cmd /c  tasklist | findstr /i node.exe'
				command_out = shell_out(command)
				is_node_running =    command_out.stdout.nil? ||  command_out.stdout.empty?
		end	
		  action:run
	end
	if  !is_node_running
#	execute 'start_node_app' do
#		command "#{node[:start_command]}"
#	  end
      batch 'start_node_app' do
		code  "#{node[:start_command]}"
	  end

	end
 else 
	ruby_block "check_if_#{node[:app_process_name]}_is_running" do
		block do
				Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
				command = "pgrep #{node[:app_process_name]}"
				command_out = shell_out(command)
				is_node_running =  command_out.stdout.nil? ||  command_out.stdout.empty?
				puts "is_node_running: #{is_node_running}"
		end	
		  action:run
	end


	if  !is_node_running
	is_node_installed = false
	execute 'clean_temp_folder' do
		command "sudo rm -rf #{node[:local_repo_expansion_folder]}/*"
	  end
	  
	ruby_block "check_if_node_is_installed" do
		block do
				Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
				command = 'whereis node'
				command_out = shell_out(command)
				is_node_installed =    command_out.stdout.nil? ||  command_out.stdout.empty? || command_out.stdout.to_s.tr(' ', '')=="node:" 
		end	 
		  action:run
		  notifies :run, "execute[install_node]", :immediately
	end
	execute 'install_node' do
			command "sudo yum remove nodejs.x86_64 -y && curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash - && sudo yum install nodejs -y && cd #{node[:site_folder]} && npm install -g nodemon"
	        action :nothing
		end
	execute  'set_access_permissions' do
     command  "sudo find  #{node[:site_folder]} -type d -exec chmod 755 {} \\; &&  find  #{node[:site_folder]} -type f -exec chmod 757 {} \\; && chmod 757 #{node[:site_folder]}/node_modules"
	end
      execute 'start_node_app' do
		command  "#{node[:start_command]}"
	  end

	end
end