## Vaultwarden Logging – Summary

1. Default Logging
   - Vaultwarden logs to standard output (`stdout`) by default.
   - In Docker, view logs using:
     ```
     docker logs <container-name>
     ```
2. Logging to a File
   - Use the `LOG_FILE` environment variable to specify a log file path.
   - Example:
     ```
     LOG_FILE=/data/vaultwarden.log
     ```
   - Logs are written to both `stdout` and the specified file.
   - Use a Docker volume to persist the log file across container restarts and removals.
3. Logging to Syslog
   - Enable Syslog logging using:
     ```
     USE_SYSLOG=true
     EXTENDED_LOGGING=true
     ```
   - Logs will be written to both `stdout` and Syslog.
4. Changing Log Levels
   - Set `EXTENDED_LOGGING=true` to enable configurable log levels.
   - Configure `LOG_LEVEL` to control log verbosity.
     Available levels:
   - `trace` – Most detailed logs.
   - `debug` – Debugging information.
   - `info` – General operational information (default).
   - `warn` – Warnings only.
   - `error` – Error messages only.
   - `off` – Disable logging.
     Example:
   ```
   EXTENDED_LOGGING=true
   LOG_LEVEL=warn
   ```
5. Fail2Ban Compatibility
   - `warn` and `error` log levels still support Fail2Ban.
   - You can reduce unnecessary logs without breaking Fail2Ban functionality.
6. Viewing Logs
   - Docker:
     ```
     docker logs vaultwarden
     ```
   - Systemd:
     ```
     journalctl -u vaultwarden.service
     ```
   - Log file:
     ```
     cat /data/vaultwarden.log
     ```

### Key Takeaway

Vaultwarden supports three logging destinations:

- stdout – Default logging.
- File – Persistent logging using `LOG_FILE`.
- Syslog – Centralized system logging using `USE_SYSLOG`.

You can configure log verbosity using `EXTENDED_LOGGING` and `LOG_LEVEL`.

---

### Our implementation

#### Log file

- /data path is already mounted to the host machine, so we can use it to store the log file to the host machine.

```yaml
environment:
  LOG_FILE: "/data/vaultwarden.log"

volumes:
  - ./vw-data:/data
```

#### Logging to Syslog

- On Ubuntu, Syslog applications commonly communicate through /dev/log.
- Your Docker container currently cannot access the host's /dev/log socket because you haven't mounted it.

```yaml
environment:
  EXTENDED_LOGGING: "true"
  USE_SYSLOG: "true"

volumes:
  - /dev/log:/dev/log
```

url: https://github.com/dani-garcia/vaultwarden/wiki/Logging
