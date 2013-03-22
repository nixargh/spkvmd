class Watcher # class to operate with Virtual Machines list
	def self.start!
		begin
			puts "Starting SPKVMD Watcher..."
			require 'KVM'
			@kvm = KVM.new if !@kvm
			loop do
				self.refresh!
				#puts "\t#{Time.now} - [KVM_VM_UPDATER] KVM VM list updated."
				sleep $params['refresh_time'].to_i
			end
		rescue
			raise "Can't create new Watcher: #{$!}"
		end
	end

	def self.refresh!
		@kvm = KVM.new if !@kvm
		$kvm_vm_list = @kvm.get_vm_list 
	end
end
