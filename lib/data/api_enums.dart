import '../models/models.dart';

/// Mappings between the backend's integer enums and the app's types.
/// Mirrors `Speek.Domain.Enums`.
class ApiEnums {
  ApiEnums._();

  // SpeakerRole: Learner = 0, Native = 1
  static SpeakerRole role(dynamic v) =>
      (v is int ? v : int.tryParse('$v') ?? 0) == 1
          ? SpeakerRole.native
          : SpeakerRole.learner;

  static int roleToInt(SpeakerRole r) => r == SpeakerRole.native ? 1 : 0;

  // CefrLevel: None=0, A1,A2,B1,B2,C1,C2,Native
  static const _cefr = ['', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Native'];

  static String cefr(dynamic v) {
    final i = v is int ? v : int.tryParse('$v') ?? 0;
    return (i >= 0 && i < _cefr.length) ? _cefr[i] : '';
  }

  static int cefrToInt(String level) {
    final i = _cefr.indexOf(level);
    return i < 0 ? 0 : i;
  }

  // MessageKind: Text=0, Voice=1, CallLog=2, Image=3, Document=4, Invite=5
  static MessageKind messageKind(dynamic v) {
    switch (v is int ? v : int.tryParse('$v') ?? 0) {
      case 1:
        return MessageKind.voice;
      case 2:
        return MessageKind.callLog;
      case 3:
        return MessageKind.image;
      case 4:
        return MessageKind.document;
      case 5:
        return MessageKind.invite;
      default:
        return MessageKind.text;
    }
  }

  static int messageKindToInt(MessageKind k) {
    switch (k) {
      case MessageKind.voice:
        return 1;
      case MessageKind.callLog:
        return 2;
      case MessageKind.image:
        return 3;
      case MessageKind.document:
        return 4;
      case MessageKind.invite:
        return 5;
      case MessageKind.text:
        return 0;
    }
  }
}
