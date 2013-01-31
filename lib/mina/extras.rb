task :setup do
  invoke :create_extra_paths
  invoke :'god:setup'
  invoke :'god:upload'
  invoke :'unicorn:upload'
  invoke :'nginx:upload'

  if sudoer?
    queue %{echo "-----> (!!!) You now need to run 'mina sudo_setup' to run the parts that require sudoer user (!!!)"}
  else
    invoke :sudo_setup
  end
end

desc 'Invoke setup tasks, that requires sudo privileges'
task :sudo_setup do
  invoke :sudo
  invoke :'god:link'
  invoke :'unicorn:link'
  invoke :'nginx:setup'
  invoke :'nginx:link'
end

desc 'Create extra paths for shared configs, pids, sockets, etc.'
task :create_extra_paths do
  queue 'echo "-----> Create configs path"'
  queue echo_cmd "mkdir -p #{config_path}"

  queue 'echo "-----> Create shared paths"'
  shared_dirs = shared_paths.map { |file| File.dirname("#{deploy_to}/#{shared_path}/#{file}") }.uniq
  cmds = shared_dirs.map do |dir|
    queue echo_cmd %{mkdir -p "#{dir}"}
  end

  queue 'echo "-----> Create PID and Sockets paths"'
  queue echo_cmd "mkdir -p #{pids_path} && chown #{user}:#{group} #{pids_path} && chmod +rw #{pids_path}"
  queue echo_cmd "mkdir -p #{sockets_path} && chown #{user}:#{group} #{sockets_path} && chmod +rw #{sockets_path}"
end

task :health do
  queue 'ps aux | grep -v grep | grep -v bash | grep -e "bin\/god" -e "unicorn_rails" -e "mongod" -e "nginx" -e "redis" -e "STAT START   TIME COMMAND" -e "bash"'
end

task :sudo do
  set :sudo, true
  set :term_mode, :system # :pretty doesn't seem to work with sudo well
end

def upload_template(desc, tpl, destination)
  contents = parse_template(tpl)
  queue %{echo "-----> Put #{desc} file to #{destination}"}
  queue %{echo "#{contents}" > #{destination}}
  queue check_exists(destination)
end

def parse_template(file)
  erb("#{config_templates_path}/#{file}.erb").gsub('"','\\"').gsub('`','\\\\`').gsub('$','\\\\$')
end

def check_response
  'then echo "----->   SUCCESS"; else echo "----->   FAILED"; fi'
end

def check_exists(destination)
  %{if [[ -s "#{destination}" ]]; #{check_response}}
end

def check_ownership(u, g, destination)
  %{
    file_info=(`ls -l #{destination}`)
    if [[ -s "#{destination}" ]] && [[ ${file_info[2]} == '#{u}' ]] && [[ ${file_info[3]} == '#{g}' ]]; #{check_response}
    }
end

def check_exec_and_ownership(u, g, destination)
  %{
    file_info=(`ls -l #{destination}`)
    if [[ -s "#{destination}" ]] && [[ -x "#{destination}" ]] && [[ ${file_info[2]} == '#{u}' ]] && [[ ${file_info[3]} == '#{g}' ]]; #{check_response}
    }
end

def check_symlink(destination)
  %{if [[ -h "#{destination}" ]]; #{check_response}}
end

# Allow to run some tasks as different (sudoer) user when sudo required
module Mina
  module Helpers
    def ssh_command
      args = domain!
      args = if sudo? && sudoer?
               "#{sudoer}@#{args}"
             elsif user?
               "#{user}@#{args}"
             end
      args << " -i #{identity_file}" if identity_file?
      args << " -p #{port}" if port?
      args << " -t"
      "ssh #{args}"
    end
  end
end
