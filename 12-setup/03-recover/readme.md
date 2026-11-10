# recover

- this process exactly similar to the process of creating a new vault warden server.
- Only change that need to do is you must add the backup folder with the name vw-data in the root . So the folder structure should look like this:

```
12-setup/ansible
├── ansible.cfg
├── inventory.ini
├── keys
├── vault-secrets.yml
└── vaultwarden.yml
├── vw-data
```

- the vw-data folder should contain all the backup data that you want to restore.

### Verify Remote Vaultwarden Data Before Recovery

- Before starting recovery, connect to the remote server and check the existing Vaultwarden data directory:

  ```bash
  ls -lah /opt/vaultwarden/vw-data/
  ```

- **Ensure that `/opt/vaultwarden/vw-data/` is empty.** If it contains files or directories, the recovery process will stop because the Ansible playbook prevents overwriting existing Vaultwarden data.
- If existing data is present, back it up and remove it only if you have confirmed it is no longer needed.
- Verify that the local `vw-data` directory in the Ansible project contains the backup files you want to restore.
- Once both directories have been verified, execute the Ansible recovery playbook.
