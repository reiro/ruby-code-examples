class Enzymic.AdUnits.DoubleClickTag
  constructor: ->
    @$publishLink = $('.publish_ad_unit')
    @publishModal = '#publish_tag_modal'
    @publishProcessingMessage = @$publishLink.data('publishingMessage')
    @publishFailedMessage = @$publishLink.data('publishFailed')
    @adUnitSequence = $('[data-sequence]').data('sequence')
    @_remotePublish()
    @_sortableAds() if @adUnitSequence

  _sortableAds: ->
    $('.ads_list').sortable({
      revert: true
    })
    $('.ads_list').on 'sortupdate', (event, ui) ->
      data = { sequence_ids: $(this).sortable('toArray', { attribute: 'ad-id' }) }
      url = window.location.href + '/update_sequence'
      $.ajax({
        type: "POST",
        url: url,
        data: data
      })

  _remotePublish: ->
    @$publishLink.on 'click', (e) =>
      if !@$publishLink.hasClass('disabled')
        that = $(e.currentTarget)
        publishMessage = $(that).text()
        url = $(that).attr('href')
        $.get(url, (data) =>
          $(@publishModal).remove() if $(@publishModal)
          $(that).html(publishMessage)
          $('body').append(data)
          @_preparePublishModal()
        ).fail( =>
          $(that).text(@publishFailedMessage)
        ).always ->
          $(that).removeClass('disabled')

        $(that).addClass('disabled')
        $(that).html(@publishProcessingMessage)

      return false

  _preparePublishModal: ->
    $(@publishModal).modal({
      show: true
    })

    $('.ads_list #ready_to_publish').each (index, ad) =>
      $ad = $(ad)
      $adStatus = $ad.find('.ready_to_publish')
      $adStatus.html('Status: Published')
      $adStatus.addClass('published').removeClass('ready_to_publish')

    @_createIframe()
    $('.default_image a').on 'click', (e) =>
      size = $(e.currentTarget).attr('data-size')
      ad_unit = $(e.currentTarget).attr('data-ad-unit')
      @_createImage(size, ad_unit)
    $(@publishModal).on "hidden.bs.modal", (e) =>
      $('iframe.default_ad').remove()

  _createIframe: ->
    i = document.createElement("iframe")
    i.className = "default_ad"
    i.src =  window.location.origin + $('.preview_button').attr('data-src') + "/default_ad"
    i.style.display = "none";
    document.body.appendChild(i)

  _createImage: (size, ad_unit) ->
    $iframe = $('iframe.default_ad').contents().find('body').find(".demo-area .size_" + size)
    html2canvas $iframe, onrendered: (canvas) ->
      a = document.createElement('a')
      a.href = canvas.toDataURL('image/jpeg').replace('image/jpeg', 'image/octet-stream')
      a.download = ad_unit + '_' + size + '.jpg'
      a.click()
      $(a).remove()

$ ->
  new Enzymic.AdUnits.DoubleClickTag()
  $unusedSizes = [$('.carousel_content_sizes #ad_unit_sizes_1')]
  $unusedSizes.push($('.carousel_content_sizes #ad_unit_sizes_3'))
  $ampInput = $('#ad_unit_amp')

  disableSizes = (sizes) ->
    $.each sizes, (i, e) ->
      $(e).prop('disabled', true)
      $(e).prop('checked', false)

  disableAmp = () ->
    $ampInput.prop('disabled', true)
    $ampInput.prop('checked', false)

  disableSizes($unusedSizes) if $ampInput.prop('checked')

  $(document).ready ->
    $('.checkbox_inline.hidden').find('input:checkbox').prop('checked', false)

  $('.ad_unit_content_type input').click (e) ->
    $('.content_sizes').remove()
    sponsored_logo_help_message = $('#sponsored_logo_help_message')
    sponsored_logo_input = $('#ad_unit_sponsored_label')
    sponsored_logo_label = $(sponsored_logo_input).parent().parent()
    sequence_input = $('#ad_unit_sequence')
    amp_input = $('#ad_unit_amp')
    sequence_label = $(sequence_input).parent().parent()
    prev_sizes = $('.list_content_sizes, .carousel_content_sizes, .carousel_overlay_content_sizes, .single_ad_content_sizes, .lead_gen_content_sizes, .single_ad_scroll_content_sizes, .lead_gen_scroll_content_sizes')
    if $(e.target).attr('value') == 'list'
      prev_sizes.splice(0, 1)
      sizes = $('.list_content_sizes')
      sponsored_logo_help_message.hide()
      sponsored_logo_label.show()
      sponsored_logo_input.prop('disabled', false)
      sequence_input.prop('disabled', true)
      disableAmp()
    else if $(e.target).attr('value') == 'carousel'
      prev_sizes.splice(1, 1)
      sizes = $('.carousel_content_sizes')
      sponsored_logo_help_message.hide()
      sponsored_logo_label.show()
      sponsored_logo_input.prop('disabled', false)
      sequence_input.prop('disabled', false)
      sequence_input.closest('.checkbox').removeClass('disabled')
      $ampInput.prop('disabled', false)
      $ampInput.closest('.checkbox').removeClass('disabled')
    else if $(e.target).attr('value') == 'carousel_overlay'
      prev_sizes.splice(2, 1)
      sizes = $('.carousel_overlay_content_sizes')
      sponsored_logo_help_message.hide()
      sponsored_logo_label.hide()
      sponsored_logo_input.prop('disabled', true)
      sequence_input.prop('disabled', false)
      disableAmp()
    else if $(e.target).attr('value') == 'single_ad'
      prev_sizes.splice(3, 1)
      sizes = $('.single_ad_content_sizes')
      sponsored_logo_help_message.show()
      sponsored_logo_label.show()
      sponsored_logo_input.prop('disabled', false)
      sequence_input.prop('disabled', true)
      disableAmp()
    else if $(e.target).attr('value') == 'lead_gen'
      prev_sizes.splice(4, 1)
      sizes = $('.lead_gen_content_sizes')
      sponsored_logo_help_message.show()
      sponsored_logo_label.show()
      sponsored_logo_input.prop('disabled', false)
      sequence_input.prop('disabled', true)
      disableAmp()
    else if $(e.target).attr('value') == 'single_ad_scroll'
      prev_sizes.splice(5, 1)
      sizes = $('.single_ad_scroll_content_sizes')
      sponsored_logo_help_message.show()
      sponsored_logo_label.show()
      sponsored_logo_input.prop('disabled', false)
      sequence_input.prop('disabled', true)
      disableAmp()
    else if $(e.target).attr('value') == 'lead_gen_scroll'
      prev_sizes.splice(6, 1)
      sizes = $('.lead_gen_scroll_content_sizes')
      sponsored_logo_help_message.show()
      sponsored_logo_label.show()
      sponsored_logo_input.prop('disabled', false)
      sequence_input.prop('disabled', true)
      disableAmp()

    prev_sizes.find('input:checkbox').prop('checked', false)
    prev_sizes.addClass('hidden')
    sizes.removeClass('hidden')

  $ampInput.on 'change', (e) =>
    if $(e.target).prop('checked')
      disableSizes($unusedSizes)
    else
      $.each $unusedSizes, (i, e) ->
        $(e).prop('disabled', false)

  $('#ad_unit_auto_optimization').on 'change', (e) =>
    $('#ad_unit_sequence').prop('checked', false)

  $('#ad_unit_sequence').on 'change', (e) =>
    $('#ad_unit_auto_optimization').prop('checked', false)
