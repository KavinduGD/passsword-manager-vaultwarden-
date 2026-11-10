# Setup - Create vault warden server

## ‼️ This setup is not in a Ubuntu environment, it is in a Debian environment. Please make sure you are using the correct commands for your OS.

## Lets create a brand new vault warden server. This will be a fresh install of the vault warden server, and will not have any existing data or configuration.

- you need to prepare a ubuntu vm that has port 80 and 443 open (after creating the server you can turn off port 80. port 80 used when lets encrypt is creating the certificate).
- In that vm you have to have microk8s cluster with ingress enabled.
- add cert manager crd to the cluster. (if cert-manager is not already installed)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.3/cert-manager.yaml
kubectl get pods -n cert-manager
```

- point the domain name to the public ip of the vm.

```bash
- in 12-setup/ansible we have the ansible playbook that will create the vault warden server for us. This playbook will install all the necessary dependencies, create the necessary directories, and configure the vault warden server.
- here are the files inside that directory:

```

12-setup/ansible
├── ansible.cfg
├── inventory.ini
├── keys
├── vault-secrets.yml
└── vaultwarden.yml

````

```yaml
ansible.cfg: contains the ansible configuration for the playbook
inventory.ini: contains the inventory of the hosts
keys: contains the SSH keys for the hosts
vault-secrets.yml: contains the secrets for the vault
vaultwarden.yml: contains the playbook for setting up the vault warden server
````

- keys, ansible.cfg are not necessary for the playbook to run, but they are included for completeness. You can remove them if you want.

```ini
[defaults]
inventory = ./inventory.ini
host_key_checking = False
```

- and then add the vaultwarden server to the inventory.ini file. The inventory.ini file should look like this:

```ini
[vaultwarden]
vaultwarden01 ansible_host=3.110.164.159
[vaultwarden:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=./keys/vaultwarden-key.pem
ansible_ssh_extra_args="-o IdentitiesOnly=yes"
```

- change the vaultwarden.yml file. there are lots of variables that you can change in the vaultwarden.yml file. you can change the domain name, the email address, the SMTP server, and the SSO configuration. you can also change the admin token and the SMTP password. make sure to change those values before running the playbook.

- refer this to more env variables [`env variables`](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template)
- after that you need to create a vault-secrets.yml file that will contain the secrets for the vault. The vault-secrets.yml file should look like this:

```bash
ansible-vault create vault-secrets.yml
```

- remember the password you used to create the vault-secrets.yml file, you will need it later to edit the file. also run the ansible playbook.

- add those secrets to the vault-secrets.yml file. The vault-secrets.yml file should look like this:

- when creating the admin-token use argon2id to hash the token. You can use the
  refer this. [`admin config`](../../05-configurations/admin-page/readme.md)

- make sure to have the sso secrets and smtp password

```yaml
admin_token: your_admin_token
smtp_password: your_smtp_password
sso_client_id: your_sso_client_id
sso_client_secret: your_sso_client_secret
```

- after that you can run the ansible playbook to create the vault warden server. The ansible playbook will install all the necessary dependencies, create the necessary directories, and configure the vault warden server.

```bash
ansible-playbook vaultwarden.yml --ask-vault-pass
```
