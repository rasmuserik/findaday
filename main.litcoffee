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

        weeks = [renderWeek date, monthNum]
        while date.getMonth() is monthNum
            weeks.push renderWeek date, monthNum

        Template.calMonth
            monthName: monthName
            weeks: weeks.join("")

      renderWeek = (date, month) ->
        days = []
        for i in [1..7]
            days.push renderDay date, month
            date.setDate date.getDate() + 1
        Template.calWeek
            days: days.join " "

      renderDay = (date, month) ->
        Template.calDay
            inactive: date.getMonth() isnt month
            date: date.getDate()


      console.log Template
      Template.calendar.calendar = ->
        renderCal()

      Template.eventDescription.eventDescription = ->
        edit = true
        pageName = "dummy"
        event = eventDB.findOne {id: pageName}
        if not event
            event = {id: pageName, title: pageName, desc: ""}
            eventDB.insert event 
        if edit
            Template.eventEdit
                title: event.title
                desc: event.desc
        else
            Template.eventShow
                title: event.title
                desc: event.desc

      #Template.hello.events
      #  'click input' : -> console.log "button pressed"

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
## Databases

    eventDB = new Meteor.Collection("events")

