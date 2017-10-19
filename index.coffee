AWS = require 'aws-sdk'

AWS.config.update
  region: process.env['AWS_DEFAULT_REGION'] or 'us-east-1'
  
ssm           = new AWS.SSM()
path          = process.argv[2]
ssmParameters = []

unless path
  console.log 'Please provide a path '

getAllParameters = (NextToken) ->
  params = 
    Path: path
    WithDecryption: true
    Recursive: true
    NextToken: NextToken
      
  ssm.getParametersByPath params, (err, data) ->
    if (err)
      console.log(err, err.stack)
    else
      ssmParameters = ssmParameters.concat data.Parameters
      if data.NextToken
        getAllParameters data.NextToken
      else
        ssmParameters.map (param) ->
          param.Name = param.Name.replace(path, '').replace(/^\//,'')
          delete param.Type
        console.log JSON.stringify {ApplicationParameters: ssmParameters}, null, 2

do getAllParameters
