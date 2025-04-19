import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'video_background_struct.g.dart';

abstract class VideoBackgroundStruct
    implements Built<VideoBackgroundStruct, VideoBackgroundStructBuilder> {
  String? get name;
  String? get videoUrl;
  String? get category;
  String? get thumbnailUrl;
  double? get opacity;
  DocumentReference<Object?>? get reference;

  VideoBackgroundStruct._();
  factory VideoBackgroundStruct(
          [void Function(VideoBackgroundStructBuilder) updates]) =
      _$VideoBackgroundStruct;
}
