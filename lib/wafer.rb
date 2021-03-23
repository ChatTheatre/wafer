#require "wafer/version"

require 'socket'
require 'cgi'

module Wafer
  class Error < StandardError; end

  DEFAULT_SETTINGS = {
      "http" => {
        "port" => 2072,
      }.freeze,
      "authServer" => {
        "selectTimeout" => 5.0,
      }.freeze,
      "dgd" => {
        "portbase" => 10_000,
        "serverIP" => "127.0.0.1",
      }.freeze,
  }.freeze

  class Server
    attr_reader :repo
    attr_reader :settings

    def initialize(repo:, settings: {})
      @repo = repo

      # Make a copy of default settings to allow modification
      @settings = copy_of_default_settings
      @settings.merge! settings

      @read_sockets = []
      @err_sockets = []
      @socket_types = {}
      @seq_numbers = {}
    end

    def copy_of_default_settings
      Hash[DEFAULT_SETTINGS.map { |key, value| [key, value.dup] }]
    end

    def log(message)
      pre = "[#{Time.now}] "
      puts pre + message
    end

    def conn_connect(conn_type)
      port = @settings["dgd"]["portbase"] + (conn_type == :auth ? 70 : 71)
      sock = TCPSocket.open @settings["dgd"]["serverIP"], port
      @socket_types[sock] = conn_type
      @read_sockets.push sock
      @err_sockets.push sock

      return sock
    end

    def conn_reconnect(conn)
      @read_sockets -= [ conn ]
      @err_sockets -= [ conn ]
      socket_type = @socket_types[conn]
      @socket_types.delete(conn)
      @seq_numbers.delete(conn)
      begin
        log("Closing connection of type #{socket_type.inspect}...")
        conn.close
      rescue
        STDERR.puts $!.inspect
        log("Closing connection of type #{socket_type.inspect}... (But got an error, failing - this is common.)")
      end

      STDERR.puts "Reconnecting outgoing connection of type #{socket_type.inspect}..."
      conn_connect(socket_type)
    end

    def send_error(conn, message)
      seq = @seq_numbers[conn]
      log("Error on conn (#{seq}): #{message}")
      conn.write "#{seq} ERR #{message}\n"
    end

    def send_ok(conn, message)
      ok_message = "#{@seq_numbers[conn]} OK #{message}\n"
      STDERR.puts "Sending OK message: #{ok_message.inspect}"
      conn.write ok_message
    end

    def event_loop
      puts "Settings:"
      puts JSON.pretty_generate(@settings)

      conn_connect(:auth)
      conn_connect(:ctl)

      loop do
        sleep 0.1
        readable, _, errorable, = IO.select @read_sockets, [], @err_sockets, @settings["authServer"]["selectTimeout"]

        readable ||= []
        errorable ||= []

        puts "Selected... R: #{readable.size} / #{@read_sockets.size} E: #{errorable.size} / #{@err_sockets.size}"

        # Close connections on error
        errorable.each { |errant_conn| conn_reconnect(errant_conn) }

        (readable - errorable).each do |conn|
          STDERR.puts "Preparing for read..."
          data = conn.recv_nonblock(2048)
          if !data || data == ""
            STDERR.puts "No data - need to reconnect?"
            #conn_reconnect(conn)
            next
          end
          STDERR.puts "Successful read: #{data.inspect}"
          parts = data.chomp.strip.split(" ").map { |part| CGI::unescape(part) }
          next if parts == []  # No-op

          STDERR.puts "Successful parse: #{parts.inspect}"

          case @socket_types[conn]
          when :ctl
            ctl_respond(conn, parts)
          when :auth
            auth_respond(conn, parts)
          else
            log("Wrong socket type #{@socket_types[conn].inspect} for connection!")
            conn_disconnect(conn)
          end
        end
      end
    end
  end
end

require_relative "wafer/json_repo"
require_relative "wafer/auth_server"
require_relative "wafer/ctl_server"
