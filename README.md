# get-ssm-parameters

## Installation

## Usage
```
> echo '{"path":"/dev/grafana"}' | get-ssm-params
{"ApplicationParameters":"[]"}

```
or 

```
> echo '{"paths":["/dev/default","/dev/grafana"]}' | get-ssm-params
{"ApplicationParameters":"[]"}

```
or 

```
> echo '{"paths":"/dev/default /dev/grafana"}' | get-ssm-params
{"ApplicationParameters":"[]"}

```

## Development
1. clone the repo
1. make your changes
1. build `npm run build`
