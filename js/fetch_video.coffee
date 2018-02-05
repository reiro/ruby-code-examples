class Enzymic.Ads.FetchVideo
  constructor: (@$form) ->
    @adFormId = @$form.prop('id')
    @contentType = @$form.data('contentType')
    @videoContainer = @$form.find('#video_ad')
    @$videoFileField = @$form.find("input[name='ad[video_attributes][video]']")
    @$videoUrlField = @$form.find("input[name='ad[video_attributes][link]']")
    @$infiniVideoUrlField = @$form.find("input[name='ad[video_attributes][infini_link]']")
    @$youkuVideoUrlField = @$form.find("input[name='ad[video_attributes][youku_link]']")
    @$fetchVideoPrefix = if window.location.pathname.includes('administrator') then '/administrator' else ''

    @_fetchVideoHandler()
    @_fetchInfiniVideoHandler()
    @_fetchYoukuVideoHandler()
    @_activateVideo()
    @_videoUploadSelectorHandler()
    @$videoUrlField.trigger('input')
    @$infiniVideoUrlField.trigger('input')
    @$youkuVideoUrlField.trigger('input')

  _videoUploadSelectorHandler: ->
    @$form.on 'click', "input[name='ad[video_attributes][video_type]']", (e) =>
      chosenValue = e.target.value
      switch chosenValue
        when 'youtube'
          @$videoUrlField.trigger('input')
        when 'file'
          @$videoFileField.trigger('input')
        when 'infini'
          @$infiniVideoUrlField.trigger('input')
        when 'youku'
          @$youkuVideoUrlField.trigger('input')
        else null

  _fetchInfiniVideoHandler: ->
    @$infiniVideoUrlField.on 'input', (e) =>
      e.preventDefault()
      url = @$infiniVideoUrlField.val()
      video_url = @_validateInfiniUrl(url)
      infiniBaseUrl = 'https://app.infinivideos.com/embedded/?story='
      if video_url
        @$infiniIframe = @$form.find('#infini-player')
        @$infiniIframe.prop('src', infiniBaseUrl + video_url)
        @$infiniVideoUrlField.prop('disabled', true)
        @$infiniIframe.load =>
          @$infiniVideoUrlField.closest('.form-group').removeClass('has-error')
          @$infiniVideoUrlField.closest('.form-group').find('.help-block').remove()
          @$infiniVideoUrlField.prop('disabled', false)
          html2canvas @$infiniIframe, onrendered: (canvas) =>
            dataURL = canvas.toDataURL('image/jpeg')
            $("#ad_image").parent().append("<input name='ad[image]' type='hidden' id='ad_image_canvas'>")
            $('#ad_image_canvas').val(dataURL)
      else
        @$form.find('#infini-player').prop('src', '')

  _validateInfiniUrl: (url) ->
    if url != undefined or url != ''
      regExp = /^(https?:\/\/app\.infinivideos\.com\/embedded\/\?story=|https?:\/\/app2\.infinivideos\.com\/play\/\?story=)(.*)$/
      match = url.match(regExp)
      if match && match.length == 3
        match[2]
      else
        false

  _fetchYoukuVideoHandler: ->
    @$youkuVideoUrlField.on 'input', (e) =>
      e.preventDefault()
      url = @$youkuVideoUrlField.val()
      video_url = @_validateYoukuUrl(url)
      youkuBaseUrl = 'https://player.youku.com/embed/'
      if video_url
        @$youkuIframe = @$form.find('#youku-player')
        @$youkuIframe.prop('src', youkuBaseUrl + video_url)
        @$youkuVideoUrlField.prop('disabled', true)
        @$youkuIframe.load =>
          @$youkuVideoUrlField.closest('.form-group').removeClass('has-error')
          @$youkuVideoUrlField.closest('.form-group').find('.help-block').remove()
          @$youkuVideoUrlField.prop('disabled', false)
          html2canvas @$youkuIframe, onrendered: (canvas) =>
            dataURL = canvas.toDataURL('image/jpeg')
            $("#ad_image").parent().append("<input name='ad[image]' type='hidden' id='ad_image_canvas'>")
            $('#ad_image_canvas').val(dataURL)
      else
        @$form.find('#youku-player').prop('src', '')

  _validateYoukuUrl: (url) ->
    if url != undefined or url != ''
      regExp = /^(https?:\/\/player\.youku\.com\/embed\/)(.*)$/
      match = url.match(regExp)
      if match && match.length == 3
        match[2]
      else
        false

  _validateYouTubeUrl: (url) ->
    if url != undefined or url != ''
      regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|\?v=)([^#\&\?]*).*/
      match = url.match(regExp)
      if match and match[2].length == 11
        match[2]
      else
        false

  _fetchVideoHandler: ->
    @$videoUrlField.on 'input', (e) =>
      e.preventDefault()
      url = @$videoUrlField.val()
      if @_validateYouTubeUrl(url)
        @$videoUrlField.prop('disabled', true)
        @_getFetchVideo(url)
      else
        $imagePreview = @videoContainer.find('.video_container img')
        $imagePreview.attr('src', '')
        $imagePreview.attr('alt', '')
        @videoContainer.find('.video_container .js-player').html('')
        
  _activateVideo: ->
    jsPlayer = document.querySelector('.ad-fetch-video .js-player')
    if jsPlayer?
      plyr.setup(jsPlayer, {debug: false})
      jsPlayer.addEventListener 'ready', (event) ->
        player = event.detail.plyr
        playerContainer = $($(player.getContainer())[0]).parent()
        previewContainer = $(playerContainer).parent().find('.yt_preview')
        controlsContainer = $(playerContainer).find('.plyr__controls')
        previewContainer.hide()
        playerContainer.show()
        controlsContainer.hide()
        playerContainer.mouseenter ->
          player.play()
          controlsContainer.show()
        playerContainer.mouseleave ->
          player.pause()
          controlsContainer.hide()

  _getFetchVideo: (url) ->
    $.ajax
      type: 'POST'
      url: @$fetchVideoPrefix + '/fetch_video'
      data: {
        video_url: url
        ad_id: @adFormId
      }
      success: (data) =>
        $imagePreview = @videoContainer.find('.video_container').first()
        $imagePreview.html(data)
        @_activateVideo()
      error: (jqXHR, textStatus) ->
        console.log textStatus
      complete: =>
        @$videoUrlField.prop('disabled', false)
