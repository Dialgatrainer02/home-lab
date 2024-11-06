# todo 
0. fix the wireguard tunnel!!!! -[] (ipv6 still needs work)
1. fix buildarr and get arr stack operational -[](testing recyclarr to automate part of sonarr + radarr jellyfin is already automated unsure as to jellyseer prowlarr and non trash related config)
3. sort out storage for arr stack media and minecraft world -[] (done in terraform then point ansible to correct directory)
4. figure out how to get metrics from vps without exposing them -[] (potemtial solution with ca and mtls)
5. find way to properly automate jellyfin -[x] # pottential fix using https://gist.github.com/aslafy-z/dce9fd98bbe42f21095eb231687ae4f5 (needs fixing cureently gives 503's)
7. get duckdns to point to home network -[] (needs work in terraform for dns provisioning as sky doesnt like duckdns)
10. dynamic inventory and provisioning with teraform/opentofu -[ ](provisioning is finished however intergration with ansible is stil needed)


(this project expects to be in the subnet 192.168.0.0/24)

# how to use 
1. place proxmox and oci credentials in terraform/secrets_override.tf
2. (place inventory in inventory.yml)
3, plaace seret varibles in secrets.yml
3. run todu/terraform init paln apply in /terraform 
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