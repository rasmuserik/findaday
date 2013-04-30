# ![logo](https://solsort.com/_logo.png) Find-a-day

This will be a simple web app for choosing days for events,
essentially just showing a calendar, and then people can tick of
which days are possible.

Implemented in Literate CoffeeScript, meaning that this document is also the program :)

Should be running online on http://findaday.meteor.com/.

_Warning:_ this code is just a hack to quickly get an app with the functionality to choose days, - not really maintained or well written :)

# General utility functions

We start out wit a couple of utility functions.

A single event is shown at the time, the name of the event shown are found from the url/location:

    if Meteor.isClient
        pageName = ->
            return location.pathname.slice(1)

## Calendar utilities

We want to get a textual representation for the date. This is also used as key in the database of signups.

    fullUTCdate = (date) ->
        date.getUTCFullYear() + "-" + 
        (date.getUTCMonth() + 1) + "-" + 
        date.getUTCDate()

When showing the calendar, we want nicely printed names, so we have a list of the months here.

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

# Databases and state

There are two databases used in the program:

- the events with description and owner info
- the signups which is event, day, and participant plus participation status

    eventDB = new Meteor.Collection("events")
    signupDB = new Meteor.Collection("signups")

The data for the current event should be synchronised to the client

    if Meteor.isClient
        Meteor.subscribe "event", pageName()

    if Meteor.isServer
        Meteor.publish "event", (event) ->
            [ (eventDB.find {_id: event}), (signupDB.find {event: event}) ]

# Calendar data structure

The calendar is created as a data structure, which is then rendered with the templates in `index.html`

    createMonths = ->
        createWeeks = ->
            createDays = ->
                days = []
                for day in [1..7]
                    fulldate = fullUTCdate(date)
                    signups = signupDB.find
                        event: pageName()
                        date: fulldate
                    participants = signups.fetch().filter((s)-> s.status is "good").length
                    maxParticipants = Math.max participants, maxParticipants
                    days.push
                        inactive: date.getUTCMonth() isnt month or
                            +date < Date.now()
                        date: date.getUTCDate()
                        participants: participants 
                        fulldate: fulldate
                        status: (signupDB.findOne 
                            event: pageName()
                            user: Meteor.userId()
                            date: fulldate)?.status || ""
                        clicked: (signupDB.findOne 
                            event: pageName()
                            user: Meteor.userId()
                            date: fulldate)?.status is "good"
                    date.setDate date.getUTCDate() + 1
                days

            month = date.getUTCMonth() 
            while date.getUTCDay() != 1
                date.setUTCDate(date.getUTCDate() - 1)
            weeks = [createDays()]
            while date.getUTCMonth() is month
                weeks.push createDays()
            console.log maxParticipants
            weeks

        maxParticipants = 0
        date = new Date()
        curMonth = date.getUTCMonth()
        result = [0..5].map (i) ->
            date.setUTCDate 1
            date.setUTCMonth curMonth + i
            { 
                monthNum: date.getUTCMonth()
                monthName: monthNames[date.getUTCMonth()]
                weeks: createWeeks()
            }
        result.forEach (month) ->
            month.weeks.forEach (week) ->
                week.forEach (day) ->
                    day.ratio = day.participants / (maxParticipants || 1)
                    if day.participants
                        day.color = calendarColor day.ratio
                    else
                        day.color = "255,255,255"
        result

    calendarColor = (ratio) ->
        if ratio < .5
            "255,#{Math.floor(255*2*ratio)},0"
        else
            "#{255-Math.floor(255*2*(ratio-0.5))},255,0"

## Bind clicks for calendar

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
                    #    signup.status = "bad"
                    #else if signup.status is "bad"
                        signup.status = ""
                    else
                        signup.status = "good"
                    signupDB.update signup._id, signup
                else
                    signup = query
                    signup.status = "good"
                    signupDB.insert signup

# Editable event description

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

# Participant list when logged in as owner

        Template.eventDescription.participants = ->
            event = getEvent()
            result = {}
            for uid, name of event.owner
                result[uid] = result[uid] || { name: name, uid: uid }
                result[uid].isOwner = true
            for uid, name of event.important
                result[uid] = result[uid] || { name: name, uid: uid }
                result[uid].important = true
            for obj in signupDB.find({event: pageName()}).fetch()
                if not result[obj.user]
                    result[obj.user] = {name: obj.username, uid: obj.user}
            obj for _, obj of result

        Template.eventDescription.events
            "click .participantOwner": ->
                event = getEvent()
                if this.isOwner
                    console.log "CCC", this.uid, Meteor.userId()
                    if this.uid is Meteor.userId()
                        alert "cannot remove self as owner"
                    else
                        delete event.owner[this.uid]
                else
                    event.owner[this.uid] = this.name
                eventDB.update {_id: event._id}, event

        Template.eventDescription.events
            "click .participantImportant": ->
                event = getEvent()
                if this.important
                    delete event.important[this.uid]
                else
                    event.important[this.uid] = this.name
                eventDB.update {_id: event._id}, event

        Template.eventDescription.events
            "click .deleteParticipant": (obj) ->
                console.log this.uid
                for signup in signupDB.find({event: pageName(), user: this.uid}).fetch()
                    signupDB.remove {_id: signup._id}

# Main

    if Meteor.isClient
        Template.calendar.months = createMonths
        Template.main.content = ->
            if not Meteor.userId() and not eventDB.findOne {_id: pageName()} 
                Template.signInToCreateEvent()
            else
                Template.event()

