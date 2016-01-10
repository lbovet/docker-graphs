stats = require 'docker-stats'
through = require 'through2'
turtle = (require 'turtle-race')
  keep: true
  seconds: true
  interval: 500
  maxGraphHeight: 6
  metrics:
    cpu:
      min: 0
      max: 100
    disk:
      min: 0
      aggregator: 'growth'

stats_opts =
  statsinterval: 1

stats(stats_opts).pipe through.obj (container, enc, cb) ->
  name = container.name
  cpu = container.stats.cpu_stats.cpu_usage.cpu_percent
  io = 0
  for block in container.stats.blkio_stats.io_service_bytes_recursive
    if block.op is 'Total'
      io = block.value
  turtle.metric(name,'cpu').push(cpu)
  turtle.metric(name,'disk').push(io)
  cb()
