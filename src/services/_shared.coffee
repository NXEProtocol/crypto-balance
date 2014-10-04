Promise = require("bluebird")
_ = require('underscore')
req = Promise.promisifyAll(require("request"))

params = (url, addr) ->
  url: url
  json: true
  body:
    jsonrpc: "2.0"
    id: 0
    method: "get_normalized_balances"
    params:
      addresses: [addr]

party = (addr, services) ->
  Promise
    .all services
    .map (attrs) ->
      [token, url] = attrs
      req.postAsync(params url, addr)
        .spread (resp, json) ->
          if resp.statusCode in [200..299] and !json.error
            for item in json.result
              tokenName = "#{token}/#{item.asset}"
              status: 'success', address: item.address, quantity: item.normalized_quantity.toFixed(8), asset: tokenName
          else
            if error = json.error
              message = "#{error.message}. Code: #{error.code}."
              message += " #{error.data.message}" if error.data?.message
            else
              message = "#{json.message}. Code: #{json.code}. #{json.data}"
            [status: 'error', service: url, message: message, raw: resp]
    .reduce (item, merged) ->
      merged.concat item
    , []


exports.party = party

