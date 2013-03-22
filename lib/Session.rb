class Session # class to work with sessions
	def initialize(session)
		@current_lvl = 'ROOT'
		@previous_lvl = nil
		@session = session
		begin
			puts "\t[#{Thread.current}] - session opened"
			@session.puts("-= spkvmd welcome you =-")
			loop do
				puts_to_c(nil)
				cmd, arg = read_s
				if cmd == 'quit'
					break
				elsif cmd == 'kvm'
					operate_kvm
				elsif cmd == 'ks'
					exit
				else
					puts_to_c('Unknown command')
				end
			end
		rescue
			puts "session initialize error: #{$!}"
		end
	end

private

	def read_s # format input from session
		@session.gets.chomp.split(' ', 3)
	end

	def operate_kvm # KVM operations
		chlvl!('KVM_OPERATOR')
		puts "\t\t[#{Thread.current}] - enter #{@current_lvl}"
		puts_to_c(nil)
		begin
			kvm = KVM.new
			loop do
				cmd, vm, arg = read_s
				if cmd == 'back'
					return_to_lvl!
					puts "\t\t[#{Thread.current}] - exit #{@previous_lvl}"
					break
				elsif cmd == 'list'
					vm_list = $kvm_vm_list
					puts "\t\t\t[#{Thread.current}] - #{vm_list.length} vms listed to client."
					puts_to_c(vm_list)
				elsif cmd == 'flist'
					Watcher.refresh!
					vm_list = $kvm_vm_list
					puts "\t\t\t[#{Thread.current}] - List updated. #{vm_list.length} vms listed to client."
					puts_to_c(vm_list)
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
						puts_to_c("#{vm} - #{responce}")
					rescue
						error = $!
						puts "\t\t\t[#{Thread.current}] - Can't connect to VM=#{vm} console: #{error}."
						puts $!.backtrace
						puts_to_c("#{vm} - failed to connect to console: #{error}")
					end
				else
					puts_to_c('Unknown command')
				end
			end
		rescue
			puts "KVM_OPERATOR error: #{$!}"
			puts $!.backtrace
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
			puts_to_c("#{vm} - #{o_name}ed")
			Watcher.refresh!
		rescue
			error = $!
			puts "\t\t\t[#{Thread.current}] - Can't #{o_name} VM=#{vm}: #{error}."
			puts_to_c("#{vm} - failed to #{o_name}: #{error}")
		end
	end

	def puts_to_c(string) # formated output to session
		@session.puts("[#{@current_lvl}]: #{string}")
	end

	def chlvl!(new_lvl) # changing current menu level
		@previous_lvl = @current_lvl
        @current_lvl = new_lvl
	end

	def return_to_lvl! # returning to previos menu level
		a = @current_lvl
		@current_lvl = @previous_lvl
		@previous_lvl = a
	end

end
