class Wafer::Server
    def ctl_respond(conn, parts)
        return send_error(conn, "BAD INPUT") if parts.size < 3 || parts.size > 9

        @seq_numbers[conn] = parts[1]
        command = parts[0]

        if command == "announce"
            return send_ok(conn, "OK")
        end

        return send_error(conn, "UNIMPLEMENTED")
    end
end
