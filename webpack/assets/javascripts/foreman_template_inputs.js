import $ from 'jquery';

export function initTypeChanges() {
  // update the hidden input which serves as template
  // and also all existing inputs in case of editing
  $('select.input_type_selector').each(function() {
    updateVisibilityAfterInputTypeChange($(this));
  })

  // every additional input that's added through "Add Input" button will also be handled
  $(document).on('change', 'select.input_type_selector', function () {
    updateVisibilityAfterInputTypeChange($(this));
  });
}

function updateVisibilityAfterInputTypeChange(select) {
  const fieldset = select.closest('fieldset');
  fieldset.find('div.custom_input_type_fields').hide();
  fieldset.find('div.' + select.val() + '_input_type').show();
}

export function initAdvancedFields() {
  $('a.advanced_fields_switch').each(function () {
    const field = $(this);
    field.on('click', updateAdvancedFields)
  })
}

function updateAdvancedFields() {
  const switcher = $('a.advanced_fields_switch');
  const original = switcher.html();
  switcher.html(switcher.data('alternativeLabel'));
  switcher.data('alternativeLabel', original);

  switcher.siblings('i').toggleClass('fa-angle-right').toggleClass('fa-angle-down');

  $('div.advanced').toggle()
}
