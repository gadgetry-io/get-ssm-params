AWS   = require 'aws-sdk'
async = require 'async'

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
          
  if parsedData.path?
    getAllParameters parsedData.path, null, null, (err, res) ->
      failWithmessage err if err
      returnApplicationParameters [res]
      
  if parsedData.paths?
    if typeof parsedData.paths == 'string'
      parsedData.paths = parsedData.paths.split(' ')
    async.mapSeries parsedData.paths, ((path, cb) ->
      getAllParameters path, null, null, cb
      ), (err, res) ->
        failWithmessage err if err
        returnApplicationParameters res
      
failWithmessage = (msg) ->
  process.stderr.write '[get-ssm-params] ' + msg
  process.exit 1
  
returnApplicationParameters = (parameterArray = []) ->
  applicationParameters = null
  for parameters in parameterArray
    applicationParameters or= parameters
    applicationParameters = joinObjects applicationParameters, parameters
  
  try
    if process.argv[2] == '--json'
      process.stdout.write JSON.stringify {ApplicationParameters: applicationParameters}, null, 2
    else
      process.stdout.write JSON.stringify {ApplicationParameters: JSON.stringify(applicationParameters, null, 2)}
  catch error
    failWithmessage error

getAllParameters = (path, NextToken, ssmParameters = [], callback) ->
  params =
    Path: path
    WithDecryption: true
    Recursive: true
    NextToken: NextToken
    
  ssm.getParametersByPath params, (err, data) ->
    if (err)
      callback "[AWS SSM getParametersByPath] #{err}"
    else
      ssmParameters = ssmParameters.concat data.Parameters
      if data.NextToken
        getAllParameters path, data.NextToken, ssmParameters, callback
      else
        ssmParameters.map (param) ->
          param.Name = param.Name.replace(path, '').replace(/^\//,'')
          delete param.Type
          delete param.Version
        
        ssmParameters.sort (a, b) ->
          return -1 if a.Name < b.Name
          return 1 if a.Name > b.Name
          return 0
        callback null, ssmParameters

joinObjects = ->
  idMap = {}
  # Iterate over arguments
  i = 0
  while i < arguments.length
    # Iterate over individual argument arrays (aka json1, json2)
    j = 0
    while j < arguments[i].length
      currentID = arguments[i][j]['Name']
      if !idMap[currentID]
        idMap[currentID] = {}
      # Iterate over properties of objects in arrays (aka id, name, etc.)
      for key of arguments[i][j]
        `key = key`
        idMap[currentID][key] = arguments[i][j][key]
      j++
    i++
  # push properties of idMap into an array
  newArray = []
  for property of idMap
    `property = property`
    newArray.push idMap[property]
  newArray