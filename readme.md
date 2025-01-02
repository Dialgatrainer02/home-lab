# The plan

## modules

### generic modules

#### proxmox_ct

    makes a lxc container using the image provided 
    will output the hostname and ip address of the container


    has option to install grafana alloy and make a dns entry with config options for both

#### ansible_playbook
    runs an anible playbook on a specified host

### service modules

#### dns
    make a dns server (dnsmasq) running on specified port

    can be updated by editing hosts file

### helper modules

#### install_alloy
    wrapper around ansible playbook for imstalling grafana alloy