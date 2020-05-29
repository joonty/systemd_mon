All credits go to joonty (https://github.com/joonty/systemd_mon) who is the author behind this tool.
To offer a complete experience, I have also incorporated the improvements made by:
- Asquera (https://github.com/Asquera/systemd_mon) => stdout, gelf and http notifier
- florczakraf (https://github.com/florczakraf/systemd_mon) => fields 'cc' and 'bcc' for emails
- kennep (https://github.com/kennep/systemd_mon) => addition of the parameters 'hostname' and first version Dockerfile
- Maistho (https://github.com/Maistho/systemd_mon) => corrections of various problems such as not starting during a missing systemd unit or resending the initial state at startup
- milk531 (https://github.com/milk531/systemd_mon) => dingbot notify
- p91 (https://github.com/p91/systemd_mon) => Desktop notification via DBus

# SystemdMon

Monitor systemd units and trigger alerts for failed states. The command line tool runs as a daemon, using dbus to get notifications of changes to systemd services. If a service enters a failed state, or returns from a failed state to an active state, notifications will be triggered.

Built-in notifications include email, slack, and hipchat, but more can be added via the ruby API.

It works by subscribing to DBus notifications from Systemd. This means that there is no polling, and no busy-loops. SystemdMon will sit in the background, happily waiting and using minimal processes.

## Requirements

* A linux server
* Ruby > 1.9.3 (2.7 for Dockerfile)
* Systemd (v204 was used in development)
* `mail` gem (if email notifier is used)
* `slack-notifier` gem > 1.0 (if slack notifier is used)
* `hipchat` (if hipchat notifier is used)
* `dingbot` gem (if ding notifier is used)

## Installation

Install the gem using:

    gem install systemd_mon

## Usage

To run the command line tool, you will first need to create a YAML configuration file to specify which systemd units you want to monitor, and which notifications you want to trigger. A full example looks like this:

```yaml
---
verbose: true # Default is off
notifiers:
  email:
    to: "team@mydomain.com"
    from: "systemdmon@mydomain.com"
    # cc and bcc are optional
    cc: "cc@mydomain.com"
    bcc: "bcc@mydomain.com"
    # These are options passed to the 'mail' gem
    smtp:
        address: smtp.gmail.com
        port: 587
        domain: mydomain.com
        user_name: "user@mydomain.com"
        password: "supersecr3t"
        authentication: "plain"
        enable_starttls_auto: true
  slack:
    webhook_url: https://hooks.slack.com/services/super/secret/tokenthings
    channel: mychannel
    username: doge
    icon_emoji: ":computer"
    icon_url: "http://example.com/icon"
  hipchat:
    token: bigsecrettokenhere
    room: myroom
    username: doge
  desktop:
   start_stop_message: false
   timeout: 2000
  ding:
    endpoint: https://oapi.dingtalk.com/robot/send
    access_token: xxxxxxxxxxxx
  stdout: {}
  gelf:
    host: 127.0.0.1
    port: 12201
    level: INFO
    network: LAN
  http:
    bind_address: 0.0.0.0
    bind_port: 9000
units:
- unicorn.service
- nginx.service
- sidekiq.service
```

Save that somewhere appropriate (e.g. `/etc/systemd_mon.yml`), then start the command line tool with:

    $ systemd_mon /etc/systemd_mon.yml

You'll probably want to run it via systemd, which you can do with this example service file (change file paths as appropriate):

```
[Unit]
Description=SystemdMon
After=network.target

[Service]
Type=simple
User=deploy
StandardInput=null
StandardOutput=syslog
StandardError=syslog
ExecStart=/usr/local/bin/systemd_mon /etc/systemd_mon.yml

[Install]
WantedBy=multi-user.target
```

## Behaviour

Systemd provides information about state changes in very fine detail. For example, if you start a service, it may go through the following states: activating (start-pre), activiating (start) and finally active (running). This will likely happen in less than a second, and you probably don't want 3 notifications. Therefore, SystemdMon queues up states until it comes across one that you think you should know about. In this case, it will notify you when the state reaches active (running), but the notification can show the history of how the state changed so you get the full picture.

SystemdMon does simple analysis on the history of state changes, so it can summarise with statuses like "recovered", "automatically restarted", "still failed", etc. It will also report with the host name of the server.

You'll also want to know if SystemdMon itself falls over, and when it starts back up again. It will attempt to send a final notification before it exits, and one to say it's starting. However, be aware that it might not send a notification in some conditions (e.g. in the case of a SIGKILL), or a network failure. The age-old question: who will watch the watcher?

## Docker integration
There is a public Docker image available which bundles all requirements (Ruby + Gems). Since systemd_mon relies on dbus, you need to mount the host dbus directory into your container. Besides that, the configuration filename is currently hardcoded to systemd_mon.yml. You have to mount the directory where the systemd_mon.yml file is located on your host system into your container as well. Below is a working example: 

```
docker run --name "systemd_mon" -v /var/run/dbus:/var/run/dbus -v /path/to/systemd_mon/config/:/systemd_mon/ kromit/systemd_mon
```

If you want to run this image with systemd (very handy on CoreOS for example) you can use it as follows:

```
[Unit]
Description=systemd_mon
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=60
ExecStartPre=-/usr/bin/docker kill systemd_mon
ExecStartPre=-/usr/bin/docker rm systemd_mon
ExecStart=/usr/bin/docker run --name "systemd_mon" -v /var/run/dbus:/var/run/dbus -v /path/to/systemd_mon/config/:/systemd_mon/ kromit/systemd_mon

[Install]
WantedBy=multi-user.target
```

## Contributing

I'd love more contributions, particulary new notifiers. Follow the example of the slack and email notifiers and either package as a new gem or submit a pull request if you think it should be part of the main project.

1. Fork it ( https://github.com/joonty/systemd_mon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
