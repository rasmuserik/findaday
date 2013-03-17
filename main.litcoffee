# Find-a-day

This will be a simple web app for choosing days for events,
essentially just showing a calendar, and then people can tick of
which days are possible.

# Tasks/todo

Initial prototype
- create calendar view
- page for each event + link calendar-day-view to dummy database
- user listing w/ name and checkoff
- actual data for users and days
- connect to mongo-db data
- editable markdown text for the event

# Actual implementation

## The Client
    if Meteor.isClient

### Render a calendar on the client

      renderCal = ->
        date = new Date()
        curMonth = date.getMonth()
        [0..11].map (i) ->
            date.setDate 1
            date.setMonth curMonth + i
            renderMonth date

      renderMonth = (date) ->
        month = monthNames[date.getMonth()]
        while date.getDay() != 1
            date.setDate(date.getDate() - 1)

        console.log month
        Template.calMonth
            monthName: month 
            weeks: [renderWeek date for i in [1..5]].join("")

      renderWeek = (date) ->
        Template.calWeek
            days: "1 2 3 4 5 6 7"

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

## General utility functions
    monthNames = [
        "January"
        "February"
        "March"
        "April"
        "May"
        "June"
        "July"
        "August"
        "September"
        "October"
        "November"
        "December"]
