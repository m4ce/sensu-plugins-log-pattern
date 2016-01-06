# Sensu plugin for monitoring patterns in log files

A sensu plugin to monitor patterns in log files.

## Usage

The plugin accepts the following command line options:

```
Usage: check-log-pattern.rb (options)
    -c, --critical <COUNT>           Critical if number of matches exceeds COUNT
    -f, --file <PATH>                Comma separated list of files (including globs) where pattern will be searched
        --ignore-case                Ignore case sensitive
    -i, --ignore-pattern <PATTERN>   Comma separated list of patterns to ignore
    -p, --pattern <PATTERN>          Comma separated list of patterns to search for (required)
        --print-matches              Print log lines that match patterns
    -s, --source <file>              Defines the log source (default: file) (required)
        --state-dir <PATH> (default: /var/cache/check-log-pattern)
                                     State directory
    -w, --warn <COUNT>               Warning if number of matches exceeds COUNT (default: 1)
```

Currently, only file is supported as source. Systemd journald support will be added in future releases.

## Author
Matteo Cerutti - <matteo.cerutti@hotmail.co.uk>
