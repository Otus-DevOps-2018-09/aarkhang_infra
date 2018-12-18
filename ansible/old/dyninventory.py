#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  dyinventory.py - dynamic inventory script
#  https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html#developing-inventory-scripts
#
import subprocess
import sys
import json
import argparse

# global dictionaries
hostvars = {}
envgrp = {}
grpvars = {}

def make_group(basename, only_env):
    """Функция принимает базовое имя, возвращает список найденных инстансов 
    и добавляет их IP-адреса в словарь hostvars"""
    group = []
    gcil = 'gcloud compute instances list --format="value(%s)" --filter="name:%s"'
    props = (   'name',
                'networkInterfaces[].accessConfigs[0].natIP',
                'networkInterfaces[0].networkIP',
                'tags.items[0]'
            )
    p = subprocess.Popen( gcil % (','.join(props), basename), shell=True, stdout=subprocess.PIPE)
    for line in p.stdout:
        name, addr, intip, env = line.split()
        if only_env != '' and env != only_env:
            continue
        hostvars[name] = { "ansible_host" : addr,
                           "internal_ip" : intip }
        group.append(name)
        if env in envgrp:
            envgrp[env].append(name)
        else:
            envgrp[env] = [name]
        if name.startswith( "reddit-db" ):
            grpvars[env] = { "dbserver" : name } 
    return group    
    
        
def main(args):
    """ Создание динамического inventory"""
    p = argparse.ArgumentParser()
    p.add_argument("--limit", help="limit inventory to specific environment", action="store", dest="env")
    p.add_argument("--list", help="output JSON inventory", action="store_true", dest="printlist")
    opts = p.parse_args()
    if not opts.printlist:
        p.print_help()
        return 1
    only_env = str(opts.env or '')
    app = make_group("reddit-app", only_env)
    db  = make_group("reddit-db", only_env)
    appvars = {}
    dbvars  = {}
    
    inventory = \
    {   "app":   { "hosts": app, "vars" : appvars },
        "db":    { "hosts": db,  "vars" : dbvars },
        "_meta": { "hostvars": hostvars }
    }
    for grp in envgrp:
        inventory[grp] = { "hosts" : envgrp[grp], "vars" : grpvars[grp] }
 
    json.dump( inventory, sys.stdout, indent=4 )
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))
