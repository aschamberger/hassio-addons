# Remote Backup Hass.io Add-On

Automatically create Hass.io snapshots to remote server location using SCP.

When the add-on is started the following happens:
1. Snapshot is created locally with a timestamp name, e.g. `Automated backup 2018-03-04 04:00`.
1. It is copied to the specified remote location using SCP.
1. The local backup is removed again (optional).

Based on https://github.com/rccoleman/hassio-remote-backup / https://github.com/overkill32/hassio-remote-backup

## Add-On Configuration

The add-on requires the following configuration:
```json
{
  "ssh_host": "192.168.1.2",
  "ssh_port": 22,
  "ssh_user": "root",
  "ssh_key": [
"-----BEGIN RSA PRIVATE KEY-----",
"MIICXAIBAAKBgQDTkdD4ya/Qxz5xKaKojVIOVWjyeyEoEuAafAvYvppqmaBhyh4N",
"5av4i87y8tdGusdq7V0Zj0+js4jEdvJRDrXJBrp1neLfsjkF6t1XLfrA51Ll9SXF",
"...",
"X+6r/gTvUEQv1ufAuUE5wKcq9FsbnTa3FOF0PdQDWl0=",
"-----END RSA PRIVATE KEY-----"
  ],
  "remote_directory": "~/hassio-backups",
  "password": "password_protect_it",
  "keep_local_backup": "14"
}
```

`password` and `keep_local_backup` are optional attributes. `keep_local_backup` controls how many local backups you want to preserve. Default (`""`) is to keep no local backups created from this addon. If `all` then all local backups will be preserved. A positive integer will determine how many of the latest backups will be preserved. Note this will delete other local backups created outside this addon.
	
## Example automating daily backups

_configuration.yaml_
```yaml
automations:
  - alias: Daily Backup at 4 AM
  trigger:
    platform: time
    at: '4:00:00'
  action:
  - service: hassio.addon_start
    data:
      addon: local_remote_backup
```