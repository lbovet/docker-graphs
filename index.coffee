stats = require 'docker-stats'
through = require 'through2'
log = require 'node-docker-log-monitor'
monitor = require 'node-docker-monitor'
turtle = (require 'turtle-race')
  keep: true
  seconds: true
  interval: 500
  maxGraphHeight: 6
  metrics:
    cpu:
      min: 0
      max: 100
      yAxis:
        decimals: 0
    disk:
      color: 'blue,bold'
      min: 0
      aggregator: 'growth'
      graphHeight: 3
      yAxis:
        decimals: 0
stats_opts =
  statsinterval: 1
containers = {}
start = { symbol: '▶', color: 'green'}
stop = { symbol: '■', color: 'red'}
ready = { symbol: '▼', color: 'yellow,bold'}
pattern = /Server startup/
console.log = (x) -> {}
stats(stats_opts).pipe through.obj (container, enc, cb) ->
  name = container.name
  cpu = container.stats.cpu_stats.cpu_usage.cpu_percent
  io = 0
  for block in container.stats.blkio_stats.io_service_bytes_recursive
    if block.op is 'Total'
      io = block.value
  containers[name] ?= {}
  if not containers[name].running
    log [name], (event) ->
      process.stdout.write event +"\n"
      turtle.metric(name,'cpu').mark(ready)
  turtle.metric(name,'cpu').push(cpu)
  turtle.metric(name,'disk').push(io)
  containers[name].running = true
  containers[name].last = Date.now()
  cb()

setTimeout ->
  monitor
    onContainerUp: (container) ->
      turtle.metric(container.Name,'cpu').mark(start) if not containers[container.Name]?.running
    onContainerDown: (container) ->
      turtle.metric(container.Name,'cpu').mark(stop)
      containers[container.Name].running = false
, 1000

setInterval ->
  for name, container of containers
    if container.last + 1200 < Date.now()
      turtle.metric(name,'cpu').push(0)
      turtle.metric(name,'disk').push(0)
, 500
