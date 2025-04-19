// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_struct.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PostsStruct extends PostsStruct {
  @override
  final String? title;
  @override
  final String? dream;
  @override
  final String? tags;
  @override
  final DateTime? date;
  @override
  final DocumentReference<Object?>? poster;
  @override
  final BuiltList<DocumentReference<Object?>>? likes;
  @override
  final BuiltList<DocumentReference<Object?>>? postSavedBy;
  @override
  final String? videoBackgroundUrl;
  @override
  final double? videoBackgroundOpacity;
  @override
  final bool? postIsEdited;
  @override
  final String? themes;
  @override
  final DocumentReference<Object?>? userref;

  factory _$PostsStruct([void Function(PostsStructBuilder)? updates]) =>
      (new PostsStructBuilder()..update(updates))._build();

  _$PostsStruct._(
      {this.title,
      this.dream,
      this.tags,
      this.date,
      this.poster,
      this.likes,
      this.postSavedBy,
      this.videoBackgroundUrl,
      this.videoBackgroundOpacity,
      this.postIsEdited,
      this.themes,
      this.userref})
      : super._();

  @override
  PostsStruct rebuild(void Function(PostsStructBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PostsStructBuilder toBuilder() => new PostsStructBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PostsStruct &&
        title == other.title &&
        dream == other.dream &&
        tags == other.tags &&
        date == other.date &&
        poster == other.poster &&
        likes == other.likes &&
        postSavedBy == other.postSavedBy &&
        videoBackgroundUrl == other.videoBackgroundUrl &&
        videoBackgroundOpacity == other.videoBackgroundOpacity &&
        postIsEdited == other.postIsEdited &&
        themes == other.themes &&
        userref == other.userref;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, dream.hashCode);
    _$hash = $jc(_$hash, tags.hashCode);
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jc(_$hash, poster.hashCode);
    _$hash = $jc(_$hash, likes.hashCode);
    _$hash = $jc(_$hash, postSavedBy.hashCode);
    _$hash = $jc(_$hash, videoBackgroundUrl.hashCode);
    _$hash = $jc(_$hash, videoBackgroundOpacity.hashCode);
    _$hash = $jc(_$hash, postIsEdited.hashCode);
    _$hash = $jc(_$hash, themes.hashCode);
    _$hash = $jc(_$hash, userref.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostsStruct')
          ..add('title', title)
          ..add('dream', dream)
          ..add('tags', tags)
          ..add('date', date)
          ..add('poster', poster)
          ..add('likes', likes)
          ..add('postSavedBy', postSavedBy)
          ..add('videoBackgroundUrl', videoBackgroundUrl)
          ..add('videoBackgroundOpacity', videoBackgroundOpacity)
          ..add('postIsEdited', postIsEdited)
          ..add('themes', themes)
          ..add('userref', userref))
        .toString();
  }
}

class PostsStructBuilder implements Builder<PostsStruct, PostsStructBuilder> {
  _$PostsStruct? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _dream;
  String? get dream => _$this._dream;
  set dream(String? dream) => _$this._dream = dream;

  String? _tags;
  String? get tags => _$this._tags;
  set tags(String? tags) => _$this._tags = tags;

  DateTime? _date;
  DateTime? get date => _$this._date;
  set date(DateTime? date) => _$this._date = date;

  DocumentReference<Object?>? _poster;
  DocumentReference<Object?>? get poster => _$this._poster;
  set poster(DocumentReference<Object?>? poster) => _$this._poster = poster;

  ListBuilder<DocumentReference<Object?>>? _likes;
  ListBuilder<DocumentReference<Object?>> get likes =>
      _$this._likes ??= new ListBuilder<DocumentReference<Object?>>();
  set likes(ListBuilder<DocumentReference<Object?>>? likes) =>
      _$this._likes = likes;

  ListBuilder<DocumentReference<Object?>>? _postSavedBy;
  ListBuilder<DocumentReference<Object?>> get postSavedBy =>
      _$this._postSavedBy ??= new ListBuilder<DocumentReference<Object?>>();
  set postSavedBy(ListBuilder<DocumentReference<Object?>>? postSavedBy) =>
      _$this._postSavedBy = postSavedBy;

  String? _videoBackgroundUrl;
  String? get videoBackgroundUrl => _$this._videoBackgroundUrl;
  set videoBackgroundUrl(String? videoBackgroundUrl) =>
      _$this._videoBackgroundUrl = videoBackgroundUrl;

  double? _videoBackgroundOpacity;
  double? get videoBackgroundOpacity => _$this._videoBackgroundOpacity;
  set videoBackgroundOpacity(double? videoBackgroundOpacity) =>
      _$this._videoBackgroundOpacity = videoBackgroundOpacity;

  bool? _postIsEdited;
  bool? get postIsEdited => _$this._postIsEdited;
  set postIsEdited(bool? postIsEdited) => _$this._postIsEdited = postIsEdited;

  String? _themes;
  String? get themes => _$this._themes;
  set themes(String? themes) => _$this._themes = themes;

  DocumentReference<Object?>? _userref;
  DocumentReference<Object?>? get userref => _$this._userref;
  set userref(DocumentReference<Object?>? userref) => _$this._userref = userref;

  PostsStructBuilder();

  PostsStructBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _dream = $v.dream;
      _tags = $v.tags;
      _date = $v.date;
      _poster = $v.poster;
      _likes = $v.likes?.toBuilder();
      _postSavedBy = $v.postSavedBy?.toBuilder();
      _videoBackgroundUrl = $v.videoBackgroundUrl;
      _videoBackgroundOpacity = $v.videoBackgroundOpacity;
      _postIsEdited = $v.postIsEdited;
      _themes = $v.themes;
      _userref = $v.userref;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PostsStruct other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PostsStruct;
  }

  @override
  void update(void Function(PostsStructBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PostsStruct build() => _build();

  _$PostsStruct _build() {
    _$PostsStruct _$result;
    try {
      _$result = _$v ??
          new _$PostsStruct._(
            title: title,
            dream: dream,
            tags: tags,
            date: date,
            poster: poster,
            likes: _likes?.build(),
            postSavedBy: _postSavedBy?.build(),
            videoBackgroundUrl: videoBackgroundUrl,
            videoBackgroundOpacity: videoBackgroundOpacity,
            postIsEdited: postIsEdited,
            themes: themes,
            userref: userref,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'likes';
        _likes?.build();
        _$failedField = 'postSavedBy';
        _postSavedBy?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'PostsStruct', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
