# Wafer

If you want a simple, production-quality, fairly thin auth system for your [ChatTheatre/SkotOS game](https://github.com/ChatTheatre/SkotOS), you want [thin-auth](https://github.com/ChatTheatre/thin-auth). Thin-auth is a perfectly reasonable PHP server app. It likes being installed at a server-like path. It needs Apache and MariaDB configured in specific ways. But it does a reasonable job of a lot of things, using a fairly small amount of code. Billing? Check. Verifying for your app that billing happened? Check. Web interface for changing settings? Check. Reasonable security? Check.

**This is not that application.**

Wafer-thin-auth is an ultra-thin dev-mode-only server, designed to impersonate SkotOS's authentication system with a minimum of ceremony in a non-production-quality way.

For now you can run it in dev and it will cheerfully believe that all your users are paid up, and always right about their passwords. It is an eternal and negligent optimist. You should never, never use it production &mdash; even once we fix that problem. There are large swaths of important functionality that it doesn't even begin to attempt. Thin-auth has good password checking, backup scripts, support for staff to manage accounts and many other things that would be worse than useless for wafer-thin-auth. Want something reasonable for production? No problem - use thin-auth.

Also, its code is far smaller and its dependencies far fewer than anything that would actually work for a real production app. 'Good' negligent optimism can be had for cheap!

But wafer-thin-auth will replace thin-auth, including its web and server components, and even the userdb-authctl shim to make an outgoing connection to the DGD server. The hope is that you can run a much less elaborate setup in development, while we get rid of an un-securable development mode of the SkotOS server.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wafer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wafer

## Usage

By default Wafer will run its AuthD and CtlD on ports 2070 and 2071, equivalent to a SkotOS portbase of 2000. You can set up your SkotOS server's UserDB file for that easily:

~~~
# root/usr/System/data/userdb
userdb-hostname 127.0.0.1
userdb-portbase 2000
~~~

If you'd like to change Wafer's settings - what ports it opens, and where it looks for your SkotOS server (see UserDB-Authctl below,) you can pass a settings file on the command line:

~~~
wafer -s my_settings.json
~~~

You can also create a new settings file with defaults:

~~~
wafer --default-settings > new_settings_file.json
~~~

### UserDB-Authctl

For weird historical reasons, neither DGD nor its AuthD/CtlD want to make an outgoing network connection. Userdb-authctl is a shim between them to fix that. Wafer handles it by making outgoing network connections.

If you're not already running the userdb-authctl shim server, you'll probably want Wafer to do that for you -- or you can run userdb-authctl, but then it's one more piece to keep up and running.

In production you'll need to run userdb-authctl -- SkotOS StackScripts set this up by default. That's because you should never, never run Wafer in production. It's ***only*** for development.

## Development

Want to do development on Wafer? It can certainly use the help!

Your go-to incantation for running the command line program:

~~~
ruby -Ilib ./exe/wafer
~~~

This runs Wafer while telling it where to find the latest local code (which you're modifying, right?) and letting you add flags to Ruby (e.g. -w for warnings.)

### Normal Setup

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wafer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/wafer/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the GNU Affero General Public License (AGPL.)

## Code of Conduct

Everyone interacting in the Wafer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wafer/blob/master/CODE_OF_CONDUCT.md).
