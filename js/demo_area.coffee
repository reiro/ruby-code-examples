class Enzymic.AdUnits.DemoArea
  constructor: (@$demoContainer) ->
    @adUnitContentType = $('[data-content-type]').data('content-type')
    @$demoArea = $(@$demoContainer).find('.demo-area')
    @adUnitContentSize = @$demoArea.data('contentSize')
    @adUnitLoadedAdsCount = @$demoArea.data('loadedAdsCount')
    @adUnitShowedAdsCount = @$demoArea.data('showedAdsCount')
    @$demoRefreshButton = $(@$demoContainer).find("[data='demo-refresh']")
    @ads = []
    @$marginFieldHeight = 7
    @adUnitSequence = $('[data-sequence]').data('sequence')
    @documentType = $('[data-document_type]').data('document_type')
    @carouselTitleOneLineLimit = 35

    @refreshAdsList()
    @_demoRefreshButtonHandler()

  refreshAdsList: ->
    $adsList = $('.ads_list').find('#ready_to_publish, #published')
    if $adsList.length
      ads = []
      $adsList.each (index, ad) =>
        $ad = $(ad)
        title = $ad.find("[data='ad-title']").text()
        description = $ad.find("[data='ad-description']").text()
        actionText = $ad.find("[data='ad-action-text']").text()
        actionColor = $ad.find("[data='ad-action-text']").attr('data-color')
        destinationUrl = $ad.find("[data='ad-destination-url']").attr('href')
        imageListSrc = $ad.find("[data='ad-image-list-src']").attr('src')
        imageCarouselSrc = $ad.find("[data='ad-image-carousel-src']").attr('src')
        image300x250Src = $ad.find("[data='ad-image-size_300x250-src']").attr('src')
        image300x150Src = $ad.find("[data='ad-image-size_300x150-src']").attr('src')
        image300x90Src = $ad.find("[data='ad-image-size_300x90-src']").attr('src')
        image250x90Src = $ad.find("[data='ad-image-size_250x90-src']").attr('src')
        adType = $ad.attr('data-type')
        autoplay = $ad.data('autoplay')
        includeLikeShare = $ad.data('include-like-share')
        short_url = $ad.data('short_url')

        ad = {
          id: index
          title: $.trim(title)
          description: $.trim(description)
          actionText: $.trim(actionText)
          actionColor: actionColor
          adType: adType
          destinationUrl: destinationUrl
          imageListSrc: imageListSrc
          imageCarouselSrc: imageCarouselSrc
          image300x250Src: image300x250Src
          image300x150Src: image300x150Src
          image300x90Src: image300x90Src
          image250x90Src: image250x90Src
          autoplay: autoplay
          includeLikeShare: includeLikeShare
          short_url: short_url
        }

        if @adUnitContentType in ['lead_gen', 'lead_gen_scroll']
          $lead_form = $ad.find('.lead_form')
          ad.privacy_link = $lead_form.attr('privacy_link')
          ad.thanks_message = $lead_form.attr('message')
          ad.thanks_description = $lead_form.attr('description')
          ad.form_title = $lead_form.attr('form_title')
          ad.fields = []
          $.each $lead_form.find('.lead_field'), (i, field) ->
            ad.fields.push $(field).data()

        if @adUnitContentType == 'carousel_overlay'
          ad.image_only = $ad.attr('image_only')
          ad.overlap_type = $ad.attr('overlap_type')

        if adType == 'video'
          ytUid = $ad.find("[data='ad-image-video-src']").attr('data-uid')
          infiniUid = $ad.find("[data='ad-image-video-src']").attr('data-infini-uid')
          youkuUid = $ad.find("[data='ad-image-video-src']").attr('data-youku-uid')
          videoSrc = $ad.find("[data='ad-image-video-src']").attr('data-video-src')
          imageVideoSrc =
            switch @adUnitContentType
              when 'carousel'
                imageCarouselSrc
              when 'carousel_overlay'
                image300x250Src
              when 'single_ad', 'single_ad_scroll'
                @_singleAdImageSrc(ad)

          ad.imageVideoSrc = imageVideoSrc
          ad.imageVideoSrc = imageVideoSrc
          ad.ytUid = ytUid
          ad.youkuUid = youkuUid
          ad.videoSrc = videoSrc

        # if not single infini ad with sizes except 300x250, then ads push
        single_infini_not_300x250 = (@adUnitContentType == 'single_ad' and ad.infiniUid?) and @adUnitContentSize != 'size_300x250'
        unless single_infini_not_300x250
          ads.push ad

      @ads = unless @adUnitSequence then @_shuffle(ads) else ads
      @ads = @ads[.. @adUnitLoadedAdsCount - 1]
      @_renderAds() unless @documentType == 'AMP' or @ads.length == 0
    else
      @ads = []
      @$demoArea.html('')

  _demoRefreshButtonHandler: ->
    @$demoRefreshButton.off 'click'
    @$demoRefreshButton.on 'click', (e) =>
      e.preventDefault()
      @refreshAdsList()

  _renderAds: ->
    @$demoArea.html(@_htmlContainerTemplate())
    if @adUnitContentType in ['single_ad', 'lead_gen', 'single_ad_scroll', 'lead_gen_scroll']
      renderedAd = @_shuffle(@ads)[0]
      @_renderAd renderedAd
    else
      @_renderAd ad for ad in @ads

    switch @adUnitContentType
      when 'list'
        @_activateList()
      when 'carousel', 'carousel_overlay'
        @_activateCarousel(@adUnitContentType)
      when 'single_ad', 'single_ad_scroll'
        @_activateSingleAd(@adUnitContentType)
      when 'lead_gen', 'lead_gen_scroll'
        @_activateLeadGen(renderedAd, @adUnitContentType)

  _singleAdImageSrc: (ad) ->
    switch @adUnitContentSize
      when 'size_300x600', 'size_970x250', 'size_320x480'
        ad.image300x250Src
      when 'size_300x250'
        ad.image300x150Src
      when 'size_728x90'
        ad.image250x90Src
      when 'size_970x90'
        ad.image300x90Src

  _activateList: ->
    $list = $(@$demoContainer).find('.list_ad_unit')
    $listAds = $list.find('.ad')
    $list.fadeIn 'slow', ->
      $listAds.eq(0).animate {opacity: 1}, 'slow', ->
        $listAds.eq(1).animate {opacity: 1}, 'slow', ->
          $listAds.eq(2).animate {opacity: 1}, 'slow', ->
            $listAds.eq(3).animate {opacity: 1}, 'slow', ->
              $listAds.eq(4).animate {opacity: 1}, 'slow', ->
                $listAds.eq(5).animate {opacity: 1}, 'slow', ->

  _activateCarousel: (type) ->
    $carousel = $(@$demoContainer).find('.carousel-ad')
    hoverAction = true
    options =
      arrows: false
      slidesToShow: @adUnitShowedAdsCount
      autoplay: false

    if @adUnitContentSize in ['size_300x600', 'size_320x480']
      options.vertical = true
      options.verticalSwiping = true
    else
      options.variableWidth = true

    $carousel.on 'afterChange', (event, slick, direction) ->
      if window.activePlayer
        ad = window.activePlayer.getContainer().closest('.ad')
        window.activePlayer.pause() unless $(ad).hasClass('slick-active')

    $carousel.slick options

    unless $carousel.has('.video_container').length
      setTimeout (->
        $carousel.slick 'slickNext'
        return
      ), 9000

    @$demoArea.on 'mouseenter', '#swipe_prev', ->
      if hoverAction
        $carousel.slick 'slickPrev'
        hoverAction = false
    @$demoArea.on 'mouseleave', '#swipe_prev', ->
      hoverAction = true
    @$demoArea.on 'mouseenter', '#swipe_next', ->
      if hoverAction
        $carousel.slick 'slickNext'
        hoverAction = false
    @$demoArea.on 'mouseleave', '#swipe_next', ->
      hoverAction = true

    @_activateVideo(@$demoContainer, @adUnitContentType, @adUnitContentSize)
    @_activateDestinationUrl(@$demoContainer, '.ad')
    @_activateLikeShareIcons(@$demoContainer)

  _activateSingleAd: (type) ->
    $single = $(@$demoContainer).find('.single-ad')
    $single.removeClass('hide')
    @_activateVideo(@$demoContainer, @adUnitContentType, @adUnitContentSize)
    @_activateDestinationUrl(@$demoContainer, '.ad')
    @_activateLikeShareIcons(@$demoContainer)
    if type == 'single_ad_scroll'
      content = $single.find('.content_with_action')
      scrollValue = content.height()
      initTop = $single.find('.description').offset().top
      currentOffset = 0
      @$demoArea.on 'mouseenter', '#swipe_prev', ->
        currentTop = $single.find('.description').offset().top
        if initTop > currentTop
          currentOffset = currentOffset - scrollValue
          content.stop().animate({
            scrollTop: currentOffset * 0.8
          }, 600);
      @$demoArea.on 'mouseenter', '#swipe_next', ->
        currentTop = $single.find('.description').offset().top
        currentOffset = currentOffset + scrollValue
        content.stop().animate({
          scrollTop: currentOffset * 0.8
        }, 600);

  validateEmail = (email) ->
    re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    re.test email

  validatePhone = (phone) ->
    re = /^\+{0,2}([\-\. ])?(\(?\d{0,3}\))?([\-\. ])?\(?\d{0,3}\)?([\-\. ])?\d{3}([\-\. ])?\d{4}/
    re.test phone

  _validateStep: (container) ->
    container.find('.form-group').each (i, field) =>
      if $(field).hasClass('radio-input')
        if $(field).find('input[type=radio]:checked').length == 0
          $(field).addClass('has-error')
        else
          $(field).removeClass('has-error')
      else if $(field).hasClass('select-input')
        if $(field).find('select').val().length == 0
          $(field).addClass('has-error')
        else
          $(field).removeClass('has-error')
      else
        if $(field).find('input').val().length == 0
          $(field).addClass('has-error')
        else if $(field).find('input').attr('type') == 'email'
          if validateEmail($(field).find('input').val())
            $(field).removeClass('has-error')
          else
            $(field).addClass('has-error')
        else if $(field).find('input').attr('type') == 'tel'
          if validatePhone($(field).find('input').val())
            $(field).removeClass('has-error')
          else
            $(field).addClass('has-error')
        else
          $(field).removeClass('has-error')

  _validatePrivacy: (container) ->
    unless container.find('input[name="terms_conditions"]').prop('checked')
      container.find('.policy_text').addClass('has-error')
    else
      container.find('.policy_text').removeClass('has-error')

  _activateLeadGen: (ad, type) ->
    currentStep = 0
    $lead_gen = $(@$demoContainer).find('.lead-generation-ad')
    stepsCount = $lead_gen.find('.form_step').length
    $nextStepButton = $lead_gen.find('.next-step')
    $backStepButton = $lead_gen.find('.back-step')
    $closeBackStepButton = $lead_gen.find('.close-back-step')
    $submitButton = $lead_gen.find('input.submit')
    $stepsContainer = $lead_gen.find('.form_step')
    $privacyLink = $lead_gen.find('.privacy-statement')
    click_class = if ad.adType == 'video' then '.video_container' else 'img'
    $media = $lead_gen.find(click_class)

    $backStepButton.hide()
    $stepsContainer.first().addClass('active')
    $stepsContainer.last().addClass('last_step')
    if @adUnitContentSize in ['size_300x600', 'size_320x480'] || type == 'lead_gen_scroll'
      $closeBackStepButton.hide()

    if stepsCount > 1
      $privacyLink.hide()
      $submitButton.hide()

      $nextStepButton.on 'click', (e) =>
        $activeStepContainer = $($stepsContainer[currentStep])
        @_validateStep($activeStepContainer)
        if $activeStepContainer.find('.has-error').length == 0
          $activeStepContainer.removeClass('active')
          currentStep++
          $($stepsContainer[currentStep]).addClass('active')
          $backStepButton.show()
          $closeBackStepButton.hide()
          if currentStep == (stepsCount - 1)
            $nextStepButton.hide()
            $submitButton.show()
            $privacyLink.show()

      $backStepButton.on 'click', (e) =>
        $activeStepContainer = $($stepsContainer[currentStep])
        if $activeStepContainer.find('.has-error').length == 0
          $activeStepContainer.removeClass('active')
          currentStep--
          $($stepsContainer[currentStep]).addClass('active')
          $submitButton.hide()
          $nextStepButton.show()
          $privacyLink.hide()
          if currentStep == 0
            $backStepButton.hide()
            $closeBackStepButton.show() if @adUnitContentSize == 'size_300x250'
    else
      $nextStepButton.hide()

    $lead_gen.find('input.submit').on 'click', (e) =>
      event.preventDefault()
      @_validateStep($lead_gen)
      @_validatePrivacy($lead_gen)
      if $lead_gen.find('.has-error').length == 0
        $lead_gen.find('.lead-gen-form').hide()
        $lead_gen.find('.description').hide() if type == 'lead_gen_scroll'
        $lead_gen.find('.thank-area').show()
        $lead_gen.find('.content_with_action').stop().animate({
          scrollTop: 0
        }, 1000);

    if @adUnitContentSize == 'size_300x250' && type == 'lead_gen'
      $lead_gen.find('.content_with_action').on 'click', (e) =>
        $lead_gen.find('.content_with_action').hide()
        $lead_gen.find('.lead-gen-form').show()
        $lead_gen.find('.close-button').show()
        $lead_gen.find('.action').hide()
        $media.hide()
        window.activePlayer.pause() if window.activePlayer
        $lead_gen.find('#enzymic').hide()

      $lead_gen.find('.close-button').on 'click', (e) =>
        $lead_gen.find('.lead-gen-form').hide()
        $lead_gen.find('.thank-area').hide()
        $lead_gen.find('.close-button').hide()
        $lead_gen.find('.content_with_action').show()
        $lead_gen.find('.action').show()
        $media.show()
        window.activePlayer.play() if window.activePlayer
        $lead_gen.find('#enzymic').show()

      $closeBackStepButton.on 'click', (e) =>
        $lead_gen.find('.close-button').click()
    else
      $lead_gen.find('.lead-gen-form').show()
      $lead_gen.find('.action').hide()

    $lead_gen.removeClass('hide')
    @_activateVideo(@$demoContainer, @adUnitContentType, @adUnitContentSize)
    @_activateDestinationUrl(@$demoContainer, click_class)

    if type == 'lead_gen_scroll'
      @_activateLikeShareIcons(@$demoContainer)
      content = $lead_gen.find('.content_with_action')
      scrollValue = content.height()
      initTop = $lead_gen.find('.description').offset().top
      currentOffset = 0
      @$demoArea.on 'mouseenter', '#swipe_prev', ->
        currentTop = $lead_gen.find('.description').offset().top
        if initTop > currentTop
          currentOffset = currentOffset - scrollValue
          content.stop().animate({
            scrollTop: currentOffset * 0.8
          }, 1000);
      @$demoArea.on 'mouseenter', '#swipe_next', ->
        currentTop = $lead_gen.find('.description').offset().top
        currentOffset = currentOffset + scrollValue
        content.stop().animate({
          scrollTop: currentOffset * 0.8
        }, 1000);

  _increaseFieldHeight: (field) ->
    fieldHeight = switch field.type
      when 'text', 'email', 'tel', 'select'
        if field.label.length > 10 then 37 else 21
      when 'radio', 'checkbox'
        if field.label.length > 10 then 32 else 16
    fieldHeight + @$marginFieldHeight

  _activateDestinationUrl: (container, click_class) ->
    $.each $(container).find(click_class), (i, ad) ->
      destUrl = $(ad).attr('data-url')
      $(ad).on 'click', (e) =>
        window.open(destUrl) if destUrl

  _activateLikeShareIcons: (container) ->
    $(container).find('.heart-white-icon').on 'click', (e) ->
      $(this).removeClass 'heart-white-icon'
      $(this).addClass 'like-heart-icon'
    $(container).find('.social_icon').on 'click', (e) ->
      e.stopPropagation()
    unless mobileCheck()
      $(container).find('.whats-app-icon').remove()

  window.mobileCheck = ->
    check = false
    ((a) ->
      if /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a) or /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4))
        check = true
      return
    ) navigator.userAgent or navigator.vendor or window.opera
    check

  window.isScrolledIntoView = (elem) ->
    docViewTop = $(window).scrollTop()
    docViewBottom = docViewTop + $(window).height()
    elemTop = $(elem).offset().top
    elemBottom = elemTop + $(elem).height()
    elemBottom <= docViewBottom and elemTop >= docViewTop

  window.isElementIntoView = (elem, parent) ->
    elemCoords = elem[0].getBoundingClientRect()
    parentCoords = elem.closest('.carousel-ad').parent()[0].getBoundingClientRect()
    elemCoords.right <= (parentCoords.right + 1) and elemCoords.bottom <= (parentCoords.bottom + 1)

  customizeVideo = (video, ad, contentType, contentSize) ->
    if video.length > 0
      if contentType in ['carousel_overlay', 'single_ad', 'lead_gen'] and (contentSize == 'size_300x600' or contentSize == 'size_970x250' or contentSize == 'size_320x480')
        video.css 'width': 'auto'
    if contentType == 'carousel_overlay'
      ad.find('.content_with_action').hide()
      ad.find('.content_without_action').hide()
      ad.find('.action').addClass 'top_right'
      ad.find('.gradient').hide()

  uncustomizeVideo = (ad, contentType) ->
    if contentType == 'carousel_overlay'
      if window.activePlayer
        not_active_ad = $(window.activePlayer.getContainer()).closest('.ad')
      if window.activeIosPlayer
        not_active_ad = $(window.activeIosPlayer).closest('.ad')
      not_active_ad.find('.content_with_action').show()
      not_active_ad.find('.content_without_action').show()
      not_active_ad.find('.action').removeClass 'top_right'
      not_active_ad.find('.gradient').show()

  _activateVideo: (container, adUnitContentType, adUnitContentSize) ->
    iOS = /iPad|iPhone|iPod/.test(navigator.userAgent) and !window.MSStream
    if iOS
      @_activateIosVideo(container, adUnitContentType, adUnitContentSize)
    else
      @_activatePlyrVideo(container, adUnitContentType, adUnitContentSize)

  _activateIosVideo: (container, adUnitContentType, adUnitContentSize) ->
    players = document.querySelectorAll('.ad:not(.slick-cloned) .js-player')
    $ytContainers = $(players).find("div[data-type='youtube']")

    createPlayer = (container, videoId) ->
      new (YT.Player)(container,
        videoId: videoId
        events:
          'onReady': onPlayerReady
          'onStateChange': onPlayerStateChange
        playerVars:
          controls: 1
          showinfo: 0
          rel: 0
          autoplay: 0
          playsinline: 1
          fs: 1
          modestbranding: 1
          cc_load_policy: 0
          iv_load_policy: 3)

    onPlayerReady = (evt) ->
      player = evt.target
      $playerContainer = $(player.a).parent()
      $ad = $playerContainer.closest('.ad')
      $playerContainer.show()
      $playerContainer.parent().find('.yt_preview').hide()
      customizeVideo($playerContainer, $ad, adUnitContentType, adUnitContentSize)
      isNotCarousel = !$ad.hasClass('slick-slide')
      if isNotCarousel
        isFirstAutoplayAd = $ad.parent().find('.ad[data-autoplay="true"]').first().is($ad)
      else
        isFirstAutoplayAd = $ad.parent().find('.ad[aria-hidden="false"][data-autoplay="true"]').first().is($ad)

      if !window.activeIosPlayer and window.isScrolledIntoView($playerContainer)
        if isFirstAutoplayAd and (window.isElementIntoView(isNotCarousel or $playerContainer, $ad))
          player.playVideo()
          window.activeIosPlayer = player
          player.mute()
      else
        player.unMute()
        $ad.find('.volume_controls').removeClass('mute')
        $ad.find('.volume_controls').addClass('unmute')

      $ad.find('.volume_controls').on 'click touch', (e) ->
        e.stopPropagation()
        if $(e.target).hasClass('mute')
          player.unMute()
          $(e.target).removeClass 'mute'
          $(e.target).addClass 'unmute'
        else
          player.mute()
          $(e.target).removeClass 'unmute'
          $(e.target).addClass 'mute'

    onPlayerStateChange = (evt) ->
      player = evt.target
      $playerContainer = $(player.a).parent()
      $ad = $playerContainer.closest('.ad')
      if evt.data == 2
        player.unMute()
        $ad.find('.volume_controls').removeClass('mute');
        $ad.find('.volume_controls').addClass('unmute');
      if evt.data == 1
        if window.activeIosPlayer and window.activeIosPlayer != player
          player.unMute()
          $ad.find('.volume_controls').removeClass('mute')
          $ad.find('.volume_controls').addClass('unmute')
          window.activeIosPlayer.pauseVideo()
          uncustomizeVideo($ad, adUnitContentType)
        window.activeIosPlayer = player
        customizeVideo($playerContainer, $ad, adUnitContentType, adUnitContentSize)

    window.onYouTubePlayerAPIReady = ->
      $.each $ytContainers, (i, playerContainer) ->
        id = $(playerContainer).parent().attr('id')
        videoId = $(playerContainer).data('video-id')
        createPlayer(playerContainer, videoId)

  _activatePlyrVideo: (container, adUnitContentType, adUnitContentSize) ->
    $(container).find('.player_icons').remove()
    players = document.querySelectorAll('.ad:not(.slick-cloned) .js-player')
    plyr.setup(players)
    $.each $(players), (i, playerContainer) ->
      if plyr.supported("video").full == false
        $(playerContainer).show()
        $(playerContainer).parent().find('.yt_preview').hide()
      playerContainer.addEventListener 'ready', (event) ->
        player = event.detail.plyr
        playerContainer = $(player.getContainer()).parent()
        videoContainer = playerContainer.closest('.video_container')
        ytPreviewContainer = $(playerContainer).parent().find('.yt_preview')
        controlsContainer = $(playerContainer).find('.plyr__controls')
        video = $(playerContainer).find('.js-player')
        ad = $(playerContainer).closest('.ad')
        firstVolumeOn = true

        playerContainer.show()
        controlsContainer.hide()
        ytPreviewContainer.hide() if ytPreviewContainer.length > 0

        isNotCarousel = !ad.hasClass('slick-slide')
        if isNotCarousel
          isFirstAutoplayAd = ad.parent().find('.ad[data-autoplay="true"]').first().is(ad)
        else
          isFirstAutoplayAd = ad.parent().find('.ad[aria-hidden="false"][data-autoplay="true"]').first().is(ad)
        if !window.activePlayer and window.isScrolledIntoView(videoContainer)
          if isFirstAutoplayAd and (isNotCarousel or window.isElementIntoView(videoContainer, ad))
            player.play()
            player.setVolume(0)
            window.activePlayer = player
            customizeVideo(playerContainer, ad, adUnitContentType, adUnitContentSize)
        else
          player.setVolume(100)

        $(playerContainer).on 'click touch', (e) =>
          e.stopPropagation()

          if (!$(e.originalEvent.path[3]).hasClass('plyr__controls') && firstVolumeOn)
            player.setVolume(100)
            firstVolumeOn = false

          if window.activePlayer && window.activePlayer != player
            window.activePlayer.pause()
            uncustomizeVideo(ad, adUnitContentType)

          customizeVideo(playerContainer, ad, adUnitContentType, adUnitContentSize)

          if (window.mobileCheck() == true)
            if (controlsContainer.is(':visible'))
              controlsContainer.hide()
            else
              controlsContainer.show()

          window.activePlayer = player

        ad.mouseenter ->
          controlsContainer.show()
        ad.mouseleave ->
          controlsContainer.hide()

  _renderAd: (ad) ->
    $(@$demoContainer).find('.ads-set').append(@_htmlAdTemplate(ad))

  _htmlAdTemplate: (ad) ->
    if ad.description.length > 0
      desc =
        "
        <div class='exit title_with_desc' id='exit#{ad.id + 1}''>#{ad.title}</div>
        <div class='description' id='exi#{ad.id + 1}''>#{ad.description}</div>
        "
    else
      desc = "<div class='exit' id='exit#{ad.id + 1}''>#{ad.title}</div>"

    if ad.actionText.length > 0
      style = "background-color: #{ad.actionColor};"
      style = if ad.actionColor == '#ffffff' then style += "border: 1px solid #b0b0b0;" else style += "color: white; font-weight: bold;"

    overlap_class =
      if ad.overlap_type == 'shade'
        'shade'
      else if ad.overlap_type == 'transparent'
        'transparent'

    if ad.adType == 'video'
      if ad.ytUid?
        mediaContainer = "
                  <div class='video_container video-yt #{overlap_class}'>
                    <img src='#{ad.imageVideoSrc}' class='yt_preview'/>
                    <div class='js-player' style='display:none;'>
                      <div data-type='youtube' data-video-id='#{ad.ytUid}'></div>
                    </div>
                  </div>"
      else if ad.infiniUid?
        mediaContainer = "
                  <div class='video_container video-infini #{overlap_class}'>
                    <iframe class='infini-player' allowfullscreen='true' width='298' height='167' frameBorder='0' src='#{ad.infiniUid}'></iframe>
                  </div>"
      else if ad.youkuUid?
        mediaContainer = "
                  <div class='video_container video-youku #{overlap_class}'>
                    <iframe class='youku-player' allowfullscreen='true' width='298' height='167' frameBorder='0' src='#{ad.youkuUid}'></iframe>
                  </div>"
      else
        mediaContainer = "
                  <div class='video_container video-file #{overlap_class}'>
                    <video class='js-player' controls='' poster='#{ad.imageVideoSrc}'>
                      <source src='#{ad.videoSrc}' type='video/mp4'>
                  </div>"
      videoIcons = "
                <div class='player_icons'>
                  <div class='volume_controls mute'></div>
                </div>
               "

    likeShareIcons = ''
    if ad.includeLikeShare
      twitter_link = "https://twitter.com/intent/tweet?text=#{escape(ad.title)} - #{escape(ad.description)} – #{escape(ad.short_url)}"
      fb_link = "https://www.facebook.com/login.php?skip_api_login=1&api_key=966242223397117&signed_next=1&next=https%3A%2F%2Fwww.facebook.com%2Fsharer.php%3Fu%3D#{escape(ad.short_url)}%26description%3D#{escape(ad.description)}&cancel_url=https%3A%2F%2Fwww.facebook.com%2Fdialog%2Freturn%2Fclose%3Ferror_code%3D4201%26error_message%3DUser%2Bcanceled%2Bthe%2BDialog%2Bflow%23_%3D_&display=popup&locale=en_GB"
      linked_link = "https://www.linkedin.com/shareArticle?mini=true&title=#{escape(ad.title)}&url=#{escape(ad.short_url)}&summary=#{escape(ad.description)}"
      whats_app_link = "whatsapp://send?text=#{escape(ad.title)} - #{escape(ad.description)} - #{escape(ad.short_url)}"
      email_link = "mailto:?subject=#{escape(ad.title)}&body=#{escape(ad.title)} - #{escape(ad.description)} - #{escape(ad.short_url)}"
      likeShareIcons = "
                        <div class='like_share_icons'>
                          <a class='social_icon heart-white-icon'></a>
                          <div class='share_icons'>
                            <a class='social_icon tw-icon' href='#{twitter_link}' target='_blank'></a>
                            <a class='social_icon fb-icon' href='#{fb_link}' target='_blank'></a>
                            <a class='social_icon linked-icon' href='#{linked_link}' target='_blank'></a>
                            <a class='social_icon whats-app-icon' href='#{whats_app_link}' target='_blank'></a>
                            <a class='social_icon email-icon' href='#{email_link}' target='_blank'></a>
                          </div>
                        </div>
                      "

    switch @adUnitContentType
      when 'list'
        if ad.description.length > 0
          desc = "<div class='vertical_middle'>
                    <div class='exit title_with_desc' id='exit#{ad.id + 1}''>#{ad.title}</div>
                    <div class='description' id='exi#{ad.id + 1}''>#{ad.description}</div>
                  </div>
                 "
        else if ad.actionText.length > 0
          desc = "<div class='exit title_with_action' id='exit#{ad.id + 1}''>#{ad.title}</div>
                  <div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>"
        else
          desc = "<div class='exit vertical_middle' id='exit#{ad.id + 1}''>#{ad.title}</div>"

        "<a href='#{ad.destinationUrl}' target='_blank' class='ad' id='ad#{ad.id + 1}'>
          <img src='#{ad.imageListSrc}' />" + desc + "</a>"
      when 'carousel'
        desc_style = if ad.title.length <= @carouselTitleOneLineLimit then 'max-height: 3.6em;' else ''
        if ad.actionText.length > 0
          desc =
            "
            <div class='content_with_action'>
              <div class='exit' id='exit#{ad.id + 1}''>#{ad.title}</div>
            </div>
            <div class='description with_action' id='exi#{ad.id + 1}' style='#{desc_style}'>#{ad.description}</div>
            <div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>
            "

        if ad.adType == 'image'
          mediaContainer = "<img src='#{ad.imageCarouselSrc}'/>"
          videoIcons = ''

        "<div class='ad' data-url='#{ad.destinationUrl}' data-autoplay='#{ad.autoplay}'>" + mediaContainer + likeShareIcons + videoIcons + desc + "</div>"
      when 'carousel_overlay'
        content_class = if ad.actionText.length > 0 then 'content_with_action' else 'content_without_action'
        desc =
          "
          <div class='#{content_class}'>
            <div class='exit' id='exit#{ad.id + 1}''>#{ad.title}</div>
            <div class='description with_action' id='exi#{ad.id + 1}''>#{ad.description}</div>
          </div>"

        desc += "<div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>" if ad.actionText.length > 0
        desc = '' if ad.image_only == 'true'

        if ad.adType == 'image'
          mediaContainer = "<img class='#{overlap_class}' src='#{ad.image300x250Src}'/>"
          videoIcons = ''
        if ad.overlap_type == 'gradient'
          mediaContainer += "<div class='gradient'></div>"

        "<div class='ad' data-url='#{ad.destinationUrl}' id='ad#{ad.id + 1}' data-autoplay='#{ad.autoplay}'>" + mediaContainer + likeShareIcons + videoIcons + desc + "</div>"
      when 'single_ad', 'single_ad_scroll'
        if ad.actionText.length > 0
          desc = "<div class='description' id='exi#{ad.id + 1}''>#{ad.description}</div>" if ad.infiniUid
          content_style = if ad.infiniUid then 'without_title' else ''

          if @adUnitContentType == 'single_ad_scroll'
            desc =
              "
                <div class='content_with_action #{content_style}'>"+desc+"
                <div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div></div>
              "
          else
            desc =
              "
                <div class='content_with_action #{content_style}'>"+desc+"</div>
                <div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>
              "

        if ad.adType == 'image'
          mediaContainer = "<img src='#{@_singleAdImageSrc(ad)}'/>"
          videoIcons = ''

        "
        <div class='ad' data-url='#{ad.destinationUrl}' id='ad#{ad.id + 1}' data-autoplay='#{ad.autoplay}'>" + mediaContainer + likeShareIcons + videoIcons + desc + "</div>"
      when 'lead_gen'
        switch @adUnitContentSize
          when 'size_300x600'
            ad_image_src = ad.image300x150Src
            leadFormStepHeigth = 230
            leadFormLastStepHeight = 185
            fieldsLimit = 6
            submitButton = if ad.actionText.length > 0 then ad.actionText else 'Submit'
          when 'size_320x480'
            ad_image_src = ad.image300x150Src
            leadFormStepHeigth = 144
            leadFormLastStepHeight = 112
            fieldsLimit = 4
            submitButton = if ad.actionText.length > 0 then ad.actionText else 'Submit'
          when 'size_300x250'
            ad_image_src = ad.image300x150Src
            leadFormStepHeigth = 140
            leadFormLastStepHeight = 137
            fieldsLimit = 5
            submitButton = 'Submit'
            if ad.actionText.length > 0
              desc += "<div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>"

        isLastStepFunc = (fields, i, leadFormStepHeight, currentFieldsCount, fieldsLimit) =>
          sum = 0
          $.each fields[i..fields.count], (i, f) =>
            sum += @_increaseFieldHeight(f)
          if fields.length - currentFieldsCount <= fieldsLimit && sum <= leadFormStepHeight
            true
          else
            false

        stepsHtml = []
        shouldOpenStepDiv = true
        stepHeigth = 0
        fieldsCount = 0
        currentStep = 0
        totalFieldsCount = ad.fields.length
        isLastStep = false
        $.each ad.fields, (i, field) =>
          if shouldOpenStepDiv
            stepsHtml.push("<div class='form_step' id='#{currentStep}'>")
            currentStep++
            shouldOpenStepDiv = false
            isLastStep = isLastStepFunc(ad.fields, i, leadFormStepHeigth, totalFieldsCount, fieldsLimit)
          fieldHtml = switch field.type
            when 'text', 'email', 'tel'
              "<div class='form-group text-input'>
                  <label>#{field.label}</label>
                  <input type='#{field.type}' name='#{field.name}' id='#{field.name}'>
                </div>"
            when 'radio'
              tag = "<div class='form-group radio-input'>
                <label>#{field.label}</label>
                <div class='radio-inline'>"
              $.each field.options, (i, option) ->
                tag += "<label><input name='#{field.name}' type='radio' value='#{option}'>#{option}</input></label>"
              tag += "</div></div>"
            when 'select'
              tag = "<div class='form-group select-input'>
                <label>#{field.label}</label>
                <select class='form-control' id='ad_status' name='#{field.name}'>
                 <option></option>"
              $.each field.options, (i, option) ->
                tag += "<option value='#{option}'>#{option}</option>"
              tag += "</select></div>"
            when 'checkbox'
              tag = "<div class='form-group checkbox-input'>
                <label>#{field.label}</label>
                <div class='checkbox-inline'>"
              $.each field.options, (i, option) ->
                tag += "<label><input name='#{field.name}' type='checkbox' value='#{option}'>#{option}</input></label>"
              tag += "</div></div>"

          stepsHtml.push(fieldHtml)
          lastField = totalFieldsCount == i + 1
          fieldsCount++
          stepHeigth += @_increaseFieldHeight(field)
          nextFieldHeigth = if lastField then 0 else @_increaseFieldHeight(ad.fields[i+1])
          height_limit = if isLastStep then leadFormLastStepHeight else leadFormStepHeigth
          if (stepHeigth + nextFieldHeigth) > height_limit || fieldsCount >= fieldsLimit || lastField
            stepsHtml.push("</div>")
            stepHeigth = 0
            fieldsCount = 0
            shouldOpenStepDiv = true

        formHtml = stepsHtml.join('')

        actionButtonStyle = 'min-width: 80px; padding: 4px 6px 4px 6px;' if submitButton.length > 20
        privacyHtml =
          "<div class='privacy-statement'>
            <div class='checkbox-input'>
              <div class='checkbox-inline'>
                <label><input name='terms_conditions' type='checkbox' value='agreed'></input></label>
              </div>
            </div>
            <div class='policy_text'>#{ad.privacy_link}</div>
          </div>"
        privacyHtml = '' if ad.privacy_link == ''

        if ad.adType == 'image'
          mediaContainer = "<img src='#{ad_image_src}' data-url='#{ad.destinationUrl}'/>"
          videoIcons = ''

        "
        <div class='ad' id='ad#{ad.id + 1}' data-autoplay='#{ad.autoplay}'>
          <div class='close-button'>X</div>
          " + mediaContainer + videoIcons + "
          <div class='content_with_action'>"+desc+"</div>
          <form class='lead-gen-form' name='lead-gen-form'>
            <div class='form-title'>#{ad.form_title}</div>
            " + formHtml + "
            <div class='lead_gen_buttons'>
              <a class='btn back-step submit' style='#{actionButtonStyle}'>Back</a>
              <a class='btn close-back-step submit'>Back</a>
              <a class='btn next-step submit' style='#{style}'>Next</a>
              <input type='submit' value='#{submitButton}' class='btn submit submit-step' style='#{style}#{actionButtonStyle}'>
            </div>
            " + privacyHtml + "
          </form>
          <div class='thank-area'>
            <div class='title'>#{ad.thanks_message}</div>
            <div class='sub-title'>#{ad.thanks_description}</div>
          </div>
        </div>
        "
      when 'lead_gen_scroll'
        switch @adUnitContentSize
          when 'size_300x600'
            ad_image_src = ad.image300x150Src
            leadFormStepHeigth = 230
            leadFormLastStepHeight = 185
            submitButton = if ad.actionText.length > 0 then ad.actionText else 'Submit'
          when 'size_320x480'
            ad_image_src = ad.image300x150Src
            leadFormStepHeigth = 144
            leadFormLastStepHeight = 112
            submitButton = if ad.actionText.length > 0 then ad.actionText else 'Submit'
          when 'size_300x250'
            ad_image_src = ad.image300x150Src
            leadFormStepHeigth = 140
            leadFormLastStepHeight = 137
            submitButton = if ad.actionText.length > 0 then ad.actionText else 'Submit'

        stepsHtml = []
        $.each ad.fields, (i, field) =>
          fieldHtml = switch field.type
            when 'text', 'email', 'tel'
              "<div class='form-group text-input'>
                  <label>#{field.label}</label>
                  <input type='#{field.type}' name='#{field.name}' id='#{field.name}'>
                </div>"
            when 'radio'
              tag = "<div class='form-group radio-input'>
                <label>#{field.label}</label>
                <div class='radio-inline'>"
              $.each field.options, (i, option) ->
                tag += "<label><input name='#{field.name}' type='radio' value='#{option}'>#{option}</input></label>"
              tag += "</div></div>"
            when 'select'
              tag = "<div class='form-group select-input'>
                <label>#{field.label}</label>
                <select class='form-control' id='ad_status' name='#{field.name}'>
                 <option></option>"
              $.each field.options, (i, option) ->
                tag += "<option value='#{option}'>#{option}</option>"
              tag += "</select></div>"
            when 'checkbox'
              tag = "<div class='form-group checkbox-input'>
                <label>#{field.label}</label>
                <div class='checkbox-inline'>"
              $.each field.options, (i, option) ->
                tag += "<label><input name='#{field.name}' type='checkbox' value='#{option}'>#{option}</input></label>"
              tag += "</div></div>"

          stepsHtml.push(fieldHtml)

        formHtml = stepsHtml.join('')

        actionButtonStyle = 'min-width: 80px; padding: 4px 6px 4px 6px;' if submitButton.length > 20
        privacyHtml =
          "<div class='privacy-statement'>
            <div class='checkbox-input'>
              <div class='checkbox-inline'>
                <label><input name='terms_conditions' type='checkbox' value='agreed'></input></label>
              </div>
            </div>
            <div class='policy_text'>#{ad.privacy_link}</div>
          </div>"
        privacyHtml = '' if ad.privacy_link == ''

        if ad.adType == 'image'
          mediaContainer = "<img src='#{ad_image_src}' data-url='#{ad.destinationUrl}'/>"
          videoIcons = ''

        formWithThanks =
          "
          <form class='lead-gen-form' name='lead-gen-form'>
            <div class='form-title'>#{ad.form_title}</div>
            " + formHtml + "
            <div class='lead_gen_buttons'>
              <a class='btn back-step submit' style='#{actionButtonStyle}'>Back</a>
              <a class='btn close-back-step submit'>Back</a>
              <a class='btn next-step submit' style='#{style}'>Next</a>
              <input type='submit' value='#{submitButton}' class='btn submit submit-step' style='#{style}#{actionButtonStyle}'>
            </div>
            " + privacyHtml + "
          </form>
          <div class='thank-area'>
            <div class='title'>#{ad.thanks_message}</div>
            <div class='sub-title'>#{ad.thanks_description}</div>
          </div>
          "

        if @adUnitContentType == 'lead_gen_scroll'
          desc =
            "
              <div class='content_with_action #{content_style}'>
                " + desc + formWithThanks + "
                <div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>
              </div>
            "
        else
          desc =
            "
              <div class='content_with_action #{content_style}'>"+desc+"</div>
              <div class='btn btn-default action' style='#{style}'>#{ad.actionText}</div>
            " + formWithThanks

        "
        <div class='ad' id='ad#{ad.id + 1}' data-autoplay='#{ad.autoplay}'>
          <div class='close-button'>X</div>
          " + mediaContainer + likeShareIcons + videoIcons + desc + "
        </div>
        "

  _htmlContainerTemplate: ->
    sponsoredText = $('.sponsored_label').text()
    sponsoredImageSrc = $('.sponsored_logo img').attr('src')
    is_vertical = (@adUnitContentSize in ['size_300x600', 'size_320x480'])
    switch @adUnitContentType
      when 'list'
        "
          <div class='ads-set list_ad_unit #{@adUnitContentSize}'>
            <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
            <div id='sponsored'>
              #{sponsoredText}
              <img src='#{sponsoredImageSrc}'/>
            </div>
          </div>
        "
      when 'carousel'
        "
        <div class='carousel_ad_unit #{@adUnitContentSize}'>
          <div class='carousel-ad ads-set'>
          </div>
          <div id='sponsored'>
            #{sponsoredText}
            <img src='#{sponsoredImageSrc}'/>
          </div>
          <div id='swipe_prev'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                  <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                  <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <div id='swipe_next'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
        </div>
        "
      when 'carousel_overlay'
        "
        <div class='carousel_overlay_ad_unit #{@adUnitContentSize}'>
          <div class='carousel-ad ads-set'>
          </div>
          <div id='sponsored'>
            <img src='#{sponsoredImageSrc}' />
          </div>
          <div id='swipe_prev'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                  <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                  <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <div id='swipe_next'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
        </div>
        "
      when 'single_ad'
        sponsored_text = ''
        unless @adUnitContentSize == 'size_300x250'
          sponsored_text = "<span id='sponsored_text'>#{sponsoredText}</span>"
        "
        <div class='single_ad_unit #{@adUnitContentSize}'>
          <div class='single-ad ads-set'>
          </div>
          <div id='sponsored'>
            " + sponsored_text + "
            <img src='#{sponsoredImageSrc}' />
          </div>
          <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
        </div>
        "
      when 'lead_gen'
        "
        <div class='lead_gen_ad_unit #{@adUnitContentSize}'>
          <div class='lead-generation-ad ads-set'>
          </div>
          <div id='sponsored'>
            <img src='#{sponsoredImageSrc}' />
          </div>
          <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
        </div>
        "
      when 'single_ad_scroll'
        sponsored_text = ''
        unless @adUnitContentSize == 'size_300x250'
          sponsored_text = "<span id='sponsored_text'>#{sponsoredText}</span>"
        "
        <div class='single_ad_unit_scroll #{@adUnitContentSize}'>
          <div class='single-ad ads-set'>
          </div>
          <div id='sponsored'>
            " + sponsored_text + "
            <img src='#{sponsoredImageSrc}' />
          </div>
          <div id='swipe_prev'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                  <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                  <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <div id='swipe_next'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
        </div>
        "
      when 'lead_gen_scroll'
        "
        <div class='lead_gen_ad_unit_scroll #{@adUnitContentSize}'>
          <div class='lead-generation-ad ads-set'>
          </div>
          <div id='sponsored'>
            <img src='#{sponsoredImageSrc}' />
          </div>
          <div id='swipe_prev'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                  <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                  <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <div id='swipe_next'>
            <div class='arrow'>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid' width='30' height='30' viewBox='0 0 30 30'>
                <g id='arrowsvg'>
                <rect id='rect-1' width='30' height='30' style='fill-opacity: 0;'/>
                <path d='M20.071,15.000 C20.071,15.000 17.950,17.121 17.950,17.121 C17.950,17.121 17.950,17.121 17.950,17.121 C17.950,17.121 13.000,22.071 13.000,22.071 C13.000,22.071 10.879,19.950 10.879,19.950 C10.879,19.950 15.828,15.000 15.828,15.000 C15.828,15.000 10.879,10.050 10.879,10.050 C10.879,10.050 13.000,7.929 13.000,7.929 C13.000,7.929 17.950,12.879 17.950,12.879 C17.950,12.879 17.950,12.879 17.950,12.879 C17.950,12.879 20.071,15.000 20.071,15.000 Z' id='path-1' class='cls-4' fill-rule='evenodd' style='fill: #ffffff;'/>
                </g>
              </svg>
            </div>
          </div>
          <a href='http://adzymic.co/' target='_blank'><div id='enzymic'></div></a>
        </div>
        "

  _shuffle: (a) ->
    i = a.length
    while --i > 0
      j = ~~(Math.random() * (i + 1))
      t = a[j]
      a[j] = a[i]
      a[i] = t
    a

$ ->
  $demoContainer = $('.demo-container')

  tag = document.createElement('script')
  tag.src = 'https://www.youtube.com/player_api'
  firstScriptTag = document.getElementsByTagName('script')[0]
  firstScriptTag.parentNode.insertBefore tag, firstScriptTag

  $.each $demoContainer, (index, demo_container) ->
    unless window.demoAreas
      window.demoAreas = []
    window.demoAreas.push(new Enzymic.AdUnits.DemoArea(demo_container))

