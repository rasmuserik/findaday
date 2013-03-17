# Find-a-day

This will be a simple web app for choosing days for events,
essentially just showing a calendar, and then people can tick of
which days are possible.

# Tasks/todo

- split up into tasks

# Actual implementation

    if Meteor.isClient

      renderCal = ->
        date = new Date()
        curMonth = date.getMonth()
        [0..11].map (i) ->
            date.setDate 1
            date.setMonth curMonth + i
            renderMonth date

      renderMonth = (date) ->
        while date.getDay() != 1
            date.setDate(date.getDate() - 1)
        date.toString() + "<br/>"

      renderLine = (date) ->
        return " 1 2 3 4 5 6 7 "

      Template.hello.calendar = ->
        renderCal()

      Template.hello.greeting = ->
        "Welcome to findaday."

      Template.hello.events
        'click input' : -> console.log "button pressed"

    if Meteor.isServer
      Meteor.startup ->
        console.log "server startup"
