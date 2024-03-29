# COLLECTIONS

class Tasks extends Backbone.Collection
  model: app.Task
  url: '/api/tasks'
  initialize: (options) ->
    @bind 'destroy', @willDestroyTask, @
  setDate: (year, month, day) ->
    # Call with either a year, 1-indexed month and a day
    # or just a Date object
    if month is undefined and day is undefined
      date = year
      [year, month, day] = [date.getFullYear(), date.getMonth()+1, date.getDate()]
    [@year, @month, @day] = [year, month, day]
    @url = "/api/tasks/#{year}/#{month}/#{day}"
    @resetUndo()
    @fetch()
    @trigger 'change:date'
  currentDate: ->
    new Date(@year, @month-1, @day)
  isToday: ->
    # Returns true if today is the date being tracked by this Collection.
    date = @currentDate()
    today = new Date()
    date.getFullYear() == today.getFullYear() and
      date.getMonth() == today.getMonth() and
      date.getDate() == today.getDate()
  hasStarted: ->
    return false unless @completedTasks().length > 0
    for task in @completedTasks() when task.get('title') == 'Start'
      return true
    false
  completedTasks: ->
    tasks = @filter (task) ->
      task.get('completedAt')
    _.sortBy tasks, (task) ->
      task.get('completedAt')
  incompleteTasks: ->
    @reject (task) ->
      task.get('completedAt')
  createStartTask: ->
    @create
      title: 'Start'
      completedAt: (new Date).getTime()
      duration: 0
  duration: ->
    durationSeconds = 0
    for duration in @pluck('duration')
      if duration > 0
        durationSeconds += duration
    durationSeconds
  tagReports: ->
    tagReports =
      other:
        name:'other'
        duration:0
    for task in @completedTasks()
      if task.isCompleted() and task.get('duration')
        if tag = task.get('tag')
          if tagReports[tag]
            tagReports[tag].duration += task.get('duration')
          else
            tagReports[tag] = { name:tag, duration:task.get('duration') }
        else
          tagReports.other.duration += task.get('duration')
    if tagReports.other.duration == 0
      delete tagReports.other
    _.sortBy tagReports, (tagReport) ->
      -tagReport.duration
  comparator: (task) ->
    task.get('createdAt')
  metaData: ->
    # Returns an object with extra attributes specific to the collection,
    # such as total time spent on all completed tasks.
    date: @currentDate()
    duration: @duration()
    tagReports: @tagReports()
  secondsSinceLastTaskWasCompleted: ->
    currentTime = (new Date()).getTime()
    lastTask = _.last(@completedTasks())
    return 0 unless lastTask
    lastCompletedTime = lastTask.get('completedAt')
    millisecondsSince = currentTime - lastCompletedTime
    secondsSince = millisecondsSince / 1000
    secondsSince
  willDestroyTask: (task) ->
    @registerUndo task.toJSON()
  registerUndo: (attributes) ->
    # Queue a model's attributes to be saved.
    @undoAttributes = attributes
    if @undoAttributes.id
      delete @undoAttributes.id
    if @undoAttributes.createdAt
      delete @undoAttributes.createdAt
  resetUndo: ->
    @undoAttributes = null
  applyUndo: ->
    @create @undoAttributes
    @resetUndo()
  undoItem: ->
    # Returns the attributes of the item queued for undo.
    @undoAttributes

@app = window.app ? {}
@app.Tasks = new Tasks

