# frozen_string_literal: true

module Nonnative
  class SocketPair
    def initialize(port)
      @port = port
    end

    def connect(local_socket)
      remote_socket = create_remote_socket
      return unless remote_socket

      loop do
        ready = select([local_socket, remote_socket], nil, nil)

        break if write(ready, local_socket, remote_socket)
        break if write(ready, remote_socket, local_socket)
      end
    rescue Errno::ECONNRESET
      # Just ignore it.
    ensure
      local_socket.close
      remote_socket&.close
    end

    private

    attr_reader :port

    def create_remote_socket
      ::TCPSocket.new('0.0.0.0', port)
    end

    def write(ready, socket1, socket2)
      if ready[0].include?(socket1)
        data = socket1.recv(1024)
        return true if data.empty?

        socket2.write(data)
      end

      false
    end
  end
end
