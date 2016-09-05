$(function () {
  $.widget("ui.limited_spinner", $.ui.spinner, {
    options: {
      soft_maximum: 0,
      error_target: null
    },
    _validate: function() {
      if (this.options['soft_maximum'] != 0) {
        if (this.value() > this.options['soft_maximum']) {
          this.options["error_target"].show();
        } else {
          this.options["error_target"].hide();
        }
      }
    },
    _spin: function (step, event) {
      var result = this._super(step, event);
      this._validate();
      return result
    }
  });

  $.widget("ui.byte_spinner", $.ui.limited_spinner, {
    options: {
      step: 1,
      min: 1,
      incremental: false,
      value_target: null
    },
    _megabyte: function() {
      return 1024 * 1024;
    },
    _gigabyte: function() {
      return 1024 * this._megabyte();
    },
    update_value_target: function() {
      $('#' + this.options['value_target']).val(this.value());
    },
    _gigabyte_spin: function(step) {
      if (step > 0) {
        if (step % this._gigabyte() == 0) {
          step = this._gigabyte();
        } else {
          step = this._gigabyte() - (this.value() % this._gigabyte())
        }
      } else if (step < 0) {
        if (this.value() % this._gigabyte() == 0) {
          step = -1 * this._gigabyte();
        } else {
          step = -1 * (this.value() % this._gigabyte());
        }
      }
      return step;
    },
    _megabyte_spin: function(step) {
      var megabyte_step = step * 256 * this._megabyte();
      if (this.value() + megabyte_step > this._gigabyte()) {
        step = this._gigabyte() - this.value();
      } else if (this.value() + megabyte_step < this._megabyte()) {
        step = step * (this.value() - this._megabyte());
      } else if (this.value() == this._megabyte() && step > 0) {
        step = 255 * this._megabyte();
      } else {
        step = megabyte_step;
      }
      return step;
    },
    _spin: function (step, event) {
      if (this.value() > this._gigabyte() && step < 0 || this.value() >= this._gigabyte() && step > 0) {
        step = this._gigabyte_spin(step)
      } else {
        step = this._megabyte_spin(step)
      }

      var result = this._super(step, event);
      this.update_value_target();

      return result
    },
    _parse: function (value) {
      if (typeof value === "string") {
        if (value.match(/gb$/i)) {
          return parseFloat(value) * this._gigabyte()
        } else if (value.match(/mb$/i) || parseInt(value) < this._megabyte()) {
          return parseInt(value) * this._megabyte()
        }
      }
      return value;
    },
    // prints value with unit, if it's multiple of gigabytes use GB, otherwise format in MB
    _format: function (value) {
      if (value % this._gigabyte() == 0) {
        return (value / this._gigabyte()) + ' GB';
      } else {
        return (value / this._megabyte()) + ' MB';
      }
    }
  });
});

export function initByteSpinner(){
  $("input.byte_spinner").each(function () {
    var target = $(this).parents('div').children('span.help-block').children('span.maximum-limit');
    $(this).byte_spinner({value_target: $(this).attr('id') + "_hidden", soft_maximum: $(this).data('softMax'), error_target: target});
    $(this).change(function() { $(this).byte_spinner("update_value_target") })
  });
}
