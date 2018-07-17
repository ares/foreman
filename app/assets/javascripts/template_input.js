$(document).on('change', 'select.input_type_selector', function () {
  update_visibility_after_input_type_change($(this));
});

function update_visibility_after_input_type_change(select){
  fieldset = select.closest('fieldset');
  fieldset.find('div.custom_input_type_fields').hide();
  fieldset.find('div.' + select.val() + '_input_type').show();
}
$(function() {
  update_visibility_after_input_type_change($('select.input_type_selector'));

  $('a.advanced_fields_switch').on('click', toggle_advanced_fields);
});


function toggle_advanced_fields() {
  switcher = $('a.advanced_fields_switch');
  original = switcher.html();
  switcher.html(switcher.data('alternativeLabel'));
  switcher.data('alternativeLabel', original);

  switcher.siblings('i').toggleClass('fa-angle-right').toggleClass('fa-angle-down');

  $('div.advanced').toggle()
}
