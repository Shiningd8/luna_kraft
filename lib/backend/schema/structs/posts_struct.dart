import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:built_collection/built_collection.dart';

part 'posts_struct.g.dart';

abstract class PostsStruct implements Built<PostsStruct, PostsStructBuilder> {
  String? get title;
  String? get dream;
  String? get tags;
  DateTime? get date;
  DocumentReference<Object?>? get poster;
  @BuiltValueField(wireName: 'likes')
  BuiltList<DocumentReference<Object?>>? get likes;
  @BuiltValueField(wireName: 'Post_saved_by')
  BuiltList<DocumentReference<Object?>>? get postSavedBy;
  String? get videoBackgroundUrl;
  double? get videoBackgroundOpacity;
  bool? get postIsEdited;
  String? get themes;
  DocumentReference<Object?>? get userref;

  PostsStruct._();
  factory PostsStruct([void Function(PostsStructBuilder) updates]) =
      _$PostsStruct;
}
