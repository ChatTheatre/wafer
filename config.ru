
require_relative "lib/wafer.rb"
require "erubis"
require "json"

repo = JSONRepo.new ENV["WAFER_USER_REPO_FILE"]

settings = {}
if ENV["WAFER_SETTINGS_FILE"] && !ENV["WAFER_SETTINGS_FILE"].empty?
  settings = JSON.load File.read(ENV["WAFER_SETTINGS_FILE"])
end
wafer = Wafer::Server.new(repo: repo, settings: settings)

# This runs the CtlD and AuthD servers in a background thread.
# If the settings say so then it also connects to the DGD incoming port to
# replace userdb-authctl.
BACKGROUND_THREAD = Thread.new do
  begin
    puts "Entered the thread..."
    wafer.event_loop
  rescue Exception
    puts "Got exception in thread! Dying! #{$!.message}"
    puts $!.backtrace.join("\n")
    exit -1 # This should shut down the web server, too.
  end
end

RET_VARS = {}

run (proc do |env|
  path = env['PATH_INFO']
  path = "/index.html" if path == "" || path == "/"

  template_path = File.join(__dir__, "www", path) + ".erb"
  if File.exist?(template_path)
    erb_text = File.read(template_path)
    eruby = Erubis::Eruby.new(erb_text)
    RET_VARS.clear
    html_text = eruby.result env: env, vars: RET_VARS,
      users: repo.user_names - ["default"],
      play_port: wafer.settings["dgd"]["portbase"] + 80

    # Should be possible to set the user and password cookies from Erb.
    resp = Rack::Response.new html_text, 200, { 'Content' => 'text/html' }
    if RET_VARS["user"]
        resp.set_cookie "user", { value: RET_VARS["user"], path: "/", expires: Time.now+30*24*60*60 }
        # "pass" is used for the keycode, not an actual password
        resp.set_cookie "pass", { value: "17", path: "/", expires: Time.now+30*24*60*60 }
    end
    resp.finish
  else
    [404, {}, [ "File not found: #{template_path}" ]]
  end

end)
