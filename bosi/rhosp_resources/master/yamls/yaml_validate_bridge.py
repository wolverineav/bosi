#!/usr/bin/env python

import argparse
import yaml

SUPPORTED_BOND = ['ovs_bond', 'linux_bond']


def validate_yaml_bridge(yaml_file_path):
    yaml_file = open(yaml_file_path, 'r')
    config_yaml = yaml.load(yaml_file)
    network_config_list = (config_yaml['resources']['OsNetConfigImpl'][
                               'properties']['config']['str_replace'][
                               'params']['$network_config']['network_config'])
    for config in network_config_list:
        config_type = config.get('type')
        # if its neither ivs_bridge or ovs_bridge, move on
        if config_type != 'ivs_bridge' and config_type != 'ovs_bridge':
            continue

        # for ivs_bridge, no other checks required. return True
        if config_type == 'ivs_bridge':
            return True

        # for ovs_bridge, check that bridge name is br-ex
        if config_type == 'ovs_bridge':
            if config.get('name') != 'br-ex':
                continue
            members = config.get('members')
            for member in members:
                # also check that type of bond for interface is supported
                if member.get('type') not in SUPPORTED_BOND:
                    continue
                # everythig checks out, return True
                return True
    # we looped through the config, did not find anything matching completely
    # return False
    return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--yaml-file", required=True,
                        help="RHOSP controller.yaml or compute.yaml with "
                             "the bridge configuration to be validated.")
    args = parser.parse_args()

    valid_yaml_config = validate_yaml_bridge(args.yaml_file)
    if valid_yaml_config:
        print ("Bridge configuration in yaml is correct.")
    else:
        print ("Incorrect bridge configuration in yaml. Please check "
               "deployment guide before proceeding.")


if __name__ == "__main__":
    main()
