require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'
require 'webrick'
require 'json'

module SystemdMon::Notifiers
  class Http < Base
    def initialize(*)
      super
      bind_host = options["bind_host"] || "127.0.0.1"
      bind_port = options["bind_port"] || 9000
      history_size = options["history"] || 5

      # keep the `history_size` last states around for each unit
      self.state_cache = Hash.new {|h, unit| h[unit] = SizedLifoBuffer.new(history_size) }

      self.server = WEBrick::HTTPServer.new :BindAdress => bind_host, :Port => bind_port, :DoNotReverseLookup => true
      server.mount_proc "/units" do |req, res|
        # path info is "" or "/" for requests on /units and /units/ respectively
        # but always contains the leading slash for /units/test.service
        #
        
        if req.path_info.length > 1
          unit_name = req.path_info[1..-1] # strip the leading slash
          if state_cache.has_key? unit_name
            if state_cache[unit_name].first[:ok]
              res.status = 200
            else
              res.status = 500
            end
            if req["Content-Type"] && req["Content-Type"].include?("application/json")
              res.body = JSON.dump state_cache[unit_name]
            else
              res['Content-Type'] = 'text/html'
              @detail   = true
              @hostname = hostname
              @state    = state_cache[unit_name]
              @unit     = unit_name
              res.body = template.result(binding)
            end
          else
            res.status = 404
            if req["Content-Type"] && req["Content-Type"].include?("application/json")
              res.body = '{"error": "unknown unit"}'
            end
          end
        else
          if req["Content-Type"] && req["Content-Type"].include?("application/json")
            res.body = JSON.dump state_cache
          else
            res['Content-Type'] = 'text/html'
            @detail   = false
            @hostname = hostname
            @states   = state_cache
            res.body = template.result(binding)
          end
        end
      end

      self.server_thread = Thread.new do
        at_exit { server.shutdown }
        server.start
      end
    end

    def notify_start!(hostname)
      self.hostname = hostname
    end

    def notify!(notification)
      push_change(notification)
    end

    def initial_state!(notification)
      push_change(notification)
    end

    protected
      attr_accessor :server, :server_thread, :options, :state_cache, :hostname

      def push_change(notification)
        unit   = notification.unit
        change = unit.state_change.last
        state_cache[unit.name].push({
          active:  change.active.value,
          loaded:  change.loaded.value,
          status:  change.sub.value,
          enabled: change.unit_file.value,
          ok:      change.ok?,
          time:    Time.now
        })
        STDOUT.puts state_cache

      end

      def template
        ERB.new(<<__EOTEMPLATE__)
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bootstrap 101 Template</title>

    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
    
    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css" integrity="sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r" crossorigin="anonymous">
    
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
    
    <!-- Bootstrap -->

    <style>
      body {
        padding-top: 50px;
      }

      .starter-template {
        padding: 40px 15px;
        text-align: center;
      }

    </style>

  </head>
  <body>

    <nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#">Project name</a>
        </div>
        <div id="navbar" class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
            <li class="active"><a href="#">Home</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#contact">Contact</a></li>
          </ul>
        </div><!--/.nav-collapse -->
      </div>
    </nav>

    <div class="container">
<% if @detail %>
      <div class="starter-template">
        <h1>Service status for <%= @unit %> on <%= @hostname %></h1>

        Current state: <%= @state.first[:ok] ? "ok" : "failed" %>

        Full service history:

        <table class="table table-striped table-hover">
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Active</th>
              <th>Status</th>
              <th>Loaded</th>
              <th>Enabled</th>
            </tr>
          </thead>
          <tbody>
  <% @state.each do |s| %>
            <tr>
              <td><%= s[:time].to_s %></td>
              <td><%= s[:active] %></td>
              <td><%= s[:status] %></td>
              <td><%= s[:loaded] %></td>
              <td><%= s[:enabled] %></td>
            </tr>
  <% end %>
          </tbody>
        </table>
      </div>
<% else %>
      <div class="starter-template">
        <h1>Service status monitored on <%= @hostname %></h1>

        Current state: <%= @states.all?{|unit, s| s.first[:ok]} ? "ok" : "failed" %>

        All services:

        <table class="table table-striped table-hover">
          <thead>
            <tr>
              <th>Unit</th?
              <th>Timestamp</th>
              <th>Active</th>
              <th>Status</th>
              <th>Loaded</th>
              <th>Enabled</th>
            </tr>
          </thead>
          <tbody>
  <% 
      @states.each do |unit, states| 
        s = states.first
  %>
            <tr>
              <td><a href="/units/<%= unit %>"><%= unit %></td> 
              <td><%= s[:time].to_s %></td>
              <td><%= s[:active] %></td>
              <td><%= s[:status] %></td>
              <td><%= s[:loaded] %></td>
              <td><%= s[:enabled] %></td>
            </tr>
  <% end %>
          </tbody>
        </table>
      </div>

<% end %>
    </div><!-- /.container -->

  </body>
</html>
__EOTEMPLATE__
     end


    # a very simple bounded lifo implementation. It's fairly inefficient
    # since it moves the whole array content around when the size limit is
    # reached, but it'll do here.
    #
    # the semantics are as follows: we want the size to be bounded and keep
    # the last `size` elements. If the buffer is full and an element gets 
    # pushed on it, the oldest element in insertion order is discarded. 
    #
    # Iteration with .each starts with the newest element to the oldest.
    class SizedLifoBuffer < Array
      def initialize(size)
        @size = size
        super()
      end

      def push(el)
        if size == @size
          pop
        end
        unshift el
      end
    end
  end
end
