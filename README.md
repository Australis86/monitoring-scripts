# Monitoring Scripts

A selection of scripts used for system monitoring.

## Dependencies

* smartmontools is required for some functionality

## Installation and Configuration

1. Download or clone a copy of the repository to your preferred location. Remember to include the submodules; i.e. `git clone --recurse-submodules https://github.com/Australis86/monitoring-scripts.git`; if downloading the ZIP, you will need to download the [mailutils](https://github.com/Australis86/mailutils) submodule separately.
2. Configure `mailutils` as per the [README](https://github.com/Australis86/mailutils).

> TO DO: Finish this part of the README.

## Usage

### startup_email.sh

This script is intended to be called shortly after startup and will send a brief summary of the system (i.e. network configuration, disk space and HDD SMART status) to a selected recipient.

## History

* 2018-07-07 Migrated scripts to Github.

## Copyright and Licence

Unless otherwise stated, these scripts are Copyright © Joshua White and licensed under the GNU Lesser GPL v3.
