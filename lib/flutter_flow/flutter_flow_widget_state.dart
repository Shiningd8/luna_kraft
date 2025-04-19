import 'package:flutter/material.dart';

enum WidgetState {
  hovered,
  pressed,
  dragged,
  disabled,
  selected,
  focused,
  error,
}

class WidgetStateProperty<T> {
  final Map<WidgetState, T> _values = {};

  WidgetStateProperty();

  T? resolve(Set<WidgetState> states) {
    for (final state in states) {
      if (_values.containsKey(state)) {
        return _values[state];
      }
    }
    return null;
  }

  static WidgetStateProperty<T> resolveWith<T>(
    T Function(Set<WidgetState> states) callback,
  ) {
    return _ResolvingWidgetStateProperty<T>(callback);
  }

  void set(WidgetState state, T value) {
    _values[state] = value;
  }
}

class _ResolvingWidgetStateProperty<T> extends WidgetStateProperty<T> {
  final T Function(Set<WidgetState> states) _callback;

  _ResolvingWidgetStateProperty(this._callback);

  @override
  T? resolve(Set<WidgetState> states) {
    return _callback(states);
  }
}
