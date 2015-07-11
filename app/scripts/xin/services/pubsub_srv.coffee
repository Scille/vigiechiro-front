do =>

  PubSub = =>
    self =
      subscriptions: {}
      lastData: {}

      subscribe: (subscription, subscriber) ->

        self.subscriptions[subscription] = []  unless self.subscriptions[subscription]

        subscriber self.lastData[subscription] if self.lastData[subscription]?

        # adds the callback to the array & returns the index for deletion later
        index = (self.subscriptions[subscription].push(subscriber) - 1)

        # return an unsubscribe function
        unsubscribe: ->
          delete self.subscriptions[subscription][index]


      publish: (subscription, data) ->

        self.lastData[subscription] = data

        return  unless self.subscriptions[subscription]

        self.subscriptions[subscription].forEach (subscriber) ->
          subscriber data or {}


      utils:

      # get a list of all subscriptions
        getAll: ->
          self.subscriptions


      # clear a single subscription
        clear: (subscription) ->
          delete self.subscriptions[subscription]  if subscription and self.subscriptions[subscription]


      # clean out the whole pub/sub mechanism
        clean: ->
          self.subscriptions = {}


  angular.module("xin_pubsub", [])
  .factory( "PubSub", PubSub)
