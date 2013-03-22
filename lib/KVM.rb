class KVM # class to work with KVM
	def initialize
		raise "kvm or vm_dir not configured" if !$params['kvm'] || !$params['vm_dir']
		if File.exist?($params['kvm'])
			@kvm_bin = $params['kvm']
		else
			raise "kvm binary not found"
		end
		if Dir.exist?($params['vm_dir'])
			@vm_dir = $params['vm_dir']
		else
			raise "virtual machines directory not found"
		end
	end

	def list # list virtual machines
		get_vm_list
	end

	def info(vm) # information about virtual machine
	end

	def start(vm) # start virtual machine
		vm_info = $kvm_vm_list[vm]
		if (status = vm_info['status']) == 'stopped'
			result = nil
			start_script = "#{$params['vm_dir']}/#{vm}/#{$params['start_script']}"
			start_cmd =  read_start_script(start_script)
			IO.popen([*start_cmd, :err=>[:child, :out]]){|io|
				result = io.readlines
			}
			result == [] ? (return true) : (raise result.to_s)
		else
			raise "VM status = \"#{status}\""
		end
	end

	def stop(vm) # stop virtual machine
		vm_info = $kvm_vm_list[vm]
		if (status = vm_info['status']) != 'stopped'
			Process.kill(15, vm_info['pid'])
			File.delete(vm_info['pid_file']) if vm_info['pid_file']
		else
			raise "VM status = \"#{status}\""
		end
	end

	def pause(vm)
		if (result = console(vm, 'stop')) == []
			return true
		else
			raise result
		end
	end

	def resume(vm)
		if (result = console(vm, 'cont')) == []
			return true
		else
			raise result
		end
	end

	def console(vm, cmd) # communicate with VM console (-monitor)
		vm_info = $kvm_vm_list[vm]
		s = UNIXSocket.new(vm_info['socket'])

		s.puts(cmd)
		sleep 0.5
		
		string_responce = read_socket(s)

		s.flush
		s.close
		
		format_responce(string_responce)
	end

	def get_vm_list # get list of VM and different information about them
		vm_list = Hash.new
		read_vm_dir.each{|vm|
			vm_info = Hash.new

			vm_info['status'], vm_info['pid_file'], vm_info['pid'] = get_process_status(vm)
			vm_info['socket'] = get_socket_file(vm)
			
			vm_list[vm] = vm_info
		}
		vm_list
	end

	def show_config(vm) # show virtual machine configuration
	end
	
	def edit_config(vm) # edit virtual machine configuration
	end

private
	
	def read_socket(socket)
		string_responce = String.new
		while output = socket.recv(128) do
			string_responce << output
			break if string_responce.scan("(qemu) ").count == 2
		end
		string_responce
	end

	def format_responce(string)
		new_string = (string.split("(qemu) "))[1]
		responce = Array.new
		c = 0
		new_string.each_line{|line|
			c += 1
			responce.push(line.chomp.strip) if c > 1
		}
		responce
	end

	def read_vm_dir # read subdirectories from virtual machines root directory
		vm_array = Dir.entries($params['vm_dir'])
		vm_array.delete('.')
		vm_array.delete('..')
		vm_array
	end

	def get_process_status(vm) # find pid file, pid and detect status of VM
		pid_file = "#{$params['vm_dir']}/#{vm}/#{$params['pid_file']}"
		status = 'stopped'
		if File.exist?(pid_file) 
			pid = IO.read(pid_file).chomp.to_i
			pid_stat_file = "/proc/#{pid}/statm"
			if Dir.exist?('/proc')
				if File.exist?(pid_stat_file)
					if IO.read(pid_stat_file).split(' ')[2] != 'Z'
						if $kvm_vm_list
							status = (console(vm, 'info status')[0].split(': '))[1]
						else
							status = 'running (maybe paused)'
						end
					end
				else
					File.delete(pid_file)
					pid_file = nil
					pid = nil
				end
			else
				raise "proc directory not found. Is it Linux?"
			end
		else
			pid_file = nil
			pid = nil
		end
		return status, pid_file, pid
	end

	def get_socket_file(vm) # detect socket file
		socket_file = "#{$params['vm_dir']}/#{vm}/#{$params['socket_file']}"
        File.socket?(socket_file) ? socket_file : nil
	end

	def read_start_script(file) # read script that start virtual machine from virtual machine folder
		start_cmd = nil
		IO.read(file).each_line{|line|
			if line.index('#') != 0
				start_cmd = line.delete('&')
				start_cmd = start_cmd.split(' ')
				break
			end
		}
		start_cmd ? start_cmd : raise("VM starting string not found")
	end

end
