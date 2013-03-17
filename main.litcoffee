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
          .join ""

      renderMonth = (date) ->
        monthNum = date.getMonth() 
        monthName = monthNames[monthNum]
        while date.getDay() != 1
            date.setDate(date.getDate() - 1)

        Template.calMonth
            monthName: monthName
            weeks: (renderWeek date, monthNum for i in [1..5]).join("")

      renderWeek = (date, month) ->
        days = []
        for i in [1..7]
            days.push renderDay date
            date.setDate date.getDate() + 1
        Template.calWeek
            days: days.join " "

      renderDay = (date, month) ->
        Template.calDay
            date: date.getDate()


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
