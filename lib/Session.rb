class Session # class to work with sessions
	def initialize(session, interactive)
		require 'json'
		@session = session
		@interactive = interactive
		begin
			if !@interactive
				scope, cmd, params = read_s
				# puts "#{scope} then #{cmd} with params = #{params}"
				if scope == 'kvm'
					if params
						vm, arg = params.split(' ', 2)
					else
						vm, arg = nil
					end
					operate_kvm(cmd, vm, arg)
				end
			else
				raise "sorry, interactive sessions not ready yet"
			end
		rescue
			puts "session initialize error: #{$!}"
			puts $!.backtrace
		end
	end

private

	def read_s # format input from session
		info = @session.gets
		if info && !info.empty?
			info.chomp.split(' ', 3)
		else
			puts_to_c([1, 'empty command'])
		end
	end
	
	def puts_to_c(array) # formated output to session
		code = array[0]
		# 0 - success code
		# 1 - fail code
		# 2 - unknown code
		comment = array[1] # all information returned by operation or error text
		@session.puts("#{code}|#{comment}")
	end

	def operate_kvm(cmd, vm, arg)
		require 'KVM'
		kvm = KVM.new
		if cmd == 'list'
			vm_list = $kvm_vm_list
			puts "\t\t\t[#{Thread.current}] - #{vm_list.length} vms listed to client."
			puts_to_c([0, vm_list.to_json])
		elsif cmd == 'flist'
			Watcher.refresh!
			vm_list = $kvm_vm_list
			puts "\t\t\t[#{Thread.current}] - List updated. #{vm_list.length} vms listed to client."
			puts_to_c([0, vm_list.to_json])
		elsif cmd == 'start'
			operation(vm, cmd){|i| kvm.start(i) }
		elsif cmd == 'stop'
			operation(vm, cmd){|i| kvm.stop(i) }
		elsif cmd == 'pause'
			operation(vm, cmd){|i| kvm.pause(i) }
		elsif cmd == 'resume'
			operation(vm, cmd){|i| kvm.resume(i) }
		elsif cmd == 'console'
			begin
				puts "\t\t\t[#{Thread.current}] - \"#{arg}\" command sended to VM=#{vm} console."
				responce = kvm.console(vm, arg)
				puts "\t\t\t[#{Thread.current}] - VM=#{vm} return \"#{responce}\" to \"#{arg}\" command."
				puts_to_c([0, responce])
			rescue
				error = $!
				puts "\t\t\t[#{Thread.current}] - Can't connect to VM=#{vm} console: #{error}."
				#puts error.backtrace
				puts_to_c([1, "failed to connect to console: #{error}"])
			end
		elsif cmd == 'showconfig'
			begin
				config = kvm.show_config(vm)
				puts "\t\t\t[#{Thread.current}] - \"#{vm}\" configuration showed to client."
				puts_to_c([0, config.to_json])
			rescue
				error = $!
				puts "\t\t\t[#{Thread.current}] - failed to show \"#{vm}\" configuration: #{error}."
				puts_to_c([1, error])
			end
		else
			puts_to_c([2, 'Unknown command'])
		end
	end

	def operation(vm, o_name) # do 'yield' operation with 'vm' and talk about it as about 'o_name'
		begin
			yield(vm)
			if (i = o_name.rindex('e'))
				o_name.slice!(i) if i == o_name.length - 1
			elsif (i = o_name.rindex('p'))
				o_name = o_name + 'p' if i == o_name.length - 1
			end
			puts "\t\t\t[#{Thread.current}] - VM=#{vm} #{o_name}ed."
			puts_to_c([0, "#{o_name}ed"])
			Watcher.refresh!
		rescue
			error = $!
			puts "\t\t\t[#{Thread.current}] - Can't #{o_name} VM=#{vm}: #{error}."
			puts_to_c([1, "failed to #{o_name}: #{error}"])
		end
	end
end
