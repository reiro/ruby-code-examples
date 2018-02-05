class Enzymic.Ads.AdFormHandler
  constructor: (adFormId) ->
    new Enzymic.Shared.ThemeInitials()._formControlInitials()
    @adFormId = adFormId

    if adFormId == 'new_ad'
      @$form = $("##{adFormId}")
      @$oldContent = @$form.parent().find('#link_to_create_new_ad')
    else
      @$form = $("#edit_ad_#{adFormId}")
      @$oldContent = $("#ad_#{adFormId}")

    @$titleLimits = [55, 40, 30, 90, 80]
    @$descriptionLimits = [180, 90, 125]
    @$actionTextLimits = [25, 10, 24]
    @$fieldLabelInputLimit = 40

    @$x = @$form.find("[name='ad[x]']")
    @$y = @$form.find("[name='ad[y]']")
    @$width = @$form.find("[name='ad[width]']")
    @$height = @$form.find("[name='ad[height]']")

    @$uploadImageContainer = @$form.find('.ad-upload-image')
    @$imageUploadPreviewContainer = @$uploadImageContainer.find('.image-preview')
    @$fetchImageContainer = @$form.find('.ad-fetch-image')
    @$destinationUrlField = @$form.find("input[name='ad[destination_url]']")
    @$fetchImageRadioButton = @$form.find("input[value='fetch_image']")
    @$uploadImageRadioButton = @$form.find("input[value='upload_image']")
    @$imageUploadInput = @$form.find("input[name='ad[image]']")
    @$remoteImageUrl = @$form.find("input[name='ad[remote_image_url]']")
    @$cropImageButton = @$form.find('.crop-image-button')
    @$adTitleField = @$form.find("[name='ad[title]']")
    @$titleCheckboxField = @$form.find("input[name='ad[has_title]']")
    @$fetchingIcon = @$adTitleField.parent().find('i.fetching-icon')
    @$validationIcon = @$destinationUrlField.parent().find('i.validation-icon')
    @$descriptionCheckboxField = @$form.find("input[name='ad[has_description]']")
    @$descriptionField = @$form.find("input[name='ad[description]']")
    @$actionCheckboxField = @$form.find("input[name='ad[has_action]']")
    @$actionTextField = @$form.find("input[name='ad[action_text]']")
    @$actionButtonColor = @$form.find("input[name='ad[button_color]']")
    @$selectColor = @$form.find("select[name='default_color']")
    @$adUnitContentType = $('[data-content-type]').data('content-type')
    @$adContentType = $('#ad_content_type')
    @$imageAdContainer = $('#image_ad')
    @$fetchVideoContainer = @$form.find('.ad-fetch-video')
    @$fetchInfiniVideoContainer = @$form.find('.ad-fetch-infini-video')
    @$fetchYoukuVideoContainer = @$form.find('.ad-fetch-youku-video')
    @$uploadVideoContainer = @$form.find('.ad-upload-video')
    @$adVideoLinkField = @$form.find('#ad_video_attributes_link')
    @$adVideoFileField = @$form.find('#ad_video_attributes_video')
    @$videoAdContainer = $('#video_ad')
    @$fetchTitlePrefix = if window.location.pathname.includes('administrator') then '/administrator' else ''
    @$videoTypeYoutubeField = $('#ad_video_attributes_video_type_youtube')
    @$videoTypeInfiniField = $('#ad_video_attributes_video_type_infini')
    @$videoTypeYoukuField = $('#ad_video_attributes_video_type_youku')
    @$videoTypeFileField = $('#ad_video_attributes_video_type_file')
    @$videoInputMessage = $('#video-input-message')
    @$lead_gen_form = @$form.find('#lead_gen_form')
    @$leadFormCustomFields = $('#lead_form_custom_fields')
    @$optionsContainer = $('.options_container')
    @$formTitleField = @$lead_gen_form.find("[name='ad[lead_form_attributes][form_title]']")
    @$privacyLinkField = @$lead_gen_form.find("[name='ad[lead_form_attributes][privacy_link]']")
    @$imageOnlyField = @$form.find('#ad_image_only')
    @$zapierLeadCheckbox = @$form.find('#ad_lead_form_attributes_zapier')
    @$adzymicLeadCheckbox = @$form.find('#ad_lead_form_attributes_adzymic')
    @$zapierWebhookField = @$form.find('#ad_lead_form_attributes_zapier_webhook')
    @$zapierConfirmationLink = @$form.find('.zapier_confirmation')

    @isScrollType = @$adUnitContentType in ['single_ad_scroll', 'lead_gen_scroll']
    @isLeadGenType = @$adUnitContentType in ['lead_gen', 'lead_gen_scroll']

    @_cancelBtnHandler()
    @_formSubmitHandler()
    @_formImageFieldHandler()
    @_titleCheckboxHandler()
    @_descriptionCheckboxHandler()
    @_checkDescriptionShowing() unless @isScrollType
    @_actionTextCheckboxHandler()
    @_selectColorHandler()
    @_checkActionTextShowing() unless @isScrollType
    @_countableHandlers()
    @_imageUploadSelectorHandler(@$form)
    @_destinationUrlHandler()
    @_toggleImageUploadSelector()
    new Enzymic.Ads.FetchImages(@$form)

    if @$adUnitContentType in ['carousel', 'carousel_overlay', 'single_ad', 'lead_gen', 'single_ad_scroll', 'lead_gen_scroll']
      @_videoUploadSelectorHandler(@$form)
      @_validateVideoHandler()
      @_contentTypeSelectHandler()
      new Enzymic.Ads.FetchVideo(@$form)
      @_contentTypeSelectChange()
      @_activateVideo()
    if @isLeadGenType
      @_leadFormCheckboxesHandler()
      @_addCustomFieldhandler()
      @_removeCustomFieldHandler(@$leadFormCustomFields)
      @_addOptionHandler(@$leadFormCustomFields)
      @_removeOptionHandler(@$optionsContainer)
      @_customFieldsTypeInitHandler()
      @_customFieldsTypeHandler(@$leadFormCustomFields)
      @_addOptionHideShow(@$leadFormCustomFields)
      @_fieldsValidation()
      @_zapierWebhookHandler()
      @_zapierConfirmationLink()
    if @$adUnitContentType == 'carousel_overlay'
      @_imageOnlyHandler()
      @_imageOnlyDisabled(@$imageOnlyField.is(':checked'))
      @_checkTitleShowing()
    if @isScrollType
      @_setLimits(@$descriptionCheckboxField.is(':checked'), @$actionCheckboxField.is(':checked'))
      @_updateHelpBlock(@$adTitleField[0])
      @_updateHelpBlock(@$actionTextField[0])

  _imageOnlyHandler: () ->
    @$imageOnlyField.on 'change', (e) =>
      @_imageOnlyDisabled(@$imageOnlyField.is(':checked'))

  _imageOnlyDisabled: (bool) ->
    @$adTitleField.prop('disabled', bool)
    @$titleCheckboxField.prop('disabled', bool)
    @$descriptionCheckboxField.prop('disabled', bool)
    @$descriptionField.prop('disabled', bool)
    @$actionCheckboxField.prop('disabled', bool)
    @$actionTextField.prop('disabled', bool)

    @$titleCheckboxField.closest('.form-group').toggle(!bool)
    @$descriptionCheckboxField.closest('.form-group').toggle(!bool)
    @$actionCheckboxField.closest('.checkbox').toggle(!bool)

    if bool
      @$titleCheckboxField.prop('checked', !bool)
      @$descriptionCheckboxField.prop('checked', !bool)
      @$actionCheckboxField.prop('checked', !bool)

    @_checkDescriptionShowing()
    @_checkActionTextShowing()

  _fieldsValidation: () ->
    @$formTitleField[0].dataset.maxLength = 70
    @_updateHelpBlock(@$formTitleField[0])
    @_updatePrivacyLinkHelpMessage()

    @$privacyLinkField.on 'input', () =>
      @_updatePrivacyLinkHelpMessage()

    @$lead_gen_form.find('.label_input').each (i, label) =>
      label.dataset.maxLength = @$fieldLabelInputLimit
      @_validateFieldLabel(label)

  _optionsValidation: () ->
    @$leadFormCustomFields.find('.options_container:visible').each (i, container) ->
      option = $(container).find('.lead_form_option')
      isEmptyOption = false
      option.find('input').each (i, option) ->
        isEmptyOption = true if $(option).val().length == 0

      if option.length == 0 || isEmptyOption
        $(container).find('.validate-block').show()
        $(container).addClass('has-error')
      else
        $(container).removeClass('has-error')

  _impTrackerValidation: () ->
    $impTracker = @$form.find('#ad_impression_tracker')
    imp = $impTracker.val()
    formGroup = $impTracker.closest('.form-group')
    if imp.length > 0
      if imp.indexOf("<IMG SRC=") > -1
        formGroup.removeClass('has-error')
      else
        formGroup.addClass('has-error')

  _updatePrivacyLinkHelpMessage: () ->
    strippedPrivacyLength = @$privacyLinkField.val().replace(/(<([^>]+)>)/ig,"").length
    formGroup = @$privacyLinkField.closest('.form-group')
    formGroup.find('.help-block').text(strippedPrivacyLength + '/' + 125)
    if strippedPrivacyLength <= 125
      formGroup.removeClass('has-error')
    else
      formGroup.addClass('has-error')

  _validateFieldLabel: (input) ->
    @_countable(input)

  _addCustomFieldhandler: () ->
    fieldIndex = 0
    $('#add_custom_field').hide() if @$leadFormCustomFields.find('.form-group').size() > 2
    $('#add_custom_field').on 'click', (e) =>
      @_addCustomField(fieldIndex)
      $('#add_custom_field').hide() if @$leadFormCustomFields.find('.form-group').size() > 2
      fieldIndex += 1

  _customFieldsTypeInitHandler: () ->
    $.each @$leadFormCustomFields.find('.type_input'), (i, select) ->
      type = $(select).attr('data-type')
      $(select).find("option[value='#{type}']").prop('selected', true)

  _customFieldsTypeHandler: (container) ->
    that = @
    container.find('.type_input').change ->
      addOption = $(this).closest('.form-group').find('.options_container')
      switch $(this).val()
        when 'select', 'radio', 'checkbox'
          addOption.show()
          addOption.find('.lead_form_option').remove()
          that._addOptionHideShow($(this).closest('.form-group'))
        else
          addOption.hide()

  _addOptionHandler: (container) ->
    that = @
    container.find('.add_option').click ->
      namePrefix = 'ad[lead_form_attributes][custom_fields]'
      name = $(this).closest('.form-group').attr('id')
      optionInput =
        "<div class='lead_form_option'>
          <input class='form-control' name='#{namePrefix}[#{name}][options][]' type='text'>
          <a class='btn btn-link btn-icon'><i class='md md-delete'></i></a>
        </div>"
      $(this).before(optionInput)
      insertedOption = that.$leadFormCustomFields.find('.lead_form_option').last()
      that._removeOptionHandler(insertedOption)
      that._addOptionHideShow($(this).closest('.form-group'))
      parent = $(this).closest('.options_container')
      parent.removeClass('has-error')
      parent.find('.validate-block').hide()

  _removeOptionHandler: (container) ->
    that = @
    container.find('.md-delete').click ->
      container = $(this).closest('.form-group')
      $(this).closest('.lead_form_option').remove()
      that._addOptionHideShow($(container))

  _addOptionHideShow: (container) ->
    $.each container.find('.add_option'), (i, button) ->
      button = $(button)
      input_type = button.closest('.form-group').find('.type_input').val()
      options_count = button.closest('.options_container').find('.lead_form_option').length
      if (input_type in ['radio', 'checkbox'] && options_count > 1)
        button.hide()
        button.prop('disabled', true)
      else
        button.show()
        button.prop('disabled', false)

  _addCustomField: (index) ->
    namePrefix = 'ad[lead_form_attributes][custom_fields]'
    field = "<div class='form-group row' id='#{index}'>
        <div class='checkbox presence'>
          <input name='#{namePrefix}[#{index}][presence]' type='hidden' value='0'>
          <input class='lead_form_fields_presence' data-checked='0' name='#{namePrefix}[#{index}][presence]' type='checkbox' value='1'>
        </div>
        <input class='form-control label_input' name='#{namePrefix}[#{index}][label]' type='text' value='Field Name'>
        <select class='form-control type_input' name='#{namePrefix}[#{index}][type]' id='ad_status'>
          <option selected='selected' value='text'>Text</option>
          <option value='select'>Dropdown</option>
          <option value='radio'>Radio</option>
          <option value='checkbox'>Checkbox</option>
        </select>
        <a class='btn btn-link btn-icon remove_custom_field'><i class='md md-delete'></i></a>
        <span class='help-block'></span>
        <div class='options_container' style='display: none;'>
          <div class='btn btn-primary btn-sm add_option'>
            Add option
          </div>
          <span class='validate-block' style='display: none;'>Please, add option</span>
        </div>
        <input name='#{namePrefix}[#{index}][name]' type='hidden' value='#{index}_name'>
      </div>"
    @$leadFormCustomFields.append(field)
    insertedFormGroup = @$leadFormCustomFields.find('.form-group').last()
    insertedFormGroup.find('.lead_form_fields_presence').prop('checked', true)
    @_removeCustomFieldHandler(insertedFormGroup)
    @_customFieldsTypeHandler(insertedFormGroup)
    @_addOptionHandler(insertedFormGroup)
    insertedField = insertedFormGroup.find('.label_input')
    insertedField[0].dataset.maxLength = @$fieldLabelInputLimit
    @_validateFieldLabel(insertedField[0])

  _removeCustomFieldHandler: (container) ->
    that = @
    $(container).find('.remove_custom_field').click ->
      $(this).closest('.form-group').remove()
      $('#add_custom_field').show() if that.$leadFormCustomFields.find('.form-group').size() < 3

  _leadFormCheckboxesHandler: () ->
    $.each $('.lead_form_fields_presence'), (i, checkbox) ->
      checkbox = $(checkbox)
      if (checkbox.attr('data-checked') == '1')
        checkbox.prop('checked', true)
      else
        checkbox.prop('checked', false)

  _validateVideoHandler: ->
    inputFileSelector = document.getElementById('ad_video_attributes_video')
    selectFileMessage = 'Please choose video file'
    @$videoInputMessage.text(selectFileMessage)
    @$adVideoFileField.change ->
      $('#video-input-message').text(inputFileSelector.files[0].name)
      maxFileSize = $(inputFileSelector).data('max-file-size')
      maxExceededMessage = 'You cannot upload a file greater than 100 MB'
      extErrorMessage = 'Only video file with extension: .mp4 is allowed'
      allowedExtension = ['mp4']
      extName = undefined
      sizeExceeded = false
      extError = false
      $.each inputFileSelector.files, ->
        if @size and maxFileSize and @size > parseInt(maxFileSize)
          sizeExceeded = true
        extName = @name.split('.').pop()
        if $.inArray(extName, allowedExtension) == -1
          extError = true
        return
      if sizeExceeded
        window.alert maxExceededMessage
        $(inputFileSelector).val ''
      if extError
        window.alert extErrorMessage
        $(inputFileSelector).val ''
      return

  _titleCheckboxHandler: ->
    @$titleCheckboxField.on 'change', (e) =>
      @_checkTitleShowing()

  _checkTitleShowing: ->
    if @$titleCheckboxField.is(':checked')
      @$adTitleField.parent().parent().show()
      @$adTitleField.prop('disabled', false)
    else
      @$adTitleField.prop('disabled', true)
      @$adTitleField.parent().parent().hide()

  _descriptionCheckboxHandler: ->
    @$descriptionCheckboxField.on 'change', (e) =>
      @_checkDescriptionShowing()

  _checkDescriptionShowing: ->
    if @$descriptionCheckboxField.is(':checked')
      @$descriptionField.parent().parent().show()
      @$descriptionField.prop('disabled', false)
      if @$adUnitContentType == 'list'
        @$actionCheckboxField.prop('checked', false)
        @$actionCheckboxField.trigger('change')
    else
      @$descriptionField.prop('disabled', true)
      @$descriptionField.parent().parent().hide()
    @_setLimits(@$descriptionCheckboxField.is(':checked'), @$actionCheckboxField.is(':checked'))
    @_updateHelpBlock(@$adTitleField[0])

  _actionTextCheckboxHandler: ->
    @$actionCheckboxField.on 'change', (e) =>
      @_checkActionTextShowing()

  _checkActionTextShowing: ->
    if @$actionCheckboxField.is(':checked')
      @$actionTextField.parent().parent().show()
      @$actionButtonColor.closest('.row').show()
      @$actionTextField.prop('disabled', false)
      if @$adUnitContentType == 'list'
        @$descriptionCheckboxField.prop('checked', false)
        @$descriptionCheckboxField.trigger('change')
    else
      @$actionTextField.prop('disabled', true)
      @$actionTextField.parent().parent().hide()
      @$actionButtonColor.closest('.row').hide()
    @_setLimits(@$descriptionCheckboxField.is(':checked'), @$actionCheckboxField.is(':checked'))
    @_updateHelpBlock(@$adTitleField[0])
    @_updateHelpBlock(@$descriptionField[0])
    @_updateHelpBlock(@$actionTextField[0])

  _selectColorHandler: ->
    @$selectColor.on 'change', (e) =>
      @$actionButtonColor.val(@$selectColor.val())

  _contentTypeSelectHandler: ->
    @$adContentType.on 'change', (e) =>
      @_contentTypeSelectChange()

  _contentTypeSelectChange: ->
    if (@$adContentType.val() == 'image')
      @$imageAdContainer.removeClass('hidden')
      @$videoAdContainer.addClass('hidden')
    else
      @$imageAdContainer.addClass('hidden')
      @$videoAdContainer.removeClass('hidden')
      if (@$videoTypeFileField.is(':checked'))
        @_switchToUploadVideoContainer()
      else if (@$videoTypeInfiniField.is(':checked'))
        @_switchToFetchInfiniVideoContainer()
      else if (@$videoTypeYoukuField.is(':checked'))
        @_switchToFetchYoukuVideoContainer()
      else
        @_switchToFetchVideoContainer()

  _setLimits: (description, action) ->
    switch @$adUnitContentType
      when 'list'
        @$adTitleField[0].dataset.maxLength = if description then @$titleLimits[2] else @$titleLimits[0]
        @$descriptionField[0].dataset.maxLength = @$descriptionLimits[1]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[0]
      when 'carousel'
        @$adTitleField[0].dataset.maxLength = if description then @$titleLimits[0] else @$titleLimits[3]
        @$descriptionField[0].dataset.maxLength = if action  then @$descriptionLimits[1] else @$descriptionLimits[2]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[0]
      when 'carousel_overlay'
        @$adTitleField[0].dataset.maxLength = if description then @$titleLimits[1] else @$titleLimits[0]
        @$descriptionField[0].dataset.maxLength = @$descriptionLimits[1]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[0]
      when 'single_ad'
        @$adTitleField[0].dataset.maxLength = @$titleLimits[4]
        @$descriptionField[0].dataset.maxLength = @$descriptionLimits[2]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[2]
      when 'lead_gen'
        @$adTitleField[0].dataset.maxLength = @$titleLimits[1]
        @$descriptionField[0].dataset.maxLength = @$descriptionLimits[0]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[0]
      when 'single_ad_scroll'
        @$adTitleField[0].dataset.maxLength = @$titleLimits[4]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[2]
      when 'lead_gen_scroll'
        @$adTitleField[0].dataset.maxLength = @$titleLimits[1]
        @$actionTextField[0].dataset.maxLength = @$actionTextLimits[0]

  _formImageFieldHandler: ->
    @$imageUploadInput.on 'change', (e) =>
      new Enzymic.Shared.ImageUploadPreview(e.target)
      @$imageUploadPreviewContainer.find('img').remove()
      form = @$form
      $.each @$imageUploadPreviewContainer, (index, container) ->
        new Enzymic.Ads.AdImageCrop(form, container)

  _formSubmitHandler: ->
    @$form.on 'submit', =>
      if @isLeadGenType
        @_optionsValidation()
        if !$('#ad_lead_form_attributes_zapier_confirmed').val() && @$zapierLeadCheckbox.prop('ckecked')
          return false
      else
        @_impTrackerValidation()
      return false if @$form.has('.has-error:visible').length
      unless @$adContentType.val() == 'video'
        imageUploadSelector = @$form.find(
          "input[name='imageUploadSelector']:checked"
        ).val()
        switch imageUploadSelector
          when 'fetch_image'
            @$imageUploadInput.val('')
            images = @$fetchImageContainer.find('.item.active img')
            @_setCoordsFields(images) if images
          when 'upload_image'
            @$remoteImageUrl.val('')
            images = @$imageUploadPreviewContainer.find('img')
            @_setCoordsFields(images) if images
          else null
      else if @$adContentType.val() == 'video'
        if @$videoTypeFileField.is(':checked')
          @$adVideoLinkField.hide()
          uploadingFileMessage = 'Uploading...'
          @$videoInputMessage.text(uploadingFileMessage)
        if @$videoTypeYoutubeField.is(':checked')
          @$adVideoFileField.hide()

  _setCoordsFields: (images) ->
    [x, y, width, height] = [[], [], [], []]
    sizes = ['300x250', '300x150', '300x90', '250x90']
    $.each images, (i, image) ->
      img = $(image)
      size = img.parents('[data-content_size]').data('content_size')
      index = sizes.indexOf(size)
      if img.data('x')? && img.data('y')? && img.data('width')? && img.data('height')?
        x[index] = img.data('x')
        y[index] = img.data('y')
        width[index] = img.data('width')
        height[index] = img.data('height')

    @$x.val(x)
    @$y.val(y)
    @$width.val(width)
    @$height.val(height)

  _cancelBtnHandler: ->
    $cancelBtn = @$form.find('.btn-cancel')
    @$oldContent.hide()
    $cancelBtn.on 'click', (e) =>
      e.preventDefault()
      @$form.remove()
      @$oldContent.show()

  _imageUploadSelectorHandler: ->
    @$form.on 'click', "input[name='imageUploadSelector']", (e) =>
      chosenValue = e.target.value
      switch chosenValue
        when 'fetch_image'
          @_switchToFetchImageContainer()
        when 'upload_image'
          @_switchToUploadImageContainer()
        else null

  _videoUploadSelectorHandler: ->
    @$form.on 'click', "input[name='ad[video_attributes][video_type]']", (e) =>
      chosenValue = e.target.value
      switch chosenValue
        when 'youtube'
          @_switchToFetchVideoContainer()
        when 'file'
          @_switchToUploadVideoContainer()
        when 'infini'
          @_switchToFetchInfiniVideoContainer()
        when 'youku'
          @_switchToFetchYoukuVideoContainer()
        else null

  _switchToUploadImageContainer: ->
    @$fetchImageContainer.addClass('hidden')
    @$uploadImageContainer.removeClass('hidden')
    @_disabledTitle(false)

  _switchToFetchImageContainer: ->
    @$fetchImageContainer.removeClass('hidden')
    @$uploadImageContainer.addClass('hidden')
    @_disabledTitle(false)

  _switchToUploadVideoContainer: ->
    @$fetchVideoContainer.addClass('hidden')
    @$uploadVideoContainer.removeClass('hidden')
    @$fetchInfiniVideoContainer.addClass('hidden')
    @$fetchYoukuVideoContainer.addClass('hidden')
    @_disabledTitle(false)

  _switchToFetchVideoContainer: ->
    @$fetchVideoContainer.removeClass('hidden')
    @$uploadVideoContainer.addClass('hidden')
    @$fetchInfiniVideoContainer.addClass('hidden')
    @$fetchYoukuVideoContainer.addClass('hidden')
    @_disabledTitle(false)

  _switchToFetchInfiniVideoContainer: ->
    @$fetchVideoContainer.addClass('hidden')
    @$uploadVideoContainer.addClass('hidden')
    @$fetchInfiniVideoContainer.removeClass('hidden')
    @$fetchYoukuVideoContainer.addClass('hidden')
    @_disabledTitle(true)

  _switchToFetchYoukuVideoContainer: ->
    @$fetchVideoContainer.addClass('hidden')
    @$uploadVideoContainer.addClass('hidden')
    @$fetchInfiniVideoContainer.addClass('hidden')
    @$fetchYoukuVideoContainer.removeClass('hidden')
    @_disabledTitle(true)

  _disabledTitle: (bool) ->
    @$adTitleField.prop('disabled', bool)
    if bool
      @$adTitleField.closest('.form-group').hide()
      @$adTitleField.val('')
    else
      @$adTitleField.closest('.form-group').show()

  _destinationUrlHandler: ->
    @$destinationUrlField.on 'input', (e) =>
      @$destinationUrlField.val($.trim(@$destinationUrlField.val()))
      @_toggleImageUploadSelector()

    @$destinationUrlField.on 'focusout', (e) =>
      destinationUrlStatus = @_isDestinationUrlValid()
      if destinationUrlStatus == false && !@$adTitleField.val()
        @$fetchingIcon.removeClass('md-done')
        @$fetchingIcon.addClass('md-spin md-autorenew')
        @$adTitleField.prop('disabled', true)
        @_getFetchTitle() unless @_getFetchTitle()

  _zapierConfirmationLink: ->
    @$zapierConfirmationLink.click =>
      webhook = @$zapierWebhookField.val()
      fields = {}
      custom_fields = {}
      @$form.find('#lead_form_fields .form-group').each (i, field) ->
        if $(field).find('.lead_form_fields_presence').prop('checked')
          fields[$(field).find('.field_name').val()] = 'test'

      @$form.find('#lead_form_custom_fields .form-group').each (i, field) ->
        if $(field).find('.lead_form_fields_presence').prop('checked')
          custom_fields[$(field).find('.label_input').val().toLowerCase().replace(' ', '_')] = 'test'

      lead = { ad_id: @adFormId, fields: fields, custom_fields: custom_fields }
      $.ajax
        type: 'POST'
        url: webhook
        crossDomain: true
        data: { lead: lead }
        success: (data, textStatus, jqXHR) =>
          @$zapierConfirmationLink.hide()
          $('#ad_lead_form_attributes_zapier_confirmed').val(true)

  _zapierWebhookHandler: ->
    zapierConfirmed = $('#ad_lead_form_attributes_zapier_confirmed').val()
    $icon = @$zapierWebhookField.parent().find('.validation-icon')
    @$zapierConfirmationLink.hide() if zapierConfirmed
    unless @$zapierLeadCheckbox.prop('checked')
      @$zapierWebhookField.parent().parent().hide()
      @$zapierWebhookField.prop('disabled', true)
      @$zapierConfirmationLink.hide()
    else
      @$zapierWebhookField.parent().parent().show()
      @$zapierWebhookField.prop('disabled', false)
      unless zapierConfirmed
        @$zapierConfirmationLink.show()

    @$zapierLeadCheckbox.change =>
      unless @$zapierLeadCheckbox.prop('checked')
        @$zapierWebhookField.parent().parent().hide()
        @$zapierWebhookField.prop('disabled', true)
        @$zapierConfirmationLink.hide()
        @$adzymicLeadCheckbox.prop('checked', true).change()
      else
        @$zapierWebhookField.parent().parent().show()
        @$zapierWebhookField.prop('disabled', false)
        if @_isZapierWebhookUrlValid() && !zapierConfirmed
          @$zapierConfirmationLink.show()

    @$adzymicLeadCheckbox.change =>
      unless @$adzymicLeadCheckbox.prop('checked')
        @$zapierLeadCheckbox.prop('checked', true).change()

    @$zapierWebhookField.on 'input', (e) =>
      $('#ad_lead_form_attributes_zapier_confirmed').val(false)
      if @_isZapierWebhookUrlValid()
        $icon.removeClass('md-block')
        $icon.addClass('md-done')
        @$zapierConfirmationLink.show()
      else
        $icon.removeClass('md-done')
        $icon.addClass('md-block')
        @$zapierConfirmationLink.hide()

  _isZapierWebhookUrlValid: ->
    isUrl = validator.isURL(@$zapierWebhookField.val(), require_protocol: true)
    startedWith = @$zapierWebhookField.val().substring(0, 37) == 'https://hooks.zapier.com/hooks/catch/'
    isUrl && startedWith

  _toggleImageUploadSelector: ->
    destinationUrlStatus = @_isDestinationUrlValid()
    @$fetchImageRadioButton.prop('disabled', destinationUrlStatus)
    if destinationUrlStatus
      @_switchToUploadImageContainer()
      @$fetchImageRadioButton.prop('checked', !destinationUrlStatus)
      @$uploadImageRadioButton.prop('checked', destinationUrlStatus)
      @$validationIcon.addClass('md-block')
    else
      @$validationIcon.removeClass('md-block')
      @$validationIcon.addClass('md-done')

  _getFetchTitle: ->
    $.ajax
      type: 'POST'
      url: @$fetchTitlePrefix + '/fetch_title'
      data: {
        destination_url: @$destinationUrlField.val()
        ad_id: @adFormId
        ad_unit_content_type: @$adUnitContentType
      }
      success: (data, textStatus, jqXHR) =>
        @$adTitleField.val(data.title).trigger('change')
        @$descriptionField.val(data.description).trigger('change')
        [@$adTitleField, @$descriptionField].forEach (input) ->
          Countable.once input[0], (counter) ->
            @.updateLength(counter)
      error: (jqXHR, textStatus) ->
        console.log textStatus
      complete: =>
        @$adTitleField.prop('disabled', false)
        @$fetchingIcon.removeClass('md-spin md-autorenew')
        @$fetchingIcon.addClass('md-done')

  _isDestinationUrlValid: ->
    validator.isURL(@$destinationUrlField.val(), require_protocol: true) == false

  _updateHelpBlock: (input) ->
    dataset = input.dataset
    length = if input.hasAttribute("data-current-length") then dataset.currentLength else 0
    formGroup = $(input).closest('.form-group')
    formGroup.find('.help-block').text(length + '/' + dataset.maxLength)
    if (length > parseInt(dataset.maxLength))
      formGroup.addClass('has-error')
    else
      formGroup.removeClass('has-error')

  _countableHandlers: ->
    [
      @$adTitleField[0]
#      @$descriptionField[0]
      @$actionTextField[0]
      @$formTitleField[0]
    ].forEach (input) =>
      @_countable(input)

  _countable: (input) ->
    not_carousel_overlay = @$adUnitContentType != 'carousel_overlay'
    if input?
      input.updateLength = (counter) ->
        dataset = this.dataset
        dataset.currentLength = counter.all
        formGroup = $(this).closest('.form-group')
        formGroup.find('.help-block').text(counter.all + '/' + dataset.maxLength)
        if (counter.all > parseInt(dataset.maxLength) || (counter.all == 0))
          formGroup.addClass('has-error')
        else
          formGroup.removeClass('has-error')
      Countable.live input, (counter) ->
        @.updateLength(counter)

  _activateVideo: ->
    jsPlayer = document.querySelector('#video_ad .js-player')
    if jsPlayer?
      plyr.setup(jsPlayer, {debug: false})
      jsPlayer.addEventListener 'ready', (event) ->
        player = event.detail.plyr
        playerContainer = $($(player.getContainer())[0]).parent()
        if playerContainer.attr('class') == 'ad-upload-video'
          previewContainer = $(playerContainer).parent().find('.yt_preview')
          previewContainer.hide()
        controlsContainer = $(playerContainer).find('.plyr__controls')
        playerContainer.show()
        controlsContainer.hide()
        playerContainer.mouseenter ->
          player.play()
          controlsContainer.show()
        playerContainer.mouseleave ->
          player.pause()
          controlsContainer.hide()
