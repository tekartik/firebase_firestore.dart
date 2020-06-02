// This is a modified version of a generated file (see the discoveryapis_generator project).
library tekartik_firebase_firestore.firestore_googleapis.firestore.v1beta1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart'
    show RunQueryResponse, RunQueryRequest;

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;
export 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart';

// ignore: constant_identifier_names
const core.String USER_AGENT = 'dart-api-client firestore/v1beta1';

/// Accesses the NoSQL document database built for automatic scaling, high
/// performance, and ease of application development.
class FirestoreFixedApi {
  final commons.ApiRequester _requester;

  ProjectsResourceFixedApi get projects => ProjectsResourceFixedApi(_requester);

  FirestoreFixedApi(http.Client client,
      {core.String rootUrl = 'https://firestore.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);
}

class ProjectsResourceFixedApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesResourceFixedApi get databases =>
      ProjectsDatabasesResourceFixedApi(_requester);

  ProjectsResourceFixedApi(commons.ApiRequester client) : _requester = client;
}

class ProjectsDatabasesResourceFixedApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesDocumentsResourceApi get documents =>
      ProjectsDatabasesDocumentsResourceApi(_requester);

  ProjectsDatabasesResourceFixedApi(commons.ApiRequester client)
      : _requester = client;
}

class ProjectsDatabasesDocumentsResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesDocumentsResourceApi(commons.ApiRequester client)
      : _requester = client;

  /// Fixing...
  async.Future<RunQueryFixedResponse> runQueryFixed(
      RunQueryRequest request, core.String parent,
      {core.String $fields}) async {
    core.String _url;
    var _queryParams = <core.String, core.List<core.String>>{};
    commons.Media _uploadMedia;
    commons.UploadOptions _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    core.String _body;

    if (request != null) {
      _body = convert.json.encode((request).toJson());
    }
    if (parent == null) {
      throw core.ArgumentError('Parameter parent is required.');
    }
    if ($fields != null) {
      _queryParams['fields'] = [$fields];
    }

    _url = 'v1beta1/' +
        commons.Escaper.ecapeVariableReserved('$parent') +
        ':runQuery';

    var _response = await _requester.request(_url, 'POST',
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);

    //core.print(_response);
    return RunQueryFixedResponse.fromJson(_response as core.List);
  }
}

/// The response for Firestore.RunQuery.
class RunQueryFixedResponse {
  /// A query result.
  /// Not set when reporting partial progress.
  core.List<RunQueryResponse> documents;

  RunQueryFixedResponse();

  RunQueryFixedResponse.fromJson(core.List _json) {
    documents = _json
        .map((documentJson) =>
            RunQueryResponse.fromJson(documentJson as core.Map))
        .toList(growable: false);
  }

  core.List<core.Object> toJson() {
    return documents
        .map((document) => document.toJson())
        ?.toList(growable: false);
  }
}
