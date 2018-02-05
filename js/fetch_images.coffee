class Enzymic.Ads.FetchImages
  constructor: (@$form) ->
    @adFormId = @$form.prop('id')
    @contentType = @$form.data('contentType')

    @$destinationUrlField = @$form.find("input[name='ad[destination_url]']")
    @$fetchedImagesWrapper = @$form.find('.fetched-images')
    @$fetchImageButton = @$form.find('.fetch-images-button')
    @$remoteImageUrl = @$form.find("input[name='ad[remote_image_url]']")
    @$fetchImageContainer = @$form.find('.ad-fetch-image')

    @fetchingMessage = @$fetchImageButton.data('fetchingMessage')
    @fetchAgainMessage = @$fetchImageButton.data('fetchAgainMessage')
    @$fetchImagePrefix = if window.location.pathname.includes('administrator') then '/administrator' else ''

    @_fetchImagesHandler()
    @$fetchImageButton.html(@fetchAgainMessage)
    @$fetchImageButton.attr('disabled', false)

  _fetchImagesHandler: ->
    @$fetchImageButton.on 'click', (e) =>
      e.preventDefault()
      if !@$fetchImageButton.is('[disabled]')
        @_getFetchImages()
        @$fetchImageButton.html(@fetchingMessage)
        @$fetchImageButton.attr('disabled', true)

  _getFetchImages: ->
    $.ajax
      type: 'POST'
      url: @$fetchImagePrefix + '/fetch_images'
      data: {
        destination_url: @$destinationUrlField.val()
        ad_id: @adFormId
        content_type: @contentType
      }
      success: (data) =>
        @$fetchedImagesWrapper.html(data)
        $images = @$fetchedImagesWrapper.find('.image-preview')
        if $images.length
          $.each $('.fetch-preview'), (index, preview) ->
            contentSize = $(preview).data('content_size')
            $(preview).find('.crop-image-button, .image-preview').addClass("size_#{contentSize}")
            $(preview).find('.image-preview').data('content_size', contentSize)
          @$carousel = $(".carousel_for_ad_#{@adFormId}")
          @_carouselSlideHandler(@$carousel)
          @_setCurrentFetchedImage(@$carousel)
          $images.each (_index, imagePreviewContainer) =>
            new Enzymic.Ads.AdImageCrop(@$form, $(imagePreviewContainer))
      error: (jqXHR, textStatus) ->
        console.log textStatus
      complete: =>
        @$fetchImageButton.html(@fetchAgainMessage)
        @$fetchImageButton.attr('disabled', false)

  _carouselSlideHandler: ($carousel) ->
    $carousel.on 'slid.bs.carousel', (e) =>
      @_setCurrentFetchedImage($carousel)

  _setCurrentFetchedImage: ($carousel) ->
    $activeItem = $carousel.find('.item.active .image-preview.slider-size')
    currentImageBackground = @_backGroundImage($activeItem)
    @$remoteImageUrl.val(currentImageBackground)

  _backGroundImage: ($elementWithBackground) ->
    new Enzymic.Shared.GetBackgroundImageSrc($elementWithBackground).getImageSrc()
