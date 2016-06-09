window.App ||= {}

App.VisualizationEmbed = require './visualization-embed.js'
App.Story              = require './story.js'

$(document).ready ->

  $body = $('body')

  # visualizations
  if $body.hasClass('visualizations')
    # /visualizations/:id/embed
    appVisualization = new App.VisualizationEmbed $('body').data('visualization-id')
    appVisualization.render()
    $( window ).resize appVisualization.resize
  # stories
  else if $body.hasClass('stories')
    # /stories/:id/embed
    appStory = new App.Story $('body').data('story-id'), $('body').data('visualization-id'), false
    appStory.render()
    $( window ).resize appStory.resize

  # Activate tooltips
  $('[data-toggle="tooltip"]').tooltip()