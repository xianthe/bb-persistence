# ROUTERS

jQuery ->
  
  class TimeLogRouter extends Backbone.Router
    routes:
      '': 'redirectToToday'
      'tasks/:year/:month/:day': 'show'
    initialize: ->
      @view = new app.AppView collection: app.Tasks
    show: (year, month, day) ->
      app.Tasks.setDate year, month, day
    redirectToToday: ->
      today = new Date()
      [day, month, year] = [today.getDate(), today.getMonth()+1, today.getFullYear()]
      Backbone.history.navigate "tasks/#{year}/#{month}/#{day}", true

@app = window.app ? {}
@app.TimeLogRouter = TimeLogRouter

