class Enzymic.Ads.AdImageCrop
  constructor: (@$form, @$container) ->
    @$imagePreviewContainer = $(@$container)
    @$cropImageModal = $('#cropImageModal')
    @$cropImageButton = @$imagePreviewContainer.find('.crop-image-button')
    @$cropImageButton.removeClass('hidden')
    @contentType = @$form.data('contentType')
    @contentSize = @$imagePreviewContainer.data('content_size')

    switch @contentType
      when 'list'
        @aspectRatio = 1
        @minSize = [250, 250]
        @previewHeight = 219
      when 'carousel'
        @aspectRatio = 2
        @minSize = [260, 130]
        @previewHeight = 110
      when 'carousel_overlay'
        @aspectRatio = 1.2016129
        @minSize = [298, 248]
        @previewHeight = 182
      when 'single_ad', 'single_ad_scroll'
        switch @contentSize
          when '300x250'
            @aspectRatio = 1.2016129
            @minSize = [298, 248]
            @previewHeight = 182
          when '300x150'
            @aspectRatio = 2
            @minSize = [298, 148]
            @previewHeight = 110
          when '300x90'
            @aspectRatio = 3.38636364
            @minSize = [298, 88]
            @previewHeight = 65
          when '250x90'
            @aspectRatio = 2.81818181818
            @minSize = [248, 88]
            @previewHeight = 78
      when 'lead_gen', 'lead_gen_scroll'
        @aspectRatio = 2
        @minSize = [298, 148]
        @previewHeight = 110

    @$image = ''
    @currentImageBackgroundSrc = ''
    @newImageSize = ''

    @_imageCropHandler()

  _imageCropHandler: ->
    @$cropImageButton.off 'click'
    @$cropImageButton.on 'click', (e) =>
      e.preventDefault()
      @currentImageBackgroundSrc = @_backGroundImage(@$imagePreviewContainer)

      image = "<img id='imageForCrop' src='#{@currentImageBackgroundSrc}' />"
      @$cropImageModal.find('.modal-body').html(image)

      @$cropImageModal.modal(
        {
          backdrop: 'static',
          keyboard: false
        },
        'show'
      )

      if @$image && @$image.data('x') >= 0 && @$image.data('y') >= 0 && @$image.data('width') >= 0 && @$image.data('height') >= 0
        x = parseInt(@$image.data('x'))
        y = parseInt(@$image.data('y'))
        x2 = parseInt(@$image.data('width')) + x
        y2 = parseInt(@$image.data('height')) + y

      switch @contentType
        when 'list'
          @defaultSelectedArea = [x || 0, y || 0, x2 || 250, y2 || 250]
        when 'carousel'
          @defaultSelectedArea = [x || 0, y || 0, x2 || 260, y2 || 130]
        when 'carousel_overlay'
          @defaultSelectedArea = [x || 0, y || 0, x2 || 298, y2 || 248]
        when 'single_ad', 'single_ad_scroll'
          @defaultSelectedArea = switch
            when @contentSize == '300x250'
              [x || 0, y || 0, x2 || 298, y2 || 248]
            when @contentSize == '300x150'
              [x || 0, y || 0, x2 || 298, y2 || 148]
            when @contentSize == '300x90'
              [x || 0, y || 0, x2 || 298, y2 || 88]
            when @contentSize == '250x90'
              [x || 0, y || 0, x2 || 248, y2 || 88]
        when 'lead_gen', 'lead_gen_scroll'
          @defaultSelectedArea = [x || 0, y || 0, x2 || 298, y2 || 248]

      JcropAPI = $('#imageForCrop').data('Jcrop')
      JcropAPI.destroy if JcropAPI

      $('#imageForCrop').Jcrop
        bgColor: 'black'
        bgOpacity: .4
        minSize: @minSize
        boxWidth: 568
        setSelect: @defaultSelectedArea
        aspectRatio: @aspectRatio
        allowSelect: false
        onChange: (coords) => @_storeCoords(coords)
        onSelect: (coords) => @_storeCoords(coords)

      @_imageCropOkHandler()
      @_imageCropCancelHandler()

  _imageCropCancelHandler: ->
    $cropCancel = @$cropImageModal.find('[data-crop-cancel]')
    $cropCancel.off 'click'
    $cropCancel.on 'click', (e) =>
      e.preventDefault()
      @$cropImageModal.modal('hide')

  _imageCropOkHandler: ->
    $cropOk = @$cropImageModal.find('[data-crop-ok]')
    $cropOk.off 'click'
    $cropOk.on 'click', (e) =>
      e.preventDefault()
      @$cropImageModal.modal('hide')
      @$imagePreviewContainer.find('img').remove()
      @$imagePreviewContainer.append("<img src='#{@currentImageBackgroundSrc}' />")

      @_renderCropedImage(@newImageSize)

  _storeCoords: (coords) ->
    @newImageSize = coords

  _renderCropedImage: (coords) ->
    @$image = @$imagePreviewContainer.find('img')

    rx = 219 / coords.w
    ry = @previewHeight / coords.h
    rx = if rx == 0 then 1 else rx
    ry = if ry == 0 then 1 else ry

    photoX = $('#imageForCrop').width()
    photoY = $('#imageForCrop').height()

    @$image.css
      width: Math.round(rx * photoX) + 'px'
      height: Math.round(ry * photoY) + 'px'
      marginLeft: '-' + Math.round(rx * coords.x) + 'px'
      marginTop: '-' + Math.round(ry * coords.y) + 'px'

    @$image.attr('data-x', Math.round(@newImageSize.x))
    @$image.attr('data-y', Math.round(@newImageSize.y))
    @$image.attr('data-width', Math.round(@newImageSize.w))
    @$image.attr('data-height', Math.round(@newImageSize.h))

  _backGroundImage: ($elementWithBackground) ->
    new Enzymic.Shared.GetBackgroundImageSrc($elementWithBackground).getImageSrc()
