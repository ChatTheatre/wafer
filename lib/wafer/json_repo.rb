require 'json'
require 'digest'
require 'digest/md5'

class JSONRepo
    EMPTY_REPO = {
        "users" => [
            {
                "id" => 1,
                "name" => "admin",
                "email" => "admin@example.com",
                "creation_time" => Time.now,
                "password" => "ABCDEFG",
                "pay_day" => 0,
                "next_month" => 0,
                "next_year" => 0,
                "next_stamp" => 0,
                "account_credit" => 0.0,
                "account_type" => "staff",  # regular, trial, free, developer, staff

                "flags" => ["terms-of-service"],  # no-email, premium, deleted, terms-of-service, banned

                "access" => [ "gables" ],  # What game names the user has access to

                "keycode" => {
                    "keycode" => "17",
                    "keycode_stamp" => Time.now,
                },
            },
            {
                "id" => 1,
                "name" => "bobo",
                "email" => "bobo@example.com",
                "creation_time" => Time.now,
                "password" => "ABCDEFG",
                "pay_day" => 0,
                "next_month" => 0,
                "next_year" => 0,
                "next_stamp" => 0,
                "account_credit" => 0.0,
                "account_type" => "staff",  # regular, trial, free, developer, staff

                "flags" => ["terms-of-service"],  # no-email, premium, deleted, terms-of-service, banned

                "access" => [ "gables" ],  # What game names the user has access to

                "keycode" => {
                    "keycode" => "17",
                    "keycode_stamp" => Time.now,
                },
            },
        ],
    }

    def initialize(json_filename)
        unless File.exist?(json_filename)
            File.open(json_filename, "w") { |f| f.print(JSON.pretty_generate EMPTY_REPO) }
        end
        @contents = JSON.load(File.read json_filename)
    end

    def uid_by_name(name)
        user = user_by_name(name)
        user && user["id"]
    end

    def user_by_name(name)
        user_by_field("name", name)
    end

    def user_by_id(id)
        user_by_field("id", id)
    end

    def user_by_field(field, value)
        @contents["users"].detect { |u| u[field] == value }
    end

    def user_has_access?(uid, game)
        user = user_by_id(uid)
        user && user["access"].include?(game)
    end

    def user_has_tos?(uid)
        user = user_by_id(uid)
        user && user["flags"].include?("terms-of-service")
    end

    # We don't do email pings
    def user_has_verified_email?(uid)
        user = user_by_id(uid)
        !!user
    end

    def user_set_email(uid, email)
        user = user_by_id(uid)
        user && user["email"] = email
    end

    def user_account_type(uid)
        user = user_by_id(uid)
        user ? user["account_type"] : nil
    end

    # Note: we ignore "freebie" users. We don't have that.
    def user_account_status(uid)
        user = user_by_id(uid)
        return nil unless user

        (user["flags"] + user["access"]).join(" ")
    end

    def user_set_flag(uid, flag)
        user = user_by_id(uid)
        user && user["flags"] |= [flag]
    end

    def user_unset_flag(uid, flag)
        user = user_by_id(uid)
        user && user["flags"] -= [flag]
    end

    private

    def new_random_keycode
        random(1 << 27)
    end

    public

    def user_keycode(uid)
        user = user_by_id(uid)
        user && new_random_keycode
    end

    def user_set_keycode(uid)
        user = user_by_id(uid)
        raise "No such user!" unless user
        user["keycode"] = { "keycode" => new_random_keycode, "stamp" => Time.now }
    end

    # Miraculously, every user's next stamp is awhile in the future.
    def user_next_stamp(uid)
        Time.now.to_i + 3600 * 24 * 20
    end

    def user_is_paid?(uid)
        user = user_by_id(uid)
        user && true
    end

    def is_user_ok(uid)
        user = user_by_id(uid)

        if !user
            return [false, "NO SUCH USER"]
        elsif user["flags"].include?("deleted")
            return [false, "NO SUCH USER"]
        elsif user["flags"].include?("banned")
            return [false, "ACCOUNT BLOCKED"]
        end

        return [true, ""]
    end

    def is_keycode_ok(uid, code)
        return [false, "BAD KEYCODE"] unless code
        return [false, "BAD KEYCODE"] unless code == "17" || code == "LOCAL"

        # Keycode handling here is insultingly trivial and entirely insecure.

        return [true, ""]
    end

    # In thin-auth, this uses PHP's built-in password hashing.
    def is_password_ok(uid, pass)
        user = user_by_id(uid)

        return [false, "NO SUCH USER"] unless user

        if user["password"] == pass
            [true, ""]
        else
            [false, "BAD PASSWORD"]
        end
    end

    def is_hash_ok(uid, hash)
        user = user_by_id(uid)
        return [false, "NO SUCH USER"] unless user

        STDERR.puts "Checking md5 hash: #{hash.inspect}"

        keycode = user["keycode"]["keycode"]
        real_hash = Digest::MD5.hexdigest(user["name"] + keycode + "NONE")

        STDERR.puts "  Real hash: #{real_hash.inspect}"

        # Skip the check and just always say it's fine.
        #if real_hash == hash
            return [true, ""]
        #else
        #    return [false, "BAD HASH"]
        #end
    end

end
