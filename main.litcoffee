# Find-a-day

This will be a simple web app for choosing days for events,
essentially just showing a calendar, and then people can tick of
which days are possible.

Implemented in Literate CoffeeScript, meaning that this document is also the program :)


# Crating notenotes

- only log in via twitter/fb/google/..., no local login management
- Show description and login and gray-out calender, when not logged in. 
- creator is event-owner per default
- event-owner can add other owners from participant list. can remove newer owners from list
- event-owner can edit description for event
- event-owner can set critical participants

# Tasks

- edit only when owner
- participant property list when owner (critical,owner)
- add owner / remove newer owners
- sign-up database and clickable dates when logged in
- unloggedin-view - gray-out + login-info
- markdown description
- calendar show date status 

- later
    - switch to std-dates instead of based on local time.
    - better styling
    - secure
    - list of best dates
    - change number of months shown


# Actual implementation


## Calendar data structure

    createMonths = ->
        createWeeks = ->
            createDays = ->
                days = []
                for day in [1..7]
                    days.push
                        inactive: date.getMonth() isnt month
                        date: date.getDate()
                    date.setDate date.getDate() + 1
                days

            month = date.getMonth() 
            while date.getDay() != 1
                date.setDate(date.getDate() - 1)
            weeks = [createDays()]
            while date.getMonth() is month
                weeks.push createDays()
            weeks

        date = new Date()
        curMonth = date.getMonth()
        [0..11].map (i) ->
            date.setDate 1
            date.setMonth curMonth + i
            { 
                monthNum: date.getMonth()
                monthName: monthNames[date.getMonth()]
                weeks: createWeeks()
            }

## The Client

    if Meteor.isClient
        pageName = ->
            return location.pathname.slice(1)

### Main

    if Meteor.isClient
        Template.calendar.months = createMonths
        Template.main.content = ->
            if not Meteor.userId() and not eventDB.findOne {_id: pageName()} 
                Template.signInToCreateEvent()
            else
                Template.event()

### Event description

    if Meteor.isClient

      Template.eventDescription.eventDescription = ->
        edit = Session.get "edit"
        event = eventDB.findOne {_id: pageName()}
        console.log event, edit
        if not event
            event = {_id: pageName(), desc: "# " + pageName() + "\n\n description here..."}
            eventDB.insert event 
        if edit
            Template.eventEdit
                desc: event.desc
        else
            Template.eventShow
                desc: (new Showdown.converter()).makeHtml event.desc

      Template.eventShow.events
        "click #edit": ->
            Session.set "edit", true

      Template.eventEdit.events
        "click #save": ->
            desc = (document.getElementById "descEdit").value
            eventDB.update {_id: pageName()}, {desc: desc}
            console.log "HERE"
            Session.set "edit", false

## Server

    if Meteor.isServer
        Meteor.startup ->
            console.log "server startup"

## Databases and global state

    eventDB = new Meteor.Collection("events")

    if Meteor.isClient
        Meteor.subscribe "event", pageName()

    if Meteor.isServer
        Meteor.publish "event", (event) ->
            console.log event
            [ eventDB.find {_id: event} ]

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
