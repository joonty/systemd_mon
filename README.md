# SystemdMon

Monitor systemd units and trigger alerts for failed states. The command line tool runs as a daemon, using dbus to get notifications of changes to systemd services. If a service enters a failed state, or returns from a failed state to an active state, notifications will be triggered.

Built-in notifications include email and slack, but more can be added via the ruby API.

## Installation

Install the gem using:

    gem install systemd_mon

## Usage

To run the command line tool, you will first need to create a YAML configuration file to specify which systemd units you want to monitor, and which notifications you want to trigger. A full example looks like this:

```yaml
---
notifiers:
  # These are options passed to the 'mail' gem
  email:
    address: smtp.gmail.com
    port: 587
    domain: mydomain.com
    user_name: "user@mydomain.com"
    password: "supersecr3t"
    authentication: "plain"
    enable_starttls_auto: true
  slack:
    team: myteam
    token: supersecr3ttoken
    channel: mychannel
    username: doge
units:
- unicorn.service
- nginx.service
- sidekiq.service
```

Then start the command line tool with:

    $ systemd_mon path/to/systemd_mon.yml

## Contributing

1. Fork it ( https://github.com/joonty/systemd_mon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
