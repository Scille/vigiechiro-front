class TaxonsParents

  constructor: (Backend, currentTaxonId) ->
    @error = undefined
    @availableTaxons = []
    @_initPromise = Backend.all('taxons').all('liste').getList()

  init: (callback) ->
# Retrieve all the existing taxons to let the user choose parents
    @_initPromise.then (items) =>
# Remove the current taxon from the list of possible parents
      if currentTaxonId?
        @availableTaxons = items.filter (item) -> item._id != currentTaxonId
      else
        @availableTaxons = items
      @parentTaxonsDict = {}
      for taxon in items
        @parentTaxonsDict[taxon._id] = taxon
      if callback?
        callback()

  parseResponse: (response) ->
    if (response.status == 422 and response.data._error.message.match('^circular dependency'))
      @error = true

  idToData: (ids) ->
    if ids?
      (@parentTaxonsDict[id] for id in ids)
    else
      ids

  dataToId: (datas) ->
    if datas?
      (data._id for data in datas)
    else
      datas

