#= require html2canvas

class TranslationEngine

  submitButton: ''
  translationsQueue: []
  screenshots: []
  screenshotsCaptured: {}
  translationIndex: 0
  highlights: []
  variant: 'desktop'

  constructor: (startButton) ->
    @startButton = $(startButton)
    @lookupDom()
    @bindStartButton()
    @variant = 'mobile' if $('body').hasClass('mobile')

  start: ->
    setTimeout @nextTranslationScreeshot, 100

  appendScreenshotsOverlay: ->
    if $('body').find('.screenshots-overlay').length == 0
      $('body').append('<div class="screenshots-overlay" data-html2canvas-ignore="true"></div>')
      $('body').append('<div class="screenshots-status" data-html2canvas-ignore="true"></div>')

  dismissScreenshotsOverlay: ->
    setTimeout ->
      $('body').find('.screenshots-overlay').detach()
      $('body').find('.screenshots-status').detach()
    , 1000

  bindStartButton: ->
    @startButton.click =>
      if @translationsQueue.length > @translationIndex
        setTimeout @nextTranslationScreeshot, 100
      else
        @appendScreenshotsOverlay()
        @setStatusText('Screenshots already send')
        @dismissScreenshotsOverlay()

  nextTranslationScreeshot: =>
    if @translationsQueue.length > @translationIndex
      @renderHighlight()
    else
      @sendTranslations()

  lookupDom: ->
    @lookupTextDom()
    @lookupAttributesDom()
    @lookupMissingTranslationDom()

  lookupTextDom: ->
    while $(':contains("--TRANSLATION--")').length > 0
      $(':contains("--TRANSLATION--")').each (i, element) =>
        element = $(element)
        if element.find(':contains("--TRANSLATION--")').length == 0
          text    = element.html()
          matched = @findTranslationFromText(text)
          element.html(text.replace(matched[0], ''))

          @translationsQueue.push
            key:     matched[1],
            element: element

  lookupAttributesDom: ->
    $('*').each (i, element) =>
      $.each element.attributes, (i, attribute) =>
        if attribute.value.match('--TRANSLATION--')
          element = $(element)
          text    = attribute.value
          matched = @findTranslationFromText(text)
          element.attr(attribute.name, text.replace(matched[0], ''))

          @translationsQueue.push
            key:     matched[1],
            element: element

  lookupMissingTranslationDom: ->
    $('[class^="translation"]').each (i, element) =>
      element = $(element)
      if element.attr('title') != undefined && element.attr('title').match('translation')
        @translationsQueue.push
          element: element,
          key:     element.attr('title').replace('translation missing: ', '')

  findTranslationFromText: (text) ->
    translations_regexp = /--TRANSLATION--([\w\_\-.]*)--/g
    translations_regexp.exec(text)

  setStatusText: (text) ->
    $('body').find('.screenshots-status').text(text)
  sendTranslations: ->
    data = {
      location:   window.location.pathname,
      images:     @screenshots,
      highlights: @highlights
    }
    @setStatusText('Sending translations')

    $.ajax(
      url:  '/translation_engine',
      type: 'POST',
      data: JSON.stringify(data),
      contentType: 'json'
    ).done (response) =>
      @setStatusText(response.message)
      @dismissScreenshotsOverlay()

  renderHighlight: ->
    @appendScreenshotsOverlay()

    translation = @translationsQueue[@translationIndex]

    @setStatusText("Capturing #{translation.key} (#{@translationIndex}/#{@translationsQueue.length})")

    image_name = window.location.pathname

    type = 'span'

    if translation.element.parent('select').length > 0
      main_element = translation.element.parent('select')
      type = 'select'
      original_selected_value = main_element.val()
      new_value = translation.element.val()
      image_name += "#select_#{main_element.attr('id')}_#{new_value}"
      main_element.val(new_value)

    else if translation.element.closest('.dropdown').length > 0
      main_element = translation.element
      dropdown     = main_element.closest('.dropdown')
      dropdown.addClass('open')
      image_name += "#dropdown_#{dropdown.attr('id')}"
      type = 'dropdown'

    else if translation.element.closest('.modal').length > 0
      main_element = translation.element
      modal = main_element.closest('.modal')
      modal.css(height: $(document).height()).removeClass('fade in').modal('show')
      $('.modal-backdrop').css(height: $(document).height())
      image_name += "#modal_#{modal.attr('id')}"
      type = 'modal'

    else
      main_element = translation.element

    offset = main_element.offset()
    width  = main_element.outerWidth()
    height = main_element.outerHeight()

    @highlights.push
      key:        translation.key,
      image_name: image_name,
      x:          offset.left,
      y:          offset.top,
      width:      width,
      height:     height

    setTimeout =>
      if @screenshotsCaptured[image_name] == true
        if type == 'select'
          main_element.val(original_selected_value)
        else if type == 'dropdown'
          main_element.closest('.dropdown').removeClass('open')
        else if type == 'modal'
          main_element.closest('.modal').modal('hide')
        @translationIndex += 1
        @nextTranslationScreeshot()
      else
        html2canvas([ document.body ], {
          onrendered: (canvas) =>
            @screenshots.push {
              location: document.URL,
              name:     image_name,
              variant:  @variant,
              image:    canvas.toDataURL()
            }
            @screenshotsCaptured[image_name] = true
            @translationIndex += 1
            @nextTranslationScreeshot()
        })
    , 1

$(document).ready ->
  window.TranslationEngine = new TranslationEngine('.translation_engine_start')
