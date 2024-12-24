### Homelab

# order of operations

dns is provisioned and ansible configures a basic dns server

step ca is provisioned using the dns server and is configured 

dns is reconfigured to include all machines made since the start 

acme certs are provided to all the hosts


task: reduce dependancy mess and speed up apply (currently takes 5 minutes to apply)