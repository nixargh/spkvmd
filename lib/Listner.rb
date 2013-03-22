class Listner # class to operate with TCP Server
	def initialize(l_name, port)
		begin
			require 'socket'
			puts "Starting SPKVMD #{l_name} Listner..."
			@server = TCPServer.new($params['tcp_addr'], port)
		rescue
			raise "Can't create new TCPServer: #{$!}"
		end
	end

	def accept_web_sessions!
		accept_sessions!('web')
	end

	def accept_interactive_sessions!
		accept_sessions!('interactive')
	end
	
private

	def accept_sessions!(type) # start new thread for each connection
		loop do
			require 'Session'
			Thread.abort_on_exception=true
			Thread.start(@server.accept) do |session|
				if	type == 'web'
					Session.new(session, false)
				elsif type == 'interactive'
					Session.new(session, true)
				end
				session.close
				puts "\t[#{Thread.current}] - session closed"
			end
		end
	end
end
