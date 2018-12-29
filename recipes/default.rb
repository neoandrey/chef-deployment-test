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


if node['platform'] != 'windows'
   include_recipe 'tar::default'
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
					is_node_running =    command_out.stdout.nil? ||  command_out.stdout.empty?
			end	
			  action:run
		end
		if  !is_node_running
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
			if   !File.exists?(config_file) || (source_file_time.to_i  > local_file_time.to_i) || node[:force_deploy] 
				should_deploy = true 
			end
		end
	end

	puts "should_deploy #{should_deploy}"
	if   should_deploy 
		if node['platform'] == 'windows' 
			execute "extract repo #{node[:local_repo_archive]}" do
			  command  "PowerShell Expand-Archive -Path \" #{node[:local_repo_archive]} \" -DestinationPath \" #{node[:repo_expansion_folder]} \"  -Force"
			end
		else

		 execute "extract repo: #{node[:local_repo_archive]}" do
			  command  "unzip \" #{node[:local_repo_archive]} \" -d \" #{node[:repo_expansion_folder]} \" "
		end
			  
	
		if   ::File.exist?("#{node[:site_folder]}") 

					if node['platform'] == 'windows'
						execute 'copy_files_from_extracted_folder_nodejs-kayxlavcomms-master-overwrite' do
						  command  "xcopy /s /d /e \"#{node[:local_repo_expansion_folder]}*.*\"  \"#{node[:site_folder]}\" "
						end
					else
					 node['platform'] != 'windows'
					 execute 'copy_files_from_extracted_folder_nodejs_nodejs-kayxlavcomms-master' do
						  command  "cp -rp \"#{node[:local_repo_expansion_folder]}*.*\"  \"#{node[:site_folder]}\""
						end
						  
					end
		else
			ruby_block "rename_extracted_repo_folder" do
				block do
				::File.rename("#{node[:local_repo_expansion_folder]}","node[:local_repo_expansion_folder]")
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
					"mongo_host_name"  => node[:mongo_host_name] ,
					"mongo_port_number" =>  node[:mongo_port_number] ,
					"refresh_structure" => node[:refresh_structure],
					"mongo_collection_name" => node[:mongo_collection_name],
				)
		end
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
	ruby_block "check_if_node_is_running" do
		block do
				Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
				command = 'ps -aux | grep node'
				command_out = shell_out(command)
				is_node_running =    command_out.stdout.nil? ||  command_out.stdout.empty?
		end	
		  action:run
	end
	if  !is_node_running
#	execute 'start_node_app' do
#		command "#{node[:start_command]}"
#	  end
      script 'start_node_app' do
		code  "#{node[:start_command]}"
	  end

	end
end