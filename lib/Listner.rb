class Listner # class to operate with TCP Server
	def initialize
		begin
			puts "Starting SPKVMD Listner..."
			require 'socket'
			@server = TCPServer.new($params['tcp_addr'],$params['tcp_port'])
		rescue
			raise "Can't create new TCPServer: #{$!}"
		end
	end

	def accept_sessions! # start new thread for each connection
		loop do
			Thread.abort_on_exception=true
			Thread.start(@server.accept) do |session|
				require 'Session'
				Session.new(session)
				session.close
				puts "\t[#{Thread.current}] - session closed"
			end
		end
	end
end
