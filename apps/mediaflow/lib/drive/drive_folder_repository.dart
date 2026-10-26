import '../models/media_models.dart';
import 'drive_folder_parser.dart';
import 'drive_http.dart';
import 'drive_link.dart';

/// Reads link-shared Drive folder pages and file metadata pages.
class DriveFolderRepository {
  final DriveHttpTransport transport;

  const DriveFolderRepository(this.transport);

  Future<DriveFolderPage> load(String folderId) async {
    final uri = Uri.https('drive.google.com', '/embeddedfolderview', {
      'id': folderId,
    });
    final response = await transport.get(uri);

    final access = DriveFolderParser.detectAccessError(response.body);
    if (access != null) {
      throw MediaFlowException(
        MediaFlowError(
          code: access,
          technicalDetails: 'Drive returned a restricted HTML page.',
        ),
      );
    }
    _throwForStatus(response.statusCode);

    try {
      return DriveFolderParser.parse(response.body);
    } on DriveFolderParseException catch (error) {
      throw MediaFlowException(
        MediaFlowError(code: error.code, technicalDetails: error.details),
      );
    }
  }

  Future<String?> fileTitle(DriveLink link) async {
    final uri = Uri.tryParse(link.canonicalUrl);
    if (uri == null) return null;
    final response = await transport.get(uri);

    final access = DriveFolderParser.detectAccessError(response.body);
    if (access != null) {
      throw MediaFlowException(
        MediaFlowError(
          code: access,
          technicalDetails: 'Drive returned a restricted HTML page.',
        ),
      );
    }
    _throwForStatus(response.statusCode);

    try {
      return DriveFolderParser.parse(response.body).name;
    } on DriveFolderParseException catch (error) {
      if (error.code == MediaFlowErrorCode.driveLayoutChanged) return null;
      throw MediaFlowException(
        MediaFlowError(code: error.code, technicalDetails: error.details),
      );
    }
  }

  void _throwForStatus(int statusCode) {
    final error = driveErrorForStatus(statusCode);
    if (error != null) throw MediaFlowException(error);
  }
}
