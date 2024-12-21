restarting on new branch

### !!! terraform add arrstack disk 
# todo 
1. fix wireguaed tunnel for ipv6
2. make nginx reverse proxy config for web gui services
3. link terraform and ansible using inventory.yml(working need to fix hostvars and laptop)
4. make a single source of truth for varibles used throughout the project in terraform
5. setup and configure shadowsocks proxy
6. add wireguard-oci to logging stack securely(mtls or wireguard tunnel)
7. redo grafana logging stack(helpful names and better configs)
8. tidy and reformat "legacy" code(remove secret sprawl throughout the project and rotate any keys)
9. remove expectation about subnet
10. transistion to ipv6 where possible

(this project expects to be in the subnet 192.168.0.0/24)

# how to use 
1. place proxmox and oci credentials in terraform/secrets_override.tf
2. (place inventory in inventory.yml)
3, place seret varibles in secrets.yml
3. run tofu/terraform init paln apply in /terraform 
4. run ansible-playbook ./playbook.yml in project root 
5. should all be there

example secrets.yml
```yaml
---
password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          32353233383463343538313561633230396461613933333639616133383232306665616538376235
          3962626262313163346131626661373466326262323035360a643830653933623161323838313366
          66393539663461373963613264343138663631613263343634653934303236353466343634313830
          3633343966363364340a313930646232343135383663643365393433616431313663646563393938
          3038
duckdns_token: blah blah blah
grafana_security:
      admin_user: olivia
      admin_password: 1234
```