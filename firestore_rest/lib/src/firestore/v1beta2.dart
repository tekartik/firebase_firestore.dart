// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unused_import, unnecessary_cast, prefer_collection_literals
// ignore_for_file: empty_constructor_bodies, constant_identifier_names, invalid_assignment, argument_type_not_assignable, directives_ordering

library firestore_googleapis.firestore.v1beta2;

import 'dart:core' as core;
import 'dart:async' as async;
import 'dart:convert' as convert;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const core.String USER_AGENT = 'dart-api-client firestore/v1beta2';

/// Accesses the NoSQL document database built for automatic scaling, high
/// performance, and ease of application development.
class FirestoreApi {
  /// View and manage your data across Google Cloud Platform services
  static const CloudPlatformScope =
      "https://www.googleapis.com/auth/cloud-platform";

  /// View and manage your Google Cloud Datastore data
  static const DatastoreScope = "https://www.googleapis.com/auth/datastore";

  final commons.ApiRequester _requester;

  ProjectsResourceApi get projects => ProjectsResourceApi(_requester);

  FirestoreApi(http.Client client,
      {core.String rootUrl = "https://firestore.googleapis.com/",
      core.String servicePath = ""})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);
}

class ProjectsResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesResourceApi get databases =>
      ProjectsDatabasesResourceApi(_requester);

  ProjectsResourceApi(commons.ApiRequester client) : _requester = client;
}

class ProjectsDatabasesResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesCollectionGroupsResourceApi get collectionGroups =>
      ProjectsDatabasesCollectionGroupsResourceApi(_requester);

  ProjectsDatabasesResourceApi(commons.ApiRequester client)
      : _requester = client;

  /// Exports a copy of all or a subset of documents from Google Cloud Firestore
  /// to another storage system, such as Google Cloud Storage. Recent updates to
  /// documents may not be reflected in the export. The export occurs in the
  /// background and its progress can be monitored and managed via the
  /// Operation resource that is created. The output of an export may only be
  /// used once the associated operation is done. If an export operation is
  /// cancelled before completion it may leave partial data behind in Google
  /// Cloud Storage.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Database to export. Should be of the form:
  /// `projects/{project_id}/databases/{database_id}`.
  /// Value must have pattern "^projects/[^/]+/databases/[^/]+$".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> exportDocuments(
      GoogleFirestoreAdminV1beta2ExportDocumentsRequest request,
      core.String name,
      {core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (request != null) {
      _body = convert.json.encode((request).toJson());
    }
    if (name == null) {
      throw core.ArgumentError("Parameter name is required.");
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' +
        commons.Escaper.ecapeVariableReserved('$name') +
        ':exportDocuments';

    var _response = _requester.request(_url, "POST",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => GoogleLongrunningOperation.fromJson(data));
  }

  /// Imports documents into Google Cloud Firestore. Existing documents with the
  /// same name are overwritten. The import occurs in the background and its
  /// progress can be monitored and managed via the Operation resource that is
  /// created. If an ImportDocuments operation is cancelled, it is possible
  /// that a subset of the data has already been imported to Cloud Firestore.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Database to import into. Should be of the form:
  /// `projects/{project_id}/databases/{database_id}`.
  /// Value must have pattern "^projects/[^/]+/databases/[^/]+$".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> importDocuments(
      GoogleFirestoreAdminV1beta2ImportDocumentsRequest request,
      core.String name,
      {core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (request != null) {
      _body = convert.json.encode((request).toJson());
    }
    if (name == null) {
      throw core.ArgumentError("Parameter name is required.");
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' +
        commons.Escaper.ecapeVariableReserved('$name') +
        ':importDocuments';

    var _response = _requester.request(_url, "POST",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => GoogleLongrunningOperation.fromJson(data));
  }
}

class ProjectsDatabasesCollectionGroupsResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesCollectionGroupsFieldsResourceApi get fields =>
      ProjectsDatabasesCollectionGroupsFieldsResourceApi(_requester);
  ProjectsDatabasesCollectionGroupsIndexesResourceApi get indexes =>
      ProjectsDatabasesCollectionGroupsIndexesResourceApi(_requester);

  ProjectsDatabasesCollectionGroupsResourceApi(commons.ApiRequester client)
      : _requester = client;
}

class ProjectsDatabasesCollectionGroupsFieldsResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesCollectionGroupsFieldsResourceApi(
      commons.ApiRequester client)
      : _requester = client;

  /// Gets the metadata and configuration for a Field.
  ///
  /// Request parameters:
  ///
  /// [name] - A name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_id}`
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+/fields/[^/]+$".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirestoreAdminV1beta2Field].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirestoreAdminV1beta2Field> get(core.String name,
      {core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (name == null) {
      throw core.ArgumentError("Parameter name is required.");
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' + commons.Escaper.ecapeVariableReserved('$name');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response
        .then((data) => GoogleFirestoreAdminV1beta2Field.fromJson(data));
  }

  /// Lists the field configuration and metadata for this database.
  ///
  /// Currently, FirestoreAdmin.ListFields only supports listing fields
  /// that have been explicitly overridden. To issue this query, call
  /// FirestoreAdmin.ListFields with the filter set to
  /// `indexConfig.usesAncestorConfig:false`.
  ///
  /// Request parameters:
  ///
  /// [parent] - A parent name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}`
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+$".
  ///
  /// [filter] - The filter to apply to list results. Currently,
  /// FirestoreAdmin.ListFields only supports listing fields
  /// that have been explicitly overridden. To issue this query, call
  /// FirestoreAdmin.ListFields with the filter set to
  /// `indexConfig.usesAncestorConfig:false`.
  ///
  /// [pageToken] - A page token, returned from a previous call to
  /// FirestoreAdmin.ListFields, that may be used to get the next
  /// page of results.
  ///
  /// [pageSize] - The number of results to return.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirestoreAdminV1beta2ListFieldsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirestoreAdminV1beta2ListFieldsResponse> list(
      core.String parent,
      {core.String filter,
      core.String pageToken,
      core.int pageSize,
      core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (parent == null) {
      throw core.ArgumentError("Parameter parent is required.");
    }
    if (filter != null) {
      _queryParams["filter"] = [filter];
    }
    if (pageToken != null) {
      _queryParams["pageToken"] = [pageToken];
    }
    if (pageSize != null) {
      _queryParams["pageSize"] = ["${pageSize}"];
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' +
        commons.Escaper.ecapeVariableReserved('$parent') +
        '/fields';

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then(
        (data) => GoogleFirestoreAdminV1beta2ListFieldsResponse.fromJson(data));
  }

  /// Updates a field configuration. Currently, field updates apply only to
  /// single field index configuration. However, calls to
  /// FirestoreAdmin.UpdateField should provide a field mask to avoid
  /// changing any configuration that the caller isn't aware of. The field mask
  /// should be specified as: `{ paths: "index_config" }`.
  ///
  /// This call returns a google.longrunning.Operation which may be used to
  /// track the status of the field update. The metadata for
  /// the operation will be the type FieldOperationMetadata.
  ///
  /// To configure the default field settings for the database, use
  /// the special `Field` with resource name:
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/__default__/fields
  /// / * `.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - A field name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_path}`
  ///
  /// A field path may be a simple field name, e.g. `address` or a path to
  /// fields
  /// within map_value , e.g. `address.city`,
  /// or a special field path. The only valid special field is `*`, which
  /// represents any field.
  ///
  /// Field paths may be quoted using ` (backtick). The only character that
  /// needs
  /// to be escaped within a quoted field path is the backtick character itself,
  /// escaped using a backslash. Special characters in field paths that
  /// must be quoted include: `*`, `.`,
  /// ``` (backtick), `[`, `]`, as well as any ascii symbolic characters.
  ///
  /// Examples:
  /// (Note: Comments here are written in markdown syntax, so there is an
  ///  additional layer of backticks to represent a code block)
  /// `\`address.city\`` represents a field named `address.city`, not the map
  /// key
  /// `city` in the field `address`.
  /// `\`*\`` represents a field named `*`, not any field.
  ///
  /// A special `Field` contains the default indexing settings for all fields.
  /// This field's resource name is:
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/__default__/fields
  /// / * `
  /// Indexes defined on this `Field` will be applied to all fields which do not
  /// have their own `Field` index configuration.
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+/fields/[^/]+$".
  ///
  /// [updateMask] - A mask, relative to the field. If specified, only
  /// configuration specified
  /// by this field_mask will be updated in the field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> patch(
      GoogleFirestoreAdminV1beta2Field request, core.String name,
      {core.String updateMask, core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (request != null) {
      _body = convert.json.encode((request).toJson());
    }
    if (name == null) {
      throw core.ArgumentError("Parameter name is required.");
    }
    if (updateMask != null) {
      _queryParams["updateMask"] = [updateMask];
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' + commons.Escaper.ecapeVariableReserved('$name');

    var _response = _requester.request(_url, "PATCH",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => GoogleLongrunningOperation.fromJson(data));
  }
}

class ProjectsDatabasesCollectionGroupsIndexesResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesCollectionGroupsIndexesResourceApi(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates a composite index. This returns a google.longrunning.Operation
  /// which may be used to track the status of the creation. The metadata for
  /// the operation will be the type IndexOperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - A parent name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}`
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+$".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
      GoogleFirestoreAdminV1beta2Index request, core.String parent,
      {core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (request != null) {
      _body = convert.json.encode((request).toJson());
    }
    if (parent == null) {
      throw core.ArgumentError("Parameter parent is required.");
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' +
        commons.Escaper.ecapeVariableReserved('$parent') +
        '/indexes';

    var _response = _requester.request(_url, "POST",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => GoogleLongrunningOperation.fromJson(data));
  }

  /// Deletes a composite index.
  ///
  /// Request parameters:
  ///
  /// [name] - A name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+/indexes/[^/]+$".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> delete(core.String name, {core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (name == null) {
      throw core.ArgumentError("Parameter name is required.");
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' + commons.Escaper.ecapeVariableReserved('$name');

    var _response = _requester.request(_url, "DELETE",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => Empty.fromJson(data));
  }

  /// Gets a composite index.
  ///
  /// Request parameters:
  ///
  /// [name] - A name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+/indexes/[^/]+$".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirestoreAdminV1beta2Index].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirestoreAdminV1beta2Index> get(core.String name,
      {core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (name == null) {
      throw core.ArgumentError("Parameter name is required.");
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' + commons.Escaper.ecapeVariableReserved('$name');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response
        .then((data) => GoogleFirestoreAdminV1beta2Index.fromJson(data));
  }

  /// Lists composite indexes.
  ///
  /// Request parameters:
  ///
  /// [parent] - A parent name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}`
  /// Value must have pattern
  /// "^projects/[^/]+/databases/[^/]+/collectionGroups/[^/]+$".
  ///
  /// [pageToken] - A page token, returned from a previous call to
  /// FirestoreAdmin.ListIndexes, that may be used to get the next
  /// page of results.
  ///
  /// [pageSize] - The number of results to return.
  ///
  /// [filter] - The filter to apply to list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirestoreAdminV1beta2ListIndexesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirestoreAdminV1beta2ListIndexesResponse> list(
      core.String parent,
      {core.String pageToken,
      core.int pageSize,
      core.String filter,
      core.String $fields}) {
    var _url;
    var _queryParams = core.Map<core.String, core.List<core.String>>();
    var _uploadMedia;
    var _uploadOptions;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body;

    if (parent == null) {
      throw core.ArgumentError("Parameter parent is required.");
    }
    if (pageToken != null) {
      _queryParams["pageToken"] = [pageToken];
    }
    if (pageSize != null) {
      _queryParams["pageSize"] = ["${pageSize}"];
    }
    if (filter != null) {
      _queryParams["filter"] = [filter];
    }
    if ($fields != null) {
      _queryParams["fields"] = [$fields];
    }

    _url = 'v1beta2/' +
        commons.Escaper.ecapeVariableReserved('$parent') +
        '/indexes';

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) =>
        GoogleFirestoreAdminV1beta2ListIndexesResponse.fromJson(data));
  }
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs. A typical example is to use it as the request
/// or the response type of an API method. For instance:
///
///     service Foo {
///       rpc Bar(google.protobuf.Empty) returns (google.protobuf.Empty);
///     }
///
/// The JSON representation for `Empty` is empty JSON object `{}`.
class Empty {
  Empty();

  Empty.fromJson(core.Map _json) {}

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    return _json;
  }
}

/// Metadata for google.longrunning.Operation results from
/// FirestoreAdmin.ExportDocuments.
class GoogleFirestoreAdminV1beta2ExportDocumentsMetadata {
  /// Which collection ids are being exported.
  core.List<core.String> collectionIds;

  /// The time this operation completed. Will be unset if operation still in
  /// progress.
  core.String endTime;

  /// The state of the export operation.
  /// Possible string values are:
  /// - "OPERATION_STATE_UNSPECIFIED" : Unspecified.
  /// - "INITIALIZING" : Request is being prepared for processing.
  /// - "PROCESSING" : Request is actively being processed.
  /// - "CANCELLING" : Request is in the process of being cancelled after user
  /// called
  /// google.longrunning.Operations.CancelOperation on the operation.
  /// - "FINALIZING" : Request has been processed and is in its finalization
  /// stage.
  /// - "SUCCESSFUL" : Request has completed successfully.
  /// - "FAILED" : Request has finished being processed, but encountered an
  /// error.
  /// - "CANCELLED" : Request has finished being cancelled after user called
  /// google.longrunning.Operations.CancelOperation.
  core.String operationState;

  /// Where the entities are being exported to.
  core.String outputUriPrefix;

  /// The progress, in bytes, of this operation.
  GoogleFirestoreAdminV1beta2Progress progressBytes;

  /// The progress, in documents, of this operation.
  GoogleFirestoreAdminV1beta2Progress progressDocuments;

  /// The time this operation started.
  core.String startTime;

  GoogleFirestoreAdminV1beta2ExportDocumentsMetadata();

  GoogleFirestoreAdminV1beta2ExportDocumentsMetadata.fromJson(core.Map _json) {
    if (_json.containsKey("collectionIds")) {
      collectionIds = (_json["collectionIds"] as core.List).cast<core.String>();
    }
    if (_json.containsKey("endTime")) {
      endTime = _json["endTime"];
    }
    if (_json.containsKey("operationState")) {
      operationState = _json["operationState"];
    }
    if (_json.containsKey("outputUriPrefix")) {
      outputUriPrefix = _json["outputUriPrefix"];
    }
    if (_json.containsKey("progressBytes")) {
      progressBytes =
          GoogleFirestoreAdminV1beta2Progress.fromJson(_json["progressBytes"]);
    }
    if (_json.containsKey("progressDocuments")) {
      progressDocuments = GoogleFirestoreAdminV1beta2Progress.fromJson(
          _json["progressDocuments"]);
    }
    if (_json.containsKey("startTime")) {
      startTime = _json["startTime"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (collectionIds != null) {
      _json["collectionIds"] = collectionIds;
    }
    if (endTime != null) {
      _json["endTime"] = endTime;
    }
    if (operationState != null) {
      _json["operationState"] = operationState;
    }
    if (outputUriPrefix != null) {
      _json["outputUriPrefix"] = outputUriPrefix;
    }
    if (progressBytes != null) {
      _json["progressBytes"] = (progressBytes).toJson();
    }
    if (progressDocuments != null) {
      _json["progressDocuments"] = (progressDocuments).toJson();
    }
    if (startTime != null) {
      _json["startTime"] = startTime;
    }
    return _json;
  }
}

/// The request for FirestoreAdmin.ExportDocuments.
class GoogleFirestoreAdminV1beta2ExportDocumentsRequest {
  /// Which collection ids to export. Unspecified means all collections.
  core.List<core.String> collectionIds;

  /// The output URI. Currently only supports Google Cloud Storage URIs of the
  /// form: `gs://BUCKET_NAME[/NAMESPACE_PATH]`, where `BUCKET_NAME` is the name
  /// of the Google Cloud Storage bucket and `NAMESPACE_PATH` is an optional
  /// Google Cloud Storage namespace path. When
  /// choosing a name, be sure to consider Google Cloud Storage naming
  /// guidelines: https://cloud.google.com/storage/docs/naming.
  /// If the URI is a bucket (without a namespace path), a prefix will be
  /// generated based on the start time.
  core.String outputUriPrefix;

  GoogleFirestoreAdminV1beta2ExportDocumentsRequest();

  GoogleFirestoreAdminV1beta2ExportDocumentsRequest.fromJson(core.Map _json) {
    if (_json.containsKey("collectionIds")) {
      collectionIds = (_json["collectionIds"] as core.List).cast<core.String>();
    }
    if (_json.containsKey("outputUriPrefix")) {
      outputUriPrefix = _json["outputUriPrefix"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (collectionIds != null) {
      _json["collectionIds"] = collectionIds;
    }
    if (outputUriPrefix != null) {
      _json["outputUriPrefix"] = outputUriPrefix;
    }
    return _json;
  }
}

/// Returned in the google.longrunning.Operation response field.
class GoogleFirestoreAdminV1beta2ExportDocumentsResponse {
  /// Location of the output files. This can be used to begin an import
  /// into Cloud Firestore (this project or another project) after the operation
  /// completes successfully.
  core.String outputUriPrefix;

  GoogleFirestoreAdminV1beta2ExportDocumentsResponse();

  GoogleFirestoreAdminV1beta2ExportDocumentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey("outputUriPrefix")) {
      outputUriPrefix = _json["outputUriPrefix"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (outputUriPrefix != null) {
      _json["outputUriPrefix"] = outputUriPrefix;
    }
    return _json;
  }
}

/// Represents a single field in the database.
///
/// Fields are grouped by their "Collection Group", which represent all
/// collections in the database with the same id.
class GoogleFirestoreAdminV1beta2Field {
  /// The index configuration for this field. If unset, field indexing will
  /// revert to the configuration defined by the `ancestor_field`. To
  /// explicitly remove all indexes for this field, specify an index config
  /// with an empty list of indexes.
  GoogleFirestoreAdminV1beta2IndexConfig indexConfig;

  /// A field name of the form
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_path}`
  ///
  /// A field path may be a simple field name, e.g. `address` or a path to
  /// fields
  /// within map_value , e.g. `address.city`,
  /// or a special field path. The only valid special field is `*`, which
  /// represents any field.
  ///
  /// Field paths may be quoted using ` (backtick). The only character that
  /// needs
  /// to be escaped within a quoted field path is the backtick character itself,
  /// escaped using a backslash. Special characters in field paths that
  /// must be quoted include: `*`, `.`,
  /// ``` (backtick), `[`, `]`, as well as any ascii symbolic characters.
  ///
  /// Examples:
  /// (Note: Comments here are written in markdown syntax, so there is an
  ///  additional layer of backticks to represent a code block)
  /// `\`address.city\`` represents a field named `address.city`, not the map
  /// key
  /// `city` in the field `address`.
  /// `\`*\`` represents a field named `*`, not any field.
  ///
  /// A special `Field` contains the default indexing settings for all fields.
  /// This field's resource name is:
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/__default__/fields
  /// / * `
  /// Indexes defined on this `Field` will be applied to all fields which do not
  /// have their own `Field` index configuration.
  core.String name;

  GoogleFirestoreAdminV1beta2Field();

  GoogleFirestoreAdminV1beta2Field.fromJson(core.Map _json) {
    if (_json.containsKey("indexConfig")) {
      indexConfig =
          GoogleFirestoreAdminV1beta2IndexConfig.fromJson(_json["indexConfig"]);
    }
    if (_json.containsKey("name")) {
      name = _json["name"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (indexConfig != null) {
      _json["indexConfig"] = (indexConfig).toJson();
    }
    if (name != null) {
      _json["name"] = name;
    }
    return _json;
  }
}

/// Metadata for google.longrunning.Operation results from
/// FirestoreAdmin.UpdateField.
class GoogleFirestoreAdminV1beta2FieldOperationMetadata {
  /// The progress, in bytes, of this operation.
  GoogleFirestoreAdminV1beta2Progress bytesProgress;

  /// The progress, in documents, of this operation.
  GoogleFirestoreAdminV1beta2Progress documentProgress;

  /// The time this operation completed. Will be unset if operation still in
  /// progress.
  core.String endTime;

  /// The field resource that this operation is acting on. For example:
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_path}`
  core.String field;

  /// A list of IndexConfigDelta, which describe the intent of this
  /// operation.
  core.List<GoogleFirestoreAdminV1beta2IndexConfigDelta> indexConfigDeltas;

  /// The time this operation started.
  core.String startTime;

  /// The state of the operation.
  /// Possible string values are:
  /// - "OPERATION_STATE_UNSPECIFIED" : Unspecified.
  /// - "INITIALIZING" : Request is being prepared for processing.
  /// - "PROCESSING" : Request is actively being processed.
  /// - "CANCELLING" : Request is in the process of being cancelled after user
  /// called
  /// google.longrunning.Operations.CancelOperation on the operation.
  /// - "FINALIZING" : Request has been processed and is in its finalization
  /// stage.
  /// - "SUCCESSFUL" : Request has completed successfully.
  /// - "FAILED" : Request has finished being processed, but encountered an
  /// error.
  /// - "CANCELLED" : Request has finished being cancelled after user called
  /// google.longrunning.Operations.CancelOperation.
  core.String state;

  GoogleFirestoreAdminV1beta2FieldOperationMetadata();

  GoogleFirestoreAdminV1beta2FieldOperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey("bytesProgress")) {
      bytesProgress =
          GoogleFirestoreAdminV1beta2Progress.fromJson(_json["bytesProgress"]);
    }
    if (_json.containsKey("documentProgress")) {
      documentProgress = GoogleFirestoreAdminV1beta2Progress.fromJson(
          _json["documentProgress"]);
    }
    if (_json.containsKey("endTime")) {
      endTime = _json["endTime"];
    }
    if (_json.containsKey("field")) {
      field = _json["field"];
    }
    if (_json.containsKey("indexConfigDeltas")) {
      indexConfigDeltas = (_json["indexConfigDeltas"] as core.List)
          .map<GoogleFirestoreAdminV1beta2IndexConfigDelta>((value) =>
              GoogleFirestoreAdminV1beta2IndexConfigDelta.fromJson(value))
          .toList();
    }
    if (_json.containsKey("startTime")) {
      startTime = _json["startTime"];
    }
    if (_json.containsKey("state")) {
      state = _json["state"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (bytesProgress != null) {
      _json["bytesProgress"] = (bytesProgress).toJson();
    }
    if (documentProgress != null) {
      _json["documentProgress"] = (documentProgress).toJson();
    }
    if (endTime != null) {
      _json["endTime"] = endTime;
    }
    if (field != null) {
      _json["field"] = field;
    }
    if (indexConfigDeltas != null) {
      _json["indexConfigDeltas"] =
          indexConfigDeltas.map((value) => (value).toJson()).toList();
    }
    if (startTime != null) {
      _json["startTime"] = startTime;
    }
    if (state != null) {
      _json["state"] = state;
    }
    return _json;
  }
}

/// Metadata for google.longrunning.Operation results from
/// FirestoreAdmin.ImportDocuments.
class GoogleFirestoreAdminV1beta2ImportDocumentsMetadata {
  /// Which collection ids are being imported.
  core.List<core.String> collectionIds;

  /// The time this operation completed. Will be unset if operation still in
  /// progress.
  core.String endTime;

  /// The location of the documents being imported.
  core.String inputUriPrefix;

  /// The state of the import operation.
  /// Possible string values are:
  /// - "OPERATION_STATE_UNSPECIFIED" : Unspecified.
  /// - "INITIALIZING" : Request is being prepared for processing.
  /// - "PROCESSING" : Request is actively being processed.
  /// - "CANCELLING" : Request is in the process of being cancelled after user
  /// called
  /// google.longrunning.Operations.CancelOperation on the operation.
  /// - "FINALIZING" : Request has been processed and is in its finalization
  /// stage.
  /// - "SUCCESSFUL" : Request has completed successfully.
  /// - "FAILED" : Request has finished being processed, but encountered an
  /// error.
  /// - "CANCELLED" : Request has finished being cancelled after user called
  /// google.longrunning.Operations.CancelOperation.
  core.String operationState;

  /// The progress, in bytes, of this operation.
  GoogleFirestoreAdminV1beta2Progress progressBytes;

  /// The progress, in documents, of this operation.
  GoogleFirestoreAdminV1beta2Progress progressDocuments;

  /// The time this operation started.
  core.String startTime;

  GoogleFirestoreAdminV1beta2ImportDocumentsMetadata();

  GoogleFirestoreAdminV1beta2ImportDocumentsMetadata.fromJson(core.Map _json) {
    if (_json.containsKey("collectionIds")) {
      collectionIds = (_json["collectionIds"] as core.List).cast<core.String>();
    }
    if (_json.containsKey("endTime")) {
      endTime = _json["endTime"];
    }
    if (_json.containsKey("inputUriPrefix")) {
      inputUriPrefix = _json["inputUriPrefix"];
    }
    if (_json.containsKey("operationState")) {
      operationState = _json["operationState"];
    }
    if (_json.containsKey("progressBytes")) {
      progressBytes =
          GoogleFirestoreAdminV1beta2Progress.fromJson(_json["progressBytes"]);
    }
    if (_json.containsKey("progressDocuments")) {
      progressDocuments = GoogleFirestoreAdminV1beta2Progress.fromJson(
          _json["progressDocuments"]);
    }
    if (_json.containsKey("startTime")) {
      startTime = _json["startTime"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (collectionIds != null) {
      _json["collectionIds"] = collectionIds;
    }
    if (endTime != null) {
      _json["endTime"] = endTime;
    }
    if (inputUriPrefix != null) {
      _json["inputUriPrefix"] = inputUriPrefix;
    }
    if (operationState != null) {
      _json["operationState"] = operationState;
    }
    if (progressBytes != null) {
      _json["progressBytes"] = (progressBytes).toJson();
    }
    if (progressDocuments != null) {
      _json["progressDocuments"] = (progressDocuments).toJson();
    }
    if (startTime != null) {
      _json["startTime"] = startTime;
    }
    return _json;
  }
}

/// The request for FirestoreAdmin.ImportDocuments.
class GoogleFirestoreAdminV1beta2ImportDocumentsRequest {
  /// Which collection ids to import. Unspecified means all collections included
  /// in the import.
  core.List<core.String> collectionIds;

  /// Location of the exported files.
  /// This must match the output_uri_prefix of an ExportDocumentsResponse from
  /// an export that has completed successfully.
  /// See:
  /// google.firestore.admin.v1beta2.ExportDocumentsResponse.output_uri_prefix.
  core.String inputUriPrefix;

  GoogleFirestoreAdminV1beta2ImportDocumentsRequest();

  GoogleFirestoreAdminV1beta2ImportDocumentsRequest.fromJson(core.Map _json) {
    if (_json.containsKey("collectionIds")) {
      collectionIds = (_json["collectionIds"] as core.List).cast<core.String>();
    }
    if (_json.containsKey("inputUriPrefix")) {
      inputUriPrefix = _json["inputUriPrefix"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (collectionIds != null) {
      _json["collectionIds"] = collectionIds;
    }
    if (inputUriPrefix != null) {
      _json["inputUriPrefix"] = inputUriPrefix;
    }
    return _json;
  }
}

/// Cloud Firestore indexes enable simple and complex queries against
/// documents in a database.
class GoogleFirestoreAdminV1beta2Index {
  /// The fields supported by this index.
  ///
  /// For composite indexes, this is always 2 or more fields.
  /// The last field entry is always for the field path `__name__`. If, on
  /// creation, `__name__` was not specified as the last field, it will be added
  /// automatically with the same direction as that of the last field defined.
  /// If
  /// the final field in a composite index is not directional, the `__name__`
  /// will be ordered ASCENDING (unless explicitly specified).
  ///
  /// For single field indexes, this will always be exactly one entry with a
  /// field path equal to the field path of the associated field.
  core.List<GoogleFirestoreAdminV1beta2IndexField> fields;

  /// Output only. A server defined name for this index.
  /// The form of this name for composite indexes will be:
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{composite_index_id}`
  /// For single field indexes, this field will be empty.
  core.String name;

  /// Indexes with a collection query scope specified allow queries
  /// against a collection that is the child of a specific document, specified
  /// at
  /// query time, and that has the same collection id.
  ///
  /// Indexes with a collection group query scope specified allow queries
  /// against
  /// all collections descended from a specific document, specified at query
  /// time, and that have the same collection id as this index.
  /// Possible string values are:
  /// - "QUERY_SCOPE_UNSPECIFIED" : The query scope is unspecified. Not a valid
  /// option.
  /// - "COLLECTION" : Indexes with a collection query scope specified allow
  /// queries
  /// against a collection that is the child of a specific document, specified
  /// at query time, and that has the collection id specified by the index.
  /// - "COLLECTION_GROUP" : Indexes with a collection group query scope
  /// specified allow queries
  /// against all collections that has the collection id specified by the
  /// index.
  core.String queryScope;

  /// Output only. The serving state of the index.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state is unspecified.
  /// - "CREATING" : The index is being created.
  /// There is an active long-running operation for the index.
  /// The index is updated when writing a document.
  /// Some index data may exist.
  /// - "READY" : The index is ready to be used.
  /// The index is updated when writing a document.
  /// The index is fully populated from all stored documents it applies to.
  /// - "NEEDS_REPAIR" : The index was being created, but something went wrong.
  /// There is no active long-running operation for the index,
  /// and the most recently finished long-running operation failed.
  /// The index is not updated when writing a document.
  /// Some index data may exist.
  /// Use the google.longrunning.Operations API to determine why the operation
  /// that last attempted to create this index failed, then re-create the
  /// index.
  core.String state;

  GoogleFirestoreAdminV1beta2Index();

  GoogleFirestoreAdminV1beta2Index.fromJson(core.Map _json) {
    if (_json.containsKey("fields")) {
      fields = (_json["fields"] as core.List)
          .map<GoogleFirestoreAdminV1beta2IndexField>(
              (value) => GoogleFirestoreAdminV1beta2IndexField.fromJson(value))
          .toList();
    }
    if (_json.containsKey("name")) {
      name = _json["name"];
    }
    if (_json.containsKey("queryScope")) {
      queryScope = _json["queryScope"];
    }
    if (_json.containsKey("state")) {
      state = _json["state"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (fields != null) {
      _json["fields"] = fields.map((value) => (value).toJson()).toList();
    }
    if (name != null) {
      _json["name"] = name;
    }
    if (queryScope != null) {
      _json["queryScope"] = queryScope;
    }
    if (state != null) {
      _json["state"] = state;
    }
    return _json;
  }
}

/// The index configuration for this field.
class GoogleFirestoreAdminV1beta2IndexConfig {
  /// Output only. Specifies the resource name of the `Field` from which this
  /// field's
  /// index configuration is set (when `uses_ancestor_config` is true),
  /// or from which it *would* be set if this field had no index configuration
  /// (when `uses_ancestor_config` is false).
  core.String ancestorField;

  /// The indexes supported for this field.
  core.List<GoogleFirestoreAdminV1beta2Index> indexes;

  /// Output only
  /// When true, the `Field`'s index configuration is in the process of being
  /// reverted. Once complete, the index config will transition to the same
  /// state as the field specified by `ancestor_field`, at which point
  /// `uses_ancestor_config` will be `true` and `reverting` will be `false`.
  core.bool reverting;

  /// Output only. When true, the `Field`'s index configuration is set from the
  /// configuration specified by the `ancestor_field`.
  /// When false, the `Field`'s index configuration is defined explicitly.
  core.bool usesAncestorConfig;

  GoogleFirestoreAdminV1beta2IndexConfig();

  GoogleFirestoreAdminV1beta2IndexConfig.fromJson(core.Map _json) {
    if (_json.containsKey("ancestorField")) {
      ancestorField = _json["ancestorField"];
    }
    if (_json.containsKey("indexes")) {
      indexes = (_json["indexes"] as core.List)
          .map<GoogleFirestoreAdminV1beta2Index>(
              (value) => GoogleFirestoreAdminV1beta2Index.fromJson(value))
          .toList();
    }
    if (_json.containsKey("reverting")) {
      reverting = _json["reverting"];
    }
    if (_json.containsKey("usesAncestorConfig")) {
      usesAncestorConfig = _json["usesAncestorConfig"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (ancestorField != null) {
      _json["ancestorField"] = ancestorField;
    }
    if (indexes != null) {
      _json["indexes"] = indexes.map((value) => (value).toJson()).toList();
    }
    if (reverting != null) {
      _json["reverting"] = reverting;
    }
    if (usesAncestorConfig != null) {
      _json["usesAncestorConfig"] = usesAncestorConfig;
    }
    return _json;
  }
}

/// Information about an index configuration change.
class GoogleFirestoreAdminV1beta2IndexConfigDelta {
  /// Specifies how the index is changing.
  /// Possible string values are:
  /// - "CHANGE_TYPE_UNSPECIFIED" : The type of change is not specified or
  /// known.
  /// - "ADD" : The single field index is being added.
  /// - "REMOVE" : The single field index is being removed.
  core.String changeType;

  /// The index being changed.
  GoogleFirestoreAdminV1beta2Index index;

  GoogleFirestoreAdminV1beta2IndexConfigDelta();

  GoogleFirestoreAdminV1beta2IndexConfigDelta.fromJson(core.Map _json) {
    if (_json.containsKey("changeType")) {
      changeType = _json["changeType"];
    }
    if (_json.containsKey("index")) {
      index = GoogleFirestoreAdminV1beta2Index.fromJson(_json["index"]);
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (changeType != null) {
      _json["changeType"] = changeType;
    }
    if (index != null) {
      _json["index"] = (index).toJson();
    }
    return _json;
  }
}

/// A field in an index.
/// The field_path describes which field is indexed, the value_mode describes
/// how the field value is indexed.
class GoogleFirestoreAdminV1beta2IndexField {
  /// Indicates that this field supports operations on `array_value`s.
  /// Possible string values are:
  /// - "ARRAY_CONFIG_UNSPECIFIED" : The index does not support additional array
  /// queries.
  /// - "CONTAINS" : The index supports array containment queries.
  core.String arrayConfig;

  /// Can be __name__.
  /// For single field indexes, this must match the name of the field or may
  /// be omitted.
  core.String fieldPath;

  /// Indicates that this field supports ordering by the specified order or
  /// comparing using =, <, <=, >, >=.
  /// Possible string values are:
  /// - "ORDER_UNSPECIFIED" : The ordering is unspecified. Not a valid option.
  /// - "ASCENDING" : The field is ordered by ascending field value.
  /// - "DESCENDING" : The field is ordered by descending field value.
  core.String order;

  GoogleFirestoreAdminV1beta2IndexField();

  GoogleFirestoreAdminV1beta2IndexField.fromJson(core.Map _json) {
    if (_json.containsKey("arrayConfig")) {
      arrayConfig = _json["arrayConfig"];
    }
    if (_json.containsKey("fieldPath")) {
      fieldPath = _json["fieldPath"];
    }
    if (_json.containsKey("order")) {
      order = _json["order"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (arrayConfig != null) {
      _json["arrayConfig"] = arrayConfig;
    }
    if (fieldPath != null) {
      _json["fieldPath"] = fieldPath;
    }
    if (order != null) {
      _json["order"] = order;
    }
    return _json;
  }
}

/// Metadata for google.longrunning.Operation results from
/// FirestoreAdmin.CreateIndex.
class GoogleFirestoreAdminV1beta2IndexOperationMetadata {
  /// The time this operation completed. Will be unset if operation still in
  /// progress.
  core.String endTime;

  /// The index resource that this operation is acting on. For example:
  /// `projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`
  core.String index;

  /// The progress, in bytes, of this operation.
  GoogleFirestoreAdminV1beta2Progress progressBytes;

  /// The progress, in documents, of this operation.
  GoogleFirestoreAdminV1beta2Progress progressDocuments;

  /// The time this operation started.
  core.String startTime;

  /// The state of the operation.
  /// Possible string values are:
  /// - "OPERATION_STATE_UNSPECIFIED" : Unspecified.
  /// - "INITIALIZING" : Request is being prepared for processing.
  /// - "PROCESSING" : Request is actively being processed.
  /// - "CANCELLING" : Request is in the process of being cancelled after user
  /// called
  /// google.longrunning.Operations.CancelOperation on the operation.
  /// - "FINALIZING" : Request has been processed and is in its finalization
  /// stage.
  /// - "SUCCESSFUL" : Request has completed successfully.
  /// - "FAILED" : Request has finished being processed, but encountered an
  /// error.
  /// - "CANCELLED" : Request has finished being cancelled after user called
  /// google.longrunning.Operations.CancelOperation.
  core.String state;

  GoogleFirestoreAdminV1beta2IndexOperationMetadata();

  GoogleFirestoreAdminV1beta2IndexOperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey("endTime")) {
      endTime = _json["endTime"];
    }
    if (_json.containsKey("index")) {
      index = _json["index"];
    }
    if (_json.containsKey("progressBytes")) {
      progressBytes =
          GoogleFirestoreAdminV1beta2Progress.fromJson(_json["progressBytes"]);
    }
    if (_json.containsKey("progressDocuments")) {
      progressDocuments = GoogleFirestoreAdminV1beta2Progress.fromJson(
          _json["progressDocuments"]);
    }
    if (_json.containsKey("startTime")) {
      startTime = _json["startTime"];
    }
    if (_json.containsKey("state")) {
      state = _json["state"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (endTime != null) {
      _json["endTime"] = endTime;
    }
    if (index != null) {
      _json["index"] = index;
    }
    if (progressBytes != null) {
      _json["progressBytes"] = (progressBytes).toJson();
    }
    if (progressDocuments != null) {
      _json["progressDocuments"] = (progressDocuments).toJson();
    }
    if (startTime != null) {
      _json["startTime"] = startTime;
    }
    if (state != null) {
      _json["state"] = state;
    }
    return _json;
  }
}

/// The response for FirestoreAdmin.ListFields.
class GoogleFirestoreAdminV1beta2ListFieldsResponse {
  /// The requested fields.
  core.List<GoogleFirestoreAdminV1beta2Field> fields;

  /// A page token that may be used to request another page of results. If
  /// blank,
  /// this is the last page.
  core.String nextPageToken;

  GoogleFirestoreAdminV1beta2ListFieldsResponse();

  GoogleFirestoreAdminV1beta2ListFieldsResponse.fromJson(core.Map _json) {
    if (_json.containsKey("fields")) {
      fields = (_json["fields"] as core.List)
          .map<GoogleFirestoreAdminV1beta2Field>(
              (value) => GoogleFirestoreAdminV1beta2Field.fromJson(value))
          .toList();
    }
    if (_json.containsKey("nextPageToken")) {
      nextPageToken = _json["nextPageToken"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (fields != null) {
      _json["fields"] = fields.map((value) => (value).toJson()).toList();
    }
    if (nextPageToken != null) {
      _json["nextPageToken"] = nextPageToken;
    }
    return _json;
  }
}

/// The response for FirestoreAdmin.ListIndexes.
class GoogleFirestoreAdminV1beta2ListIndexesResponse {
  /// The requested indexes.
  core.List<GoogleFirestoreAdminV1beta2Index> indexes;

  /// A page token that may be used to request another page of results. If
  /// blank,
  /// this is the last page.
  core.String nextPageToken;

  GoogleFirestoreAdminV1beta2ListIndexesResponse();

  GoogleFirestoreAdminV1beta2ListIndexesResponse.fromJson(core.Map _json) {
    if (_json.containsKey("indexes")) {
      indexes = (_json["indexes"] as core.List)
          .map<GoogleFirestoreAdminV1beta2Index>(
              (value) => GoogleFirestoreAdminV1beta2Index.fromJson(value))
          .toList();
    }
    if (_json.containsKey("nextPageToken")) {
      nextPageToken = _json["nextPageToken"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (indexes != null) {
      _json["indexes"] = indexes.map((value) => (value).toJson()).toList();
    }
    if (nextPageToken != null) {
      _json["nextPageToken"] = nextPageToken;
    }
    return _json;
  }
}

/// Describes the progress of the operation.
/// Unit of work is generic and must be interpreted based on where Progress
/// is used.
class GoogleFirestoreAdminV1beta2Progress {
  /// The amount of work completed.
  core.String completedWork;

  /// The amount of work estimated.
  core.String estimatedWork;

  GoogleFirestoreAdminV1beta2Progress();

  GoogleFirestoreAdminV1beta2Progress.fromJson(core.Map _json) {
    if (_json.containsKey("completedWork")) {
      completedWork = _json["completedWork"];
    }
    if (_json.containsKey("estimatedWork")) {
      estimatedWork = _json["estimatedWork"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (completedWork != null) {
      _json["completedWork"] = completedWork;
    }
    if (estimatedWork != null) {
      _json["estimatedWork"] = estimatedWork;
    }
    return _json;
  }
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool done;

  /// The error result of the operation in case of failure or cancellation.
  Status error;

  /// Service-specific metadata associated with the operation.  It typically
  /// contains progress information and common metadata such as create time.
  /// Some services might not provide such metadata.  Any method that returns a
  /// long-running operation should document the metadata type, if any.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object> metadata;

  /// The server-assigned name, which is only unique within the same service
  /// that
  /// originally returns it. If you use the default HTTP mapping, the
  /// `name` should be a resource name ending with `operations/{unique_id}`.
  core.String name;

  /// The normal response of the operation in case of success.  If the original
  /// method returns no data on success, such as `Delete`, the response is
  /// `google.protobuf.Empty`.  If the original method is standard
  /// `Get`/`Create`/`Update`, the response should be the resource.  For other
  /// methods, the response should have the type `XxxResponse`, where `Xxx`
  /// is the original method name.  For example, if the original method name
  /// is `TakeSnapshot()`, the inferred response type is
  /// `TakeSnapshotResponse`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object> response;

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey("done")) {
      done = _json["done"];
    }
    if (_json.containsKey("error")) {
      error = Status.fromJson(_json["error"]);
    }
    if (_json.containsKey("metadata")) {
      metadata =
          (_json["metadata"] as core.Map).cast<core.String, core.Object>();
    }
    if (_json.containsKey("name")) {
      name = _json["name"];
    }
    if (_json.containsKey("response")) {
      response =
          (_json["response"] as core.Map).cast<core.String, core.Object>();
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (done != null) {
      _json["done"] = done;
    }
    if (error != null) {
      _json["error"] = (error).toJson();
    }
    if (metadata != null) {
      _json["metadata"] = metadata;
    }
    if (name != null) {
      _json["name"] = name;
    }
    if (response != null) {
      _json["response"] = response;
    }
    return _json;
  }
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs. It is
/// used by [gRPC](https://github.com/grpc). Each `Status` message contains
/// three pieces of data: error code, error message, and error details.
///
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
  /// The status code, which should be an enum value of google.rpc.Code.
  core.int code;

  /// A list of messages that carry the error details.  There is a common set of
  /// message types for APIs to use.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>> details;

  /// A developer-facing error message, which should be in English. Any
  /// user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  core.String message;

  Status();

  Status.fromJson(core.Map _json) {
    if (_json.containsKey("code")) {
      code = _json["code"];
    }
    if (_json.containsKey("details")) {
      details = (_json["details"] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map).cast<core.String, core.Object>())
          .toList();
    }
    if (_json.containsKey("message")) {
      message = _json["message"];
    }
  }

  core.Map<core.String, core.Object> toJson() {
    final core.Map<core.String, core.Object> _json =
        core.Map<core.String, core.Object>();
    if (code != null) {
      _json["code"] = code;
    }
    if (details != null) {
      _json["details"] = details;
    }
    if (message != null) {
      _json["message"] = message;
    }
    return _json;
  }
}
