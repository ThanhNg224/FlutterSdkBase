import 'package:flutter/widgets.dart';
import 'package:flutter_sdk_base/core/extensions/context_extensions.dart';

abstract final class FormValidators {
  static FormFieldValidator<String> required(BuildContext context) {
    return (value) => value == null || value.trim().isEmpty ? context.l10n.validationRequired : null;
  }

  static FormFieldValidator<String> email(BuildContext context) {
    final requiredValidator = required(context);
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return (value) {
      final requiredMessage = requiredValidator(value);
      if (requiredMessage != null) return requiredMessage;
      return emailPattern.hasMatch(value!.trim()) ? null : context.l10n.validationEmail;
    };
  }

  static FormFieldValidator<String> minLength(BuildContext context, int count) {
    return (value) => value != null && value.trim().length >= count ? null : context.l10n.validationMinLength(count);
  }

  static FormFieldValidator<String> compose(List<FormFieldValidator<String>> validators) {
    return (value) {
      for (final validator in validators) {
        final message = validator(value);
        if (message != null) return message;
      }
      return null;
    };
  }
}
