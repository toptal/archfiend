# Archfiend

Archfiend (/ˈɑrtʃˈfind/) - a basic daemon generator. It features boilerplate for common development tools (ActiveRecord, RSpec, FactoryBot, RuboCop),
handles daemonizing, configuration, logging and more. It provides a way to structure backend applications in an organized manner.

[![Build Status](https://travis-ci.com/toptal/archfiend.svg?branch=master)](https://travis-ci.com/toptal/archfiend)
[![Gem Version](https://badge.fury.io/rb/archfiend.svg)](https://badge.fury.io/rb/archfiend)

## Contents
* [Getting started](#getting-started)
* [Primitives](#primitives)
* [Featured gems](#featured-gems)
* [Changelog](#changelog)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Getting started

Archfiend provides the `archfiend` executable, which features a daemon generator.

```bash
  $ bundle exec archfiend new my_new_daemon # Creates the new daemon
  $ cd my_new_daemon
  $ cp config/database.yml{.example,}       # Currently, it ships with ActiveRecord, database configuration is required
  $ bin/start                               # Start without daemonization
  2018-10-09T13:59:55.874Z 88087 TID-ovtqe0m53 INFO: Starting up
  2018-10-09T13:59:56.301Z 88087 TID-ovtqu0g3f INFO: Starting thread BarThreadLoop
  2018-10-09T13:59:56.303Z 88431 TID-ovtqe0m53 INFO: Starting subprocess FooSubprocessLoop
```

## Primitives

Daemons generated with Archfiend are structured around `ThreadLoops` and `SubprocessLoops`.
They provide entry points for any user code. There is no limit on the number of each, you should
use your judgement on how many your target environment can realistically handle.

### ThreadLoops

When started, Archfiend instantiates each [ThreadLoop](lib/archfiend/thread_loop.rb) subclass in a separate thread and calls its `#run` method.
By default, `#run` wraps looped execution of `#iterate` with `StandardError` handling.
You are supposed to either provide the `#iterate` method or shadow the `#run` method to fully take over
the control of the thread.
Bear in mind that any unhandled exception will terminate the whole process. If your code deals with
exceptions that are not subclasses of `StandardError`, make sure you handle it on your own.

With MRI, parallel threads execution happens only when one of threads waits for IO. This should be
fairly often in network communicating daemons.

### SubprocessLoops

When started, archfiend instantiates each [SubprocessLoop](lib/archfiend/subprocess_loop.rb) subclass in a separate fork and calls its `#run` method.
By default, `#run` wraps looped execution of `#iterate` with `StandardError` handling.
You are supposed to either provide the `#iterate` method or shadow the `#run` method to fully take over
the control of the process.
Subprocesses are killed when the main daemon process exits. If a subprocess gets terminated, it does not kill the main
process. The main process doesn't restart its subprocesses by default.

## Featured gems

### ActiveRecord

ActiveRecord is available and configured using the `config/database.yml`, you can create regular AR model files
inside `app/models`.
When creating multi-threaded daemons, make sure connection pool is handled correctly (that connections are
released to the pool after a thread finishes) and that the pool has enough open connections (default is 5).

Migrations are provided by the [ActiveRecord::Migrations](https://github.com/ioquatix/activerecord-migrations) gem, you can use following rake tasks
```bash
rake db:migrate                       # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
rake db:rollback                      # Rolls the schema back to the previous version (specify steps w/ STEP=n)
rake db:migrations:new[name,options]  # Creates a new migration file with the specified name
```

Please see `bundle exec rake -T` for more options.

### Clockwork

Archfiend provides the [Clockwork](https://github.com/Rykian/clockwork) integration, so daemons can schedule recurring tasks.
Uncomment the contents of the `clockwork/clockwork.rb` file to enable it. If the daemon doesn't use clockwork, feel free
to remove the file, the directory and the Gemfile entry.

### Settings

The [config](https://github.com/railsconfig/config) gem is used to handle multi-environment settings.

### rbtrace

For debugging, daemons generated with Archfiend include [rbtrace](http://github.com/tmm1/rbtrace).
By default, it is enabled in the development environment.

### RSpec / RuboCop

Newly generated daemons come with integrations for RSpec and RuboCop.

## Changelog

See [CHANGES.md](CHANGES.md) for the list of changes.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the uncommitted list of ideas for future.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/toptal/archfiend.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Archfiend project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/toptal/archfiend/blob/master/CODE_OF_CONDUCT.md).