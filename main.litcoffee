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

## Databases and global state

    if Meteor.isClient
        pageName = ->
            return location.pathname.slice(1)


    eventDB = new Meteor.Collection("events")
    signupDB = new Meteor.Collection("signups")

    if Meteor.isClient
        Meteor.subscribe "event", pageName()

    if Meteor.isServer
        Meteor.publish "event", (event) ->
            console.log event
            [ (eventDB.find {_id: event}), (signupDB.find {event: event}) ]


## Calendar 

### Create data structure

    createMonths = ->
        maxGood = 0
        createWeeks = ->
            createDays = ->
                days = []
                for day in [1..7]
                    fulldate = fullUTCdate(date)
                    signups = signupDB.find
                        event: pageName()
                        user: Meteor.userId()
                        date: fulldate
                    goods = signups.fetch().filter((s)-> s.status is "good").length
                    maxGood = Math.max goods, maxGood
                    days.push
                        inactive: date.getUTCMonth() isnt month or
                            +date < Date.now()
                        date: date.getUTCDate()
                        fulldate: fulldate
                        status: (signupDB.findOne 
                            event: pageName()
                            user: Meteor.userId()
                            date: fulldate)?.status || ""
                    date.setDate date.getUTCDate() + 1
                days

            month = date.getUTCMonth() 
            while date.getUTCDay() != 1
                date.setUTCDate(date.getUTCDate() - 1)
            weeks = [createDays()]
            while date.getUTCMonth() is month
                weeks.push createDays()
            console.log maxGood
            weeks

        date = new Date()
        curMonth = date.getUTCMonth()
        [0..4].map (i) ->
            date.setUTCDate 1
            date.setUTCMonth curMonth + i
            { 
                monthNum: date.getUTCMonth()
                monthName: monthNames[date.getUTCMonth()]
                weeks: createWeeks()
            }
### Bind clicks

    if Meteor.isClient
        Template.calendar.events
            "click .day": (a, b, c, d) ->
                console.log "this", this
                console.log "abcd", a, b, c, d
                if not Meteor.user()
                    return undefined
                query = 
                    event: pageName(),
                    user: Meteor.user()._id
                    username: Meteor.user().profile.name
                    date: this.fulldate
                console.log "query", query
                signup = signupDB.findOne query
                if signup
                    if signup.status is "good"
                        signup.status = "bad"
                    else if signup.status is "bad"
                        signup.status = ""
                    else
                        signup.status = "good"
                    signupDB.update signup._id, signup
                else
                    signup = query
                    signup.status = "good"
                    signupDB.insert signup

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
        getEvent = ->
            event = eventDB.findOne {_id: pageName()}
            if not event
                owner = {}
                important = {}
                owner[Meteor.userId()] = Meteor.user()?.profile?.name
                important[Meteor.userId()] = Meteor.user()?.profile?.name
                event = 
                    _id: pageName()
                    desc: "# " + pageName() + "\n\ndescription here..."
                    owner: owner
                    important: important
                if Meteor.user()
                    eventDB.insert event 
            event

        Template.eventDescription.edit = ->
            Session.get "edit"

        Template.eventDescription.htmlDescription = ->
            (new Showdown.converter()).makeHtml getEvent().desc

        Template.eventDescription.markdownDescription = ->
            getEvent().desc

        Template.eventDescription.owner = ->
            console.log "HERE", Meteor.user(), getEvent()?.owner
            getEvent().owner?[Meteor.user()?._id] 

        Template.eventDescription.events
            "click #edit": ->
                Session.set "edit", true

        Template.eventDescription.events
            "click #save": ->
                event = getEvent()
                event.desc = (document.getElementById "descEdit").value
                eventDB.update {_id: event._id}, event
                Session.set "edit", false

## Server

    if Meteor.isServer
        Meteor.startup ->
            console.log "server startup"

## General utility functions

    fullUTCdate = (date) ->
        date.getUTCFullYear() + "-" + 
        (date.getUTCMonth() + 1) + "-" + 
        date.getUTCDate()


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
