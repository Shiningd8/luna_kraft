// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_background_struct.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VideoBackgroundStruct extends VideoBackgroundStruct {
  @override
  final String? name;
  @override
  final String? videoUrl;
  @override
  final String? category;
  @override
  final String? thumbnailUrl;
  @override
  final double? opacity;
  @override
  final DocumentReference<Object?>? reference;

  factory _$VideoBackgroundStruct(
          [void Function(VideoBackgroundStructBuilder)? updates]) =>
      (new VideoBackgroundStructBuilder()..update(updates))._build();

  _$VideoBackgroundStruct._(
      {this.name,
      this.videoUrl,
      this.category,
      this.thumbnailUrl,
      this.opacity,
      this.reference})
      : super._();

  @override
  VideoBackgroundStruct rebuild(
          void Function(VideoBackgroundStructBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VideoBackgroundStructBuilder toBuilder() =>
      new VideoBackgroundStructBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VideoBackgroundStruct &&
        name == other.name &&
        videoUrl == other.videoUrl &&
        category == other.category &&
        thumbnailUrl == other.thumbnailUrl &&
        opacity == other.opacity &&
        reference == other.reference;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, videoUrl.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, thumbnailUrl.hashCode);
    _$hash = $jc(_$hash, opacity.hashCode);
    _$hash = $jc(_$hash, reference.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VideoBackgroundStruct')
          ..add('name', name)
          ..add('videoUrl', videoUrl)
          ..add('category', category)
          ..add('thumbnailUrl', thumbnailUrl)
          ..add('opacity', opacity)
          ..add('reference', reference))
        .toString();
  }
}

class VideoBackgroundStructBuilder
    implements Builder<VideoBackgroundStruct, VideoBackgroundStructBuilder> {
  _$VideoBackgroundStruct? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _videoUrl;
  String? get videoUrl => _$this._videoUrl;
  set videoUrl(String? videoUrl) => _$this._videoUrl = videoUrl;

  String? _category;
  String? get category => _$this._category;
  set category(String? category) => _$this._category = category;

  String? _thumbnailUrl;
  String? get thumbnailUrl => _$this._thumbnailUrl;
  set thumbnailUrl(String? thumbnailUrl) => _$this._thumbnailUrl = thumbnailUrl;

  double? _opacity;
  double? get opacity => _$this._opacity;
  set opacity(double? opacity) => _$this._opacity = opacity;

  DocumentReference<Object?>? _reference;
  DocumentReference<Object?>? get reference => _$this._reference;
  set reference(DocumentReference<Object?>? reference) =>
      _$this._reference = reference;

  VideoBackgroundStructBuilder();

  VideoBackgroundStructBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _videoUrl = $v.videoUrl;
      _category = $v.category;
      _thumbnailUrl = $v.thumbnailUrl;
      _opacity = $v.opacity;
      _reference = $v.reference;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VideoBackgroundStruct other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$VideoBackgroundStruct;
  }

  @override
  void update(void Function(VideoBackgroundStructBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VideoBackgroundStruct build() => _build();

  _$VideoBackgroundStruct _build() {
    final _$result = _$v ??
        new _$VideoBackgroundStruct._(
          name: name,
          videoUrl: videoUrl,
          category: category,
          thumbnailUrl: thumbnailUrl,
          opacity: opacity,
          reference: reference,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
