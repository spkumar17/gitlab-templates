
[[runners]]
  name = "ip-172-31-14-204"
  url = "https://gitlab.com"
  id = 48109337
  token = "glrt-c5K2EUmVAIPAJpCzIqX1hG86MQpwOjE2bWZpcQp0OjMKdTpkazE4aRg.01.1j1igzhr5"
  token_obtained_at = 2025-07-13T12:05:39Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker+machine"
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "ruby:2.7"
    privileged = true
    services = ["docker:24.0.5-dind"]
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mtu = 0
  [runners.machine]
    IdleCount = 0
    IdleScaleFactor = 0.0
    IdleCountMin = 0
    MachineDriver = ""
    MachineName = ""
