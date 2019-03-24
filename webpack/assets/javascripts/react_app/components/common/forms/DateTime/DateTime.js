import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { FieldLevelHelp } from 'patternfly-react';
import DateTimePicker from '../../DateTimePicker/DateTimePicker';

import Form from '../CommonForm';
import { documentLocale } from '../../../../common/I18n';
import './DateTimeOverrides.scss';

const DateTime = ({
  label,
  id,
  info,
  isRequired,
  locale,
  template,
  value,
  initialError,
}) => {
  const currentLocale = locale || documentLocale();

  return (
    <Form
      label={label}
      touched
      error={initialError}
      required={isRequired}
      tooltipHelp={
        info && (
          <FieldLevelHelp
            buttonClass="field-help"
            content={<Fragment>{info}</Fragment>}
          />
        )
      }
    >
      <DateTimePicker
        hiddenValue={isRequired}
        value={value}
        id={`template-date-input-${id}`}
        inputProps={{
          name: `${template}[input_values][${id}][value]`,
        }}
        locale={currentLocale}
      />
    </Form>
  );
};

DateTime.propTypes = {
  label: PropTypes.string.isRequired,
  info: PropTypes.string,
  isRequired: PropTypes.bool,
  id: PropTypes.number.isRequired,
  locale: PropTypes.string,
  template: PropTypes.string.isRequired,
  value: PropTypes.oneOfType([PropTypes.instanceOf(Date), PropTypes.string]),
  initialError: PropTypes.string,
};

DateTime.defaultProps = {
  info: null,
  isRequired: false,
  locale: null,
  value: new Date(),
  initialError: undefined,
};

export default DateTime;
