AWS = require 'aws-sdk'

AWS.config.update
  region: process.env['AWS_DEFAULT_REGION'] or 'us-east-1'
  
ssm           = new AWS.SSM()
ssmParameters = []

inputChunks = []
process.stdin.resume()
process.stdin.setEncoding 'utf8'

process.stdin.on 'data', (chunk) ->
  inputChunks.push chunk
  
process.stdin.on 'end', ->
  inputJSON = inputChunks.join()
  try
    parsedData = JSON.parse(inputJSON)
  catch err
    failWithmessage "Unable to process input #{inputJSON}. #{err}"
    
  getAllParameters parsedData

failWithmessage = (msg) ->
  process.stderr.write '[get-ssm-params] ' + msg
  process.exit 1
  
getAllParameters = (cfg, NextToken) ->
  params = 
    Path: cfg.path
    WithDecryption: true
    Recursive: true
    NextToken: NextToken
      
  ssm.getParametersByPath params, (err, data) ->
    if (err)
      failWithmessage "[AWS] #{err}"
    else
      ssmParameters = ssmParameters.concat data.Parameters
      if data.NextToken
        getAllParameters cfg, data.NextToken
      else
        ssmParameters.map (param) ->
          param.Name = param.Name.replace(cfg.path, '').replace(/^\//,'')
          delete param.Type
          delete param.Version
        
        ssmParameters.sort (a, b) ->
          return -1 if a.Name < b.Name
          return 1 if a.Name > b.Name
          return 0
          
        try
          process.stdout.write JSON.stringify {ApplicationParameters: JSON.stringify(ssmParameters, null, 2)}
        catch error
          failWithmessage error
