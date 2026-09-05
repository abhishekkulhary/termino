// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SshHostRowsTable extends SshHostRows
    with TableInfo<$SshHostRowsTable, SshHostRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SshHostRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostnameMeta = const VerificationMeta(
    'hostname',
  );
  @override
  late final GeneratedColumn<String> hostname = GeneratedColumn<String>(
    'hostname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(22),
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authMethodsMeta = const VerificationMeta(
    'authMethods',
  );
  @override
  late final GeneratedColumn<String> authMethods = GeneratedColumn<String>(
    'auth_methods',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _jumpHostIdMeta = const VerificationMeta(
    'jumpHostId',
  );
  @override
  late final GeneratedColumn<String> jumpHostId = GeneratedColumn<String>(
    'jump_host_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keepAliveSecondsMeta = const VerificationMeta(
    'keepAliveSeconds',
  );
  @override
  late final GeneratedColumn<int> keepAliveSeconds = GeneratedColumn<int>(
    'keep_alive_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _startupCommandMeta = const VerificationMeta(
    'startupCommand',
  );
  @override
  late final GeneratedColumn<String> startupCommand = GeneratedColumn<String>(
    'startup_command',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasSavedPasswordMeta = const VerificationMeta(
    'hasSavedPassword',
  );
  @override
  late final GeneratedColumn<bool> hasSavedPassword = GeneratedColumn<bool>(
    'has_saved_password',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_saved_password" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _forwardAgentMeta = const VerificationMeta(
    'forwardAgent',
  );
  @override
  late final GeneratedColumn<bool> forwardAgent = GeneratedColumn<bool>(
    'forward_agent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("forward_agent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    hostname,
    username,
    port,
    identityId,
    authMethods,
    jumpHostId,
    keepAliveSeconds,
    startupCommand,
    colorValue,
    folder,
    hasSavedPassword,
    forwardAgent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ssh_host_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SshHostRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('hostname')) {
      context.handle(
        _hostnameMeta,
        hostname.isAcceptableOrUnknown(data['hostname']!, _hostnameMeta),
      );
    } else if (isInserting) {
      context.missing(_hostnameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    }
    if (data.containsKey('auth_methods')) {
      context.handle(
        _authMethodsMeta,
        authMethods.isAcceptableOrUnknown(
          data['auth_methods']!,
          _authMethodsMeta,
        ),
      );
    }
    if (data.containsKey('jump_host_id')) {
      context.handle(
        _jumpHostIdMeta,
        jumpHostId.isAcceptableOrUnknown(
          data['jump_host_id']!,
          _jumpHostIdMeta,
        ),
      );
    }
    if (data.containsKey('keep_alive_seconds')) {
      context.handle(
        _keepAliveSecondsMeta,
        keepAliveSeconds.isAcceptableOrUnknown(
          data['keep_alive_seconds']!,
          _keepAliveSecondsMeta,
        ),
      );
    }
    if (data.containsKey('startup_command')) {
      context.handle(
        _startupCommandMeta,
        startupCommand.isAcceptableOrUnknown(
          data['startup_command']!,
          _startupCommandMeta,
        ),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('has_saved_password')) {
      context.handle(
        _hasSavedPasswordMeta,
        hasSavedPassword.isAcceptableOrUnknown(
          data['has_saved_password']!,
          _hasSavedPasswordMeta,
        ),
      );
    }
    if (data.containsKey('forward_agent')) {
      context.handle(
        _forwardAgentMeta,
        forwardAgent.isAcceptableOrUnknown(
          data['forward_agent']!,
          _forwardAgentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SshHostRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SshHostRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      hostname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hostname'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      ),
      authMethods: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_methods'],
      )!,
      jumpHostId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jump_host_id'],
      ),
      keepAliveSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}keep_alive_seconds'],
      )!,
      startupCommand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}startup_command'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      ),
      hasSavedPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_saved_password'],
      )!,
      forwardAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}forward_agent'],
      )!,
    );
  }

  @override
  $SshHostRowsTable createAlias(String alias) {
    return $SshHostRowsTable(attachedDatabase, alias);
  }
}

class SshHostRow extends DataClass implements Insertable<SshHostRow> {
  /// Stable identifier, also used to derive the keystore key.
  final String id;

  /// What the user calls this connection.
  final String label;

  /// The address to connect to.
  final String hostname;

  /// The account to log in as.
  final String username;

  /// The TCP port.
  final int port;

  /// The identity to authenticate with, if any.
  final String? identityId;

  /// Auth methods to offer, comma separated, in order. Empty means "all".
  final String authMethods;

  /// Another host to tunnel through, as OpenSSH's ProxyJump.
  final String? jumpHostId;

  /// Keepalive period in seconds. Zero disables it.
  final int keepAliveSeconds;

  /// A command to run once the shell opens.
  final String? startupCommand;

  /// Tab colour, as an ARGB value.
  final int? colorValue;

  /// Grouping shown as a folder in the host list.
  final String? folder;

  /// Whether a password for this host exists in the keystore.
  final bool hasSavedPassword;

  /// Whether to forward the key to the remote host.
  final bool forwardAgent;
  const SshHostRow({
    required this.id,
    required this.label,
    required this.hostname,
    required this.username,
    required this.port,
    this.identityId,
    required this.authMethods,
    this.jumpHostId,
    required this.keepAliveSeconds,
    this.startupCommand,
    this.colorValue,
    this.folder,
    required this.hasSavedPassword,
    required this.forwardAgent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['hostname'] = Variable<String>(hostname);
    map['username'] = Variable<String>(username);
    map['port'] = Variable<int>(port);
    if (!nullToAbsent || identityId != null) {
      map['identity_id'] = Variable<String>(identityId);
    }
    map['auth_methods'] = Variable<String>(authMethods);
    if (!nullToAbsent || jumpHostId != null) {
      map['jump_host_id'] = Variable<String>(jumpHostId);
    }
    map['keep_alive_seconds'] = Variable<int>(keepAliveSeconds);
    if (!nullToAbsent || startupCommand != null) {
      map['startup_command'] = Variable<String>(startupCommand);
    }
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    if (!nullToAbsent || folder != null) {
      map['folder'] = Variable<String>(folder);
    }
    map['has_saved_password'] = Variable<bool>(hasSavedPassword);
    map['forward_agent'] = Variable<bool>(forwardAgent);
    return map;
  }

  SshHostRowsCompanion toCompanion(bool nullToAbsent) {
    return SshHostRowsCompanion(
      id: Value(id),
      label: Value(label),
      hostname: Value(hostname),
      username: Value(username),
      port: Value(port),
      identityId: identityId == null && nullToAbsent
          ? const Value.absent()
          : Value(identityId),
      authMethods: Value(authMethods),
      jumpHostId: jumpHostId == null && nullToAbsent
          ? const Value.absent()
          : Value(jumpHostId),
      keepAliveSeconds: Value(keepAliveSeconds),
      startupCommand: startupCommand == null && nullToAbsent
          ? const Value.absent()
          : Value(startupCommand),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      folder: folder == null && nullToAbsent
          ? const Value.absent()
          : Value(folder),
      hasSavedPassword: Value(hasSavedPassword),
      forwardAgent: Value(forwardAgent),
    );
  }

  factory SshHostRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SshHostRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      hostname: serializer.fromJson<String>(json['hostname']),
      username: serializer.fromJson<String>(json['username']),
      port: serializer.fromJson<int>(json['port']),
      identityId: serializer.fromJson<String?>(json['identityId']),
      authMethods: serializer.fromJson<String>(json['authMethods']),
      jumpHostId: serializer.fromJson<String?>(json['jumpHostId']),
      keepAliveSeconds: serializer.fromJson<int>(json['keepAliveSeconds']),
      startupCommand: serializer.fromJson<String?>(json['startupCommand']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      folder: serializer.fromJson<String?>(json['folder']),
      hasSavedPassword: serializer.fromJson<bool>(json['hasSavedPassword']),
      forwardAgent: serializer.fromJson<bool>(json['forwardAgent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'hostname': serializer.toJson<String>(hostname),
      'username': serializer.toJson<String>(username),
      'port': serializer.toJson<int>(port),
      'identityId': serializer.toJson<String?>(identityId),
      'authMethods': serializer.toJson<String>(authMethods),
      'jumpHostId': serializer.toJson<String?>(jumpHostId),
      'keepAliveSeconds': serializer.toJson<int>(keepAliveSeconds),
      'startupCommand': serializer.toJson<String?>(startupCommand),
      'colorValue': serializer.toJson<int?>(colorValue),
      'folder': serializer.toJson<String?>(folder),
      'hasSavedPassword': serializer.toJson<bool>(hasSavedPassword),
      'forwardAgent': serializer.toJson<bool>(forwardAgent),
    };
  }

  SshHostRow copyWith({
    String? id,
    String? label,
    String? hostname,
    String? username,
    int? port,
    Value<String?> identityId = const Value.absent(),
    String? authMethods,
    Value<String?> jumpHostId = const Value.absent(),
    int? keepAliveSeconds,
    Value<String?> startupCommand = const Value.absent(),
    Value<int?> colorValue = const Value.absent(),
    Value<String?> folder = const Value.absent(),
    bool? hasSavedPassword,
    bool? forwardAgent,
  }) => SshHostRow(
    id: id ?? this.id,
    label: label ?? this.label,
    hostname: hostname ?? this.hostname,
    username: username ?? this.username,
    port: port ?? this.port,
    identityId: identityId.present ? identityId.value : this.identityId,
    authMethods: authMethods ?? this.authMethods,
    jumpHostId: jumpHostId.present ? jumpHostId.value : this.jumpHostId,
    keepAliveSeconds: keepAliveSeconds ?? this.keepAliveSeconds,
    startupCommand: startupCommand.present
        ? startupCommand.value
        : this.startupCommand,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    folder: folder.present ? folder.value : this.folder,
    hasSavedPassword: hasSavedPassword ?? this.hasSavedPassword,
    forwardAgent: forwardAgent ?? this.forwardAgent,
  );
  SshHostRow copyWithCompanion(SshHostRowsCompanion data) {
    return SshHostRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      hostname: data.hostname.present ? data.hostname.value : this.hostname,
      username: data.username.present ? data.username.value : this.username,
      port: data.port.present ? data.port.value : this.port,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      authMethods: data.authMethods.present
          ? data.authMethods.value
          : this.authMethods,
      jumpHostId: data.jumpHostId.present
          ? data.jumpHostId.value
          : this.jumpHostId,
      keepAliveSeconds: data.keepAliveSeconds.present
          ? data.keepAliveSeconds.value
          : this.keepAliveSeconds,
      startupCommand: data.startupCommand.present
          ? data.startupCommand.value
          : this.startupCommand,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      folder: data.folder.present ? data.folder.value : this.folder,
      hasSavedPassword: data.hasSavedPassword.present
          ? data.hasSavedPassword.value
          : this.hasSavedPassword,
      forwardAgent: data.forwardAgent.present
          ? data.forwardAgent.value
          : this.forwardAgent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SshHostRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('hostname: $hostname, ')
          ..write('username: $username, ')
          ..write('port: $port, ')
          ..write('identityId: $identityId, ')
          ..write('authMethods: $authMethods, ')
          ..write('jumpHostId: $jumpHostId, ')
          ..write('keepAliveSeconds: $keepAliveSeconds, ')
          ..write('startupCommand: $startupCommand, ')
          ..write('colorValue: $colorValue, ')
          ..write('folder: $folder, ')
          ..write('hasSavedPassword: $hasSavedPassword, ')
          ..write('forwardAgent: $forwardAgent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    hostname,
    username,
    port,
    identityId,
    authMethods,
    jumpHostId,
    keepAliveSeconds,
    startupCommand,
    colorValue,
    folder,
    hasSavedPassword,
    forwardAgent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SshHostRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.hostname == this.hostname &&
          other.username == this.username &&
          other.port == this.port &&
          other.identityId == this.identityId &&
          other.authMethods == this.authMethods &&
          other.jumpHostId == this.jumpHostId &&
          other.keepAliveSeconds == this.keepAliveSeconds &&
          other.startupCommand == this.startupCommand &&
          other.colorValue == this.colorValue &&
          other.folder == this.folder &&
          other.hasSavedPassword == this.hasSavedPassword &&
          other.forwardAgent == this.forwardAgent);
}

class SshHostRowsCompanion extends UpdateCompanion<SshHostRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> hostname;
  final Value<String> username;
  final Value<int> port;
  final Value<String?> identityId;
  final Value<String> authMethods;
  final Value<String?> jumpHostId;
  final Value<int> keepAliveSeconds;
  final Value<String?> startupCommand;
  final Value<int?> colorValue;
  final Value<String?> folder;
  final Value<bool> hasSavedPassword;
  final Value<bool> forwardAgent;
  final Value<int> rowid;
  const SshHostRowsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.hostname = const Value.absent(),
    this.username = const Value.absent(),
    this.port = const Value.absent(),
    this.identityId = const Value.absent(),
    this.authMethods = const Value.absent(),
    this.jumpHostId = const Value.absent(),
    this.keepAliveSeconds = const Value.absent(),
    this.startupCommand = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.folder = const Value.absent(),
    this.hasSavedPassword = const Value.absent(),
    this.forwardAgent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SshHostRowsCompanion.insert({
    required String id,
    required String label,
    required String hostname,
    required String username,
    this.port = const Value.absent(),
    this.identityId = const Value.absent(),
    this.authMethods = const Value.absent(),
    this.jumpHostId = const Value.absent(),
    this.keepAliveSeconds = const Value.absent(),
    this.startupCommand = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.folder = const Value.absent(),
    this.hasSavedPassword = const Value.absent(),
    this.forwardAgent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       hostname = Value(hostname),
       username = Value(username);
  static Insertable<SshHostRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? hostname,
    Expression<String>? username,
    Expression<int>? port,
    Expression<String>? identityId,
    Expression<String>? authMethods,
    Expression<String>? jumpHostId,
    Expression<int>? keepAliveSeconds,
    Expression<String>? startupCommand,
    Expression<int>? colorValue,
    Expression<String>? folder,
    Expression<bool>? hasSavedPassword,
    Expression<bool>? forwardAgent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (hostname != null) 'hostname': hostname,
      if (username != null) 'username': username,
      if (port != null) 'port': port,
      if (identityId != null) 'identity_id': identityId,
      if (authMethods != null) 'auth_methods': authMethods,
      if (jumpHostId != null) 'jump_host_id': jumpHostId,
      if (keepAliveSeconds != null) 'keep_alive_seconds': keepAliveSeconds,
      if (startupCommand != null) 'startup_command': startupCommand,
      if (colorValue != null) 'color_value': colorValue,
      if (folder != null) 'folder': folder,
      if (hasSavedPassword != null) 'has_saved_password': hasSavedPassword,
      if (forwardAgent != null) 'forward_agent': forwardAgent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SshHostRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? hostname,
    Value<String>? username,
    Value<int>? port,
    Value<String?>? identityId,
    Value<String>? authMethods,
    Value<String?>? jumpHostId,
    Value<int>? keepAliveSeconds,
    Value<String?>? startupCommand,
    Value<int?>? colorValue,
    Value<String?>? folder,
    Value<bool>? hasSavedPassword,
    Value<bool>? forwardAgent,
    Value<int>? rowid,
  }) {
    return SshHostRowsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      hostname: hostname ?? this.hostname,
      username: username ?? this.username,
      port: port ?? this.port,
      identityId: identityId ?? this.identityId,
      authMethods: authMethods ?? this.authMethods,
      jumpHostId: jumpHostId ?? this.jumpHostId,
      keepAliveSeconds: keepAliveSeconds ?? this.keepAliveSeconds,
      startupCommand: startupCommand ?? this.startupCommand,
      colorValue: colorValue ?? this.colorValue,
      folder: folder ?? this.folder,
      hasSavedPassword: hasSavedPassword ?? this.hasSavedPassword,
      forwardAgent: forwardAgent ?? this.forwardAgent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (hostname.present) {
      map['hostname'] = Variable<String>(hostname.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (authMethods.present) {
      map['auth_methods'] = Variable<String>(authMethods.value);
    }
    if (jumpHostId.present) {
      map['jump_host_id'] = Variable<String>(jumpHostId.value);
    }
    if (keepAliveSeconds.present) {
      map['keep_alive_seconds'] = Variable<int>(keepAliveSeconds.value);
    }
    if (startupCommand.present) {
      map['startup_command'] = Variable<String>(startupCommand.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (hasSavedPassword.present) {
      map['has_saved_password'] = Variable<bool>(hasSavedPassword.value);
    }
    if (forwardAgent.present) {
      map['forward_agent'] = Variable<bool>(forwardAgent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SshHostRowsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('hostname: $hostname, ')
          ..write('username: $username, ')
          ..write('port: $port, ')
          ..write('identityId: $identityId, ')
          ..write('authMethods: $authMethods, ')
          ..write('jumpHostId: $jumpHostId, ')
          ..write('keepAliveSeconds: $keepAliveSeconds, ')
          ..write('startupCommand: $startupCommand, ')
          ..write('colorValue: $colorValue, ')
          ..write('folder: $folder, ')
          ..write('hasSavedPassword: $hasSavedPassword, ')
          ..write('forwardAgent: $forwardAgent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnownHostRowsTable extends KnownHostRows
    with TableInfo<$KnownHostRowsTable, KnownHostRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownHostRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyTypeMeta = const VerificationMeta(
    'keyType',
  );
  @override
  late final GeneratedColumn<String> keyType = GeneratedColumn<String>(
    'key_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    host,
    port,
    keyType,
    fingerprint,
    publicKey,
    addedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_host_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnownHostRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('key_type')) {
      context.handle(
        _keyTypeMeta,
        keyType.isAcceptableOrUnknown(data['key_type']!, _keyTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_keyTypeMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  KnownHostRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownHostRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      keyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_type'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $KnownHostRowsTable createAlias(String alias) {
    return $KnownHostRowsTable(attachedDatabase, alias);
  }
}

class KnownHostRow extends DataClass implements Insertable<KnownHostRow> {
  /// Surrogate key; the meaningful uniqueness is the triple below.
  final int rowId;

  /// The host as the user connects to it.
  final String host;

  /// The port.
  final int port;

  /// The key type, e.g. `ssh-ed25519`.
  final String keyType;

  /// OpenSSH-style `SHA256:...` fingerprint.
  final String fingerprint;

  /// The base64 key blob, when known. Present for imported entries.
  final String? publicKey;

  /// When this key was accepted.
  final DateTime addedAt;

  /// `trustOnFirstUse` or `imported`.
  final String source;
  const KnownHostRow({
    required this.rowId,
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    this.publicKey,
    required this.addedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['key_type'] = Variable<String>(keyType);
    map['fingerprint'] = Variable<String>(fingerprint);
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  KnownHostRowsCompanion toCompanion(bool nullToAbsent) {
    return KnownHostRowsCompanion(
      rowId: Value(rowId),
      host: Value(host),
      port: Value(port),
      keyType: Value(keyType),
      fingerprint: Value(fingerprint),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      addedAt: Value(addedAt),
      source: Value(source),
    );
  }

  factory KnownHostRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownHostRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      keyType: serializer.fromJson<String>(json['keyType']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'keyType': serializer.toJson<String>(keyType),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'publicKey': serializer.toJson<String?>(publicKey),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  KnownHostRow copyWith({
    int? rowId,
    String? host,
    int? port,
    String? keyType,
    String? fingerprint,
    Value<String?> publicKey = const Value.absent(),
    DateTime? addedAt,
    String? source,
  }) => KnownHostRow(
    rowId: rowId ?? this.rowId,
    host: host ?? this.host,
    port: port ?? this.port,
    keyType: keyType ?? this.keyType,
    fingerprint: fingerprint ?? this.fingerprint,
    publicKey: publicKey.present ? publicKey.value : this.publicKey,
    addedAt: addedAt ?? this.addedAt,
    source: source ?? this.source,
  );
  KnownHostRow copyWithCompanion(KnownHostRowsCompanion data) {
    return KnownHostRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      keyType: data.keyType.present ? data.keyType.value : this.keyType,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownHostRow(')
          ..write('rowId: $rowId, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('keyType: $keyType, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('publicKey: $publicKey, ')
          ..write('addedAt: $addedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    host,
    port,
    keyType,
    fingerprint,
    publicKey,
    addedAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownHostRow &&
          other.rowId == this.rowId &&
          other.host == this.host &&
          other.port == this.port &&
          other.keyType == this.keyType &&
          other.fingerprint == this.fingerprint &&
          other.publicKey == this.publicKey &&
          other.addedAt == this.addedAt &&
          other.source == this.source);
}

class KnownHostRowsCompanion extends UpdateCompanion<KnownHostRow> {
  final Value<int> rowId;
  final Value<String> host;
  final Value<int> port;
  final Value<String> keyType;
  final Value<String> fingerprint;
  final Value<String?> publicKey;
  final Value<DateTime> addedAt;
  final Value<String> source;
  const KnownHostRowsCompanion({
    this.rowId = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.keyType = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.source = const Value.absent(),
  });
  KnownHostRowsCompanion.insert({
    this.rowId = const Value.absent(),
    required String host,
    required int port,
    required String keyType,
    required String fingerprint,
    this.publicKey = const Value.absent(),
    required DateTime addedAt,
    required String source,
  }) : host = Value(host),
       port = Value(port),
       keyType = Value(keyType),
       fingerprint = Value(fingerprint),
       addedAt = Value(addedAt),
       source = Value(source);
  static Insertable<KnownHostRow> custom({
    Expression<int>? rowId,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? keyType,
    Expression<String>? fingerprint,
    Expression<String>? publicKey,
    Expression<DateTime>? addedAt,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (keyType != null) 'key_type': keyType,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (publicKey != null) 'public_key': publicKey,
      if (addedAt != null) 'added_at': addedAt,
      if (source != null) 'source': source,
    });
  }

  KnownHostRowsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? host,
    Value<int>? port,
    Value<String>? keyType,
    Value<String>? fingerprint,
    Value<String?>? publicKey,
    Value<DateTime>? addedAt,
    Value<String>? source,
  }) {
    return KnownHostRowsCompanion(
      rowId: rowId ?? this.rowId,
      host: host ?? this.host,
      port: port ?? this.port,
      keyType: keyType ?? this.keyType,
      fingerprint: fingerprint ?? this.fingerprint,
      publicKey: publicKey ?? this.publicKey,
      addedAt: addedAt ?? this.addedAt,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (keyType.present) {
      map['key_type'] = Variable<String>(keyType.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownHostRowsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('keyType: $keyType, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('publicKey: $publicKey, ')
          ..write('addedAt: $addedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $SshIdentityRowsTable extends SshIdentityRows
    with TableInfo<$SshIdentityRowsTable, SshIdentityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SshIdentityRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyTypeMeta = const VerificationMeta(
    'keyType',
  );
  @override
  late final GeneratedColumn<String> keyType = GeneratedColumn<String>(
    'key_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasPassphraseMeta = const VerificationMeta(
    'hasPassphrase',
  );
  @override
  late final GeneratedColumn<bool> hasPassphrase = GeneratedColumn<bool>(
    'has_passphrase',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_passphrase" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _requiresBiometricsMeta =
      const VerificationMeta('requiresBiometrics');
  @override
  late final GeneratedColumn<bool> requiresBiometrics = GeneratedColumn<bool>(
    'requires_biometrics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_biometrics" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    keyType,
    publicKey,
    fingerprint,
    hasPassphrase,
    requiresBiometrics,
    comment,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ssh_identity_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SshIdentityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('key_type')) {
      context.handle(
        _keyTypeMeta,
        keyType.isAcceptableOrUnknown(data['key_type']!, _keyTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_keyTypeMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('has_passphrase')) {
      context.handle(
        _hasPassphraseMeta,
        hasPassphrase.isAcceptableOrUnknown(
          data['has_passphrase']!,
          _hasPassphraseMeta,
        ),
      );
    }
    if (data.containsKey('requires_biometrics')) {
      context.handle(
        _requiresBiometricsMeta,
        requiresBiometrics.isAcceptableOrUnknown(
          data['requires_biometrics']!,
          _requiresBiometricsMeta,
        ),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SshIdentityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SshIdentityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      keyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_type'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      hasPassphrase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_passphrase'],
      )!,
      requiresBiometrics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_biometrics'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SshIdentityRowsTable createAlias(String alias) {
    return $SshIdentityRowsTable(attachedDatabase, alias);
  }
}

class SshIdentityRow extends DataClass implements Insertable<SshIdentityRow> {
  /// Stable identifier, also used to derive the keystore key.
  final String id;

  /// What the user calls this key.
  final String name;

  /// `ed25519`, `rsa` or `ecdsa`.
  final String keyType;

  /// The public key, which is not secret.
  final String publicKey;

  /// OpenSSH-style fingerprint of the public key.
  final String fingerprint;

  /// Whether the stored private key is passphrase-encrypted.
  final bool hasPassphrase;

  /// Whether using this key requires a biometric check.
  final bool requiresBiometrics;

  /// Usually `user@host` from the original key.
  final String? comment;

  /// When the key was imported or generated.
  final DateTime createdAt;
  const SshIdentityRow({
    required this.id,
    required this.name,
    required this.keyType,
    required this.publicKey,
    required this.fingerprint,
    required this.hasPassphrase,
    required this.requiresBiometrics,
    this.comment,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['key_type'] = Variable<String>(keyType);
    map['public_key'] = Variable<String>(publicKey);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['has_passphrase'] = Variable<bool>(hasPassphrase);
    map['requires_biometrics'] = Variable<bool>(requiresBiometrics);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SshIdentityRowsCompanion toCompanion(bool nullToAbsent) {
    return SshIdentityRowsCompanion(
      id: Value(id),
      name: Value(name),
      keyType: Value(keyType),
      publicKey: Value(publicKey),
      fingerprint: Value(fingerprint),
      hasPassphrase: Value(hasPassphrase),
      requiresBiometrics: Value(requiresBiometrics),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      createdAt: Value(createdAt),
    );
  }

  factory SshIdentityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SshIdentityRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      keyType: serializer.fromJson<String>(json['keyType']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      hasPassphrase: serializer.fromJson<bool>(json['hasPassphrase']),
      requiresBiometrics: serializer.fromJson<bool>(json['requiresBiometrics']),
      comment: serializer.fromJson<String?>(json['comment']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'keyType': serializer.toJson<String>(keyType),
      'publicKey': serializer.toJson<String>(publicKey),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'hasPassphrase': serializer.toJson<bool>(hasPassphrase),
      'requiresBiometrics': serializer.toJson<bool>(requiresBiometrics),
      'comment': serializer.toJson<String?>(comment),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SshIdentityRow copyWith({
    String? id,
    String? name,
    String? keyType,
    String? publicKey,
    String? fingerprint,
    bool? hasPassphrase,
    bool? requiresBiometrics,
    Value<String?> comment = const Value.absent(),
    DateTime? createdAt,
  }) => SshIdentityRow(
    id: id ?? this.id,
    name: name ?? this.name,
    keyType: keyType ?? this.keyType,
    publicKey: publicKey ?? this.publicKey,
    fingerprint: fingerprint ?? this.fingerprint,
    hasPassphrase: hasPassphrase ?? this.hasPassphrase,
    requiresBiometrics: requiresBiometrics ?? this.requiresBiometrics,
    comment: comment.present ? comment.value : this.comment,
    createdAt: createdAt ?? this.createdAt,
  );
  SshIdentityRow copyWithCompanion(SshIdentityRowsCompanion data) {
    return SshIdentityRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      keyType: data.keyType.present ? data.keyType.value : this.keyType,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      hasPassphrase: data.hasPassphrase.present
          ? data.hasPassphrase.value
          : this.hasPassphrase,
      requiresBiometrics: data.requiresBiometrics.present
          ? data.requiresBiometrics.value
          : this.requiresBiometrics,
      comment: data.comment.present ? data.comment.value : this.comment,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SshIdentityRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('keyType: $keyType, ')
          ..write('publicKey: $publicKey, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('hasPassphrase: $hasPassphrase, ')
          ..write('requiresBiometrics: $requiresBiometrics, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    keyType,
    publicKey,
    fingerprint,
    hasPassphrase,
    requiresBiometrics,
    comment,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SshIdentityRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.keyType == this.keyType &&
          other.publicKey == this.publicKey &&
          other.fingerprint == this.fingerprint &&
          other.hasPassphrase == this.hasPassphrase &&
          other.requiresBiometrics == this.requiresBiometrics &&
          other.comment == this.comment &&
          other.createdAt == this.createdAt);
}

class SshIdentityRowsCompanion extends UpdateCompanion<SshIdentityRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> keyType;
  final Value<String> publicKey;
  final Value<String> fingerprint;
  final Value<bool> hasPassphrase;
  final Value<bool> requiresBiometrics;
  final Value<String?> comment;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SshIdentityRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.keyType = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.hasPassphrase = const Value.absent(),
    this.requiresBiometrics = const Value.absent(),
    this.comment = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SshIdentityRowsCompanion.insert({
    required String id,
    required String name,
    required String keyType,
    required String publicKey,
    required String fingerprint,
    this.hasPassphrase = const Value.absent(),
    this.requiresBiometrics = const Value.absent(),
    this.comment = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       keyType = Value(keyType),
       publicKey = Value(publicKey),
       fingerprint = Value(fingerprint),
       createdAt = Value(createdAt);
  static Insertable<SshIdentityRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? keyType,
    Expression<String>? publicKey,
    Expression<String>? fingerprint,
    Expression<bool>? hasPassphrase,
    Expression<bool>? requiresBiometrics,
    Expression<String>? comment,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (keyType != null) 'key_type': keyType,
      if (publicKey != null) 'public_key': publicKey,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (hasPassphrase != null) 'has_passphrase': hasPassphrase,
      if (requiresBiometrics != null) 'requires_biometrics': requiresBiometrics,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SshIdentityRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? keyType,
    Value<String>? publicKey,
    Value<String>? fingerprint,
    Value<bool>? hasPassphrase,
    Value<bool>? requiresBiometrics,
    Value<String?>? comment,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SshIdentityRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      keyType: keyType ?? this.keyType,
      publicKey: publicKey ?? this.publicKey,
      fingerprint: fingerprint ?? this.fingerprint,
      hasPassphrase: hasPassphrase ?? this.hasPassphrase,
      requiresBiometrics: requiresBiometrics ?? this.requiresBiometrics,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (keyType.present) {
      map['key_type'] = Variable<String>(keyType.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (hasPassphrase.present) {
      map['has_passphrase'] = Variable<bool>(hasPassphrase.value);
    }
    if (requiresBiometrics.present) {
      map['requires_biometrics'] = Variable<bool>(requiresBiometrics.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SshIdentityRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('keyType: $keyType, ')
          ..write('publicKey: $publicKey, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('hasPassphrase: $hasPassphrase, ')
          ..write('requiresBiometrics: $requiresBiometrics, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TerminoDatabase extends GeneratedDatabase {
  _$TerminoDatabase(QueryExecutor e) : super(e);
  $TerminoDatabaseManager get managers => $TerminoDatabaseManager(this);
  late final $SshHostRowsTable sshHostRows = $SshHostRowsTable(this);
  late final $KnownHostRowsTable knownHostRows = $KnownHostRowsTable(this);
  late final $SshIdentityRowsTable sshIdentityRows = $SshIdentityRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sshHostRows,
    knownHostRows,
    sshIdentityRows,
  ];
}

typedef $$SshHostRowsTableCreateCompanionBuilder =
    SshHostRowsCompanion Function({
      required String id,
      required String label,
      required String hostname,
      required String username,
      Value<int> port,
      Value<String?> identityId,
      Value<String> authMethods,
      Value<String?> jumpHostId,
      Value<int> keepAliveSeconds,
      Value<String?> startupCommand,
      Value<int?> colorValue,
      Value<String?> folder,
      Value<bool> hasSavedPassword,
      Value<bool> forwardAgent,
      Value<int> rowid,
    });
typedef $$SshHostRowsTableUpdateCompanionBuilder =
    SshHostRowsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> hostname,
      Value<String> username,
      Value<int> port,
      Value<String?> identityId,
      Value<String> authMethods,
      Value<String?> jumpHostId,
      Value<int> keepAliveSeconds,
      Value<String?> startupCommand,
      Value<int?> colorValue,
      Value<String?> folder,
      Value<bool> hasSavedPassword,
      Value<bool> forwardAgent,
      Value<int> rowid,
    });

class $$SshHostRowsTableFilterComposer
    extends Composer<_$TerminoDatabase, $SshHostRowsTable> {
  $$SshHostRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostname => $composableBuilder(
    column: $table.hostname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authMethods => $composableBuilder(
    column: $table.authMethods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jumpHostId => $composableBuilder(
    column: $table.jumpHostId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keepAliveSeconds => $composableBuilder(
    column: $table.keepAliveSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startupCommand => $composableBuilder(
    column: $table.startupCommand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSavedPassword => $composableBuilder(
    column: $table.hasSavedPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get forwardAgent => $composableBuilder(
    column: $table.forwardAgent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SshHostRowsTableOrderingComposer
    extends Composer<_$TerminoDatabase, $SshHostRowsTable> {
  $$SshHostRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostname => $composableBuilder(
    column: $table.hostname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authMethods => $composableBuilder(
    column: $table.authMethods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jumpHostId => $composableBuilder(
    column: $table.jumpHostId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keepAliveSeconds => $composableBuilder(
    column: $table.keepAliveSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startupCommand => $composableBuilder(
    column: $table.startupCommand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSavedPassword => $composableBuilder(
    column: $table.hasSavedPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get forwardAgent => $composableBuilder(
    column: $table.forwardAgent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SshHostRowsTableAnnotationComposer
    extends Composer<_$TerminoDatabase, $SshHostRowsTable> {
  $$SshHostRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get hostname =>
      $composableBuilder(column: $table.hostname, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authMethods => $composableBuilder(
    column: $table.authMethods,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jumpHostId => $composableBuilder(
    column: $table.jumpHostId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keepAliveSeconds => $composableBuilder(
    column: $table.keepAliveSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startupCommand => $composableBuilder(
    column: $table.startupCommand,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<bool> get hasSavedPassword => $composableBuilder(
    column: $table.hasSavedPassword,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get forwardAgent => $composableBuilder(
    column: $table.forwardAgent,
    builder: (column) => column,
  );
}

class $$SshHostRowsTableTableManager
    extends
        RootTableManager<
          _$TerminoDatabase,
          $SshHostRowsTable,
          SshHostRow,
          $$SshHostRowsTableFilterComposer,
          $$SshHostRowsTableOrderingComposer,
          $$SshHostRowsTableAnnotationComposer,
          $$SshHostRowsTableCreateCompanionBuilder,
          $$SshHostRowsTableUpdateCompanionBuilder,
          (
            SshHostRow,
            BaseReferences<_$TerminoDatabase, $SshHostRowsTable, SshHostRow>,
          ),
          SshHostRow,
          PrefetchHooks Function()
        > {
  $$SshHostRowsTableTableManager(_$TerminoDatabase db, $SshHostRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SshHostRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SshHostRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SshHostRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> hostname = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String?> identityId = const Value.absent(),
                Value<String> authMethods = const Value.absent(),
                Value<String?> jumpHostId = const Value.absent(),
                Value<int> keepAliveSeconds = const Value.absent(),
                Value<String?> startupCommand = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<bool> hasSavedPassword = const Value.absent(),
                Value<bool> forwardAgent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SshHostRowsCompanion(
                id: id,
                label: label,
                hostname: hostname,
                username: username,
                port: port,
                identityId: identityId,
                authMethods: authMethods,
                jumpHostId: jumpHostId,
                keepAliveSeconds: keepAliveSeconds,
                startupCommand: startupCommand,
                colorValue: colorValue,
                folder: folder,
                hasSavedPassword: hasSavedPassword,
                forwardAgent: forwardAgent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String hostname,
                required String username,
                Value<int> port = const Value.absent(),
                Value<String?> identityId = const Value.absent(),
                Value<String> authMethods = const Value.absent(),
                Value<String?> jumpHostId = const Value.absent(),
                Value<int> keepAliveSeconds = const Value.absent(),
                Value<String?> startupCommand = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<bool> hasSavedPassword = const Value.absent(),
                Value<bool> forwardAgent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SshHostRowsCompanion.insert(
                id: id,
                label: label,
                hostname: hostname,
                username: username,
                port: port,
                identityId: identityId,
                authMethods: authMethods,
                jumpHostId: jumpHostId,
                keepAliveSeconds: keepAliveSeconds,
                startupCommand: startupCommand,
                colorValue: colorValue,
                folder: folder,
                hasSavedPassword: hasSavedPassword,
                forwardAgent: forwardAgent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SshHostRowsTable, SshHostRow>(table),
                  BaseReferences<
                    _$TerminoDatabase,
                    $SshHostRowsTable,
                    SshHostRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SshHostRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$TerminoDatabase,
      $SshHostRowsTable,
      SshHostRow,
      $$SshHostRowsTableFilterComposer,
      $$SshHostRowsTableOrderingComposer,
      $$SshHostRowsTableAnnotationComposer,
      $$SshHostRowsTableCreateCompanionBuilder,
      $$SshHostRowsTableUpdateCompanionBuilder,
      (
        SshHostRow,
        BaseReferences<_$TerminoDatabase, $SshHostRowsTable, SshHostRow>,
      ),
      SshHostRow,
      PrefetchHooks Function()
    >;
typedef $$KnownHostRowsTableCreateCompanionBuilder =
    KnownHostRowsCompanion Function({
      Value<int> rowId,
      required String host,
      required int port,
      required String keyType,
      required String fingerprint,
      Value<String?> publicKey,
      required DateTime addedAt,
      required String source,
    });
typedef $$KnownHostRowsTableUpdateCompanionBuilder =
    KnownHostRowsCompanion Function({
      Value<int> rowId,
      Value<String> host,
      Value<int> port,
      Value<String> keyType,
      Value<String> fingerprint,
      Value<String?> publicKey,
      Value<DateTime> addedAt,
      Value<String> source,
    });

class $$KnownHostRowsTableFilterComposer
    extends Composer<_$TerminoDatabase, $KnownHostRowsTable> {
  $$KnownHostRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyType => $composableBuilder(
    column: $table.keyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KnownHostRowsTableOrderingComposer
    extends Composer<_$TerminoDatabase, $KnownHostRowsTable> {
  $$KnownHostRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyType => $composableBuilder(
    column: $table.keyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnownHostRowsTableAnnotationComposer
    extends Composer<_$TerminoDatabase, $KnownHostRowsTable> {
  $$KnownHostRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get keyType =>
      $composableBuilder(column: $table.keyType, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$KnownHostRowsTableTableManager
    extends
        RootTableManager<
          _$TerminoDatabase,
          $KnownHostRowsTable,
          KnownHostRow,
          $$KnownHostRowsTableFilterComposer,
          $$KnownHostRowsTableOrderingComposer,
          $$KnownHostRowsTableAnnotationComposer,
          $$KnownHostRowsTableCreateCompanionBuilder,
          $$KnownHostRowsTableUpdateCompanionBuilder,
          (
            KnownHostRow,
            BaseReferences<
              _$TerminoDatabase,
              $KnownHostRowsTable,
              KnownHostRow
            >,
          ),
          KnownHostRow,
          PrefetchHooks Function()
        > {
  $$KnownHostRowsTableTableManager(
    _$TerminoDatabase db,
    $KnownHostRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnownHostRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnownHostRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnownHostRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> keyType = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => KnownHostRowsCompanion(
                rowId: rowId,
                host: host,
                port: port,
                keyType: keyType,
                fingerprint: fingerprint,
                publicKey: publicKey,
                addedAt: addedAt,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String host,
                required int port,
                required String keyType,
                required String fingerprint,
                Value<String?> publicKey = const Value.absent(),
                required DateTime addedAt,
                required String source,
              }) => KnownHostRowsCompanion.insert(
                rowId: rowId,
                host: host,
                port: port,
                keyType: keyType,
                fingerprint: fingerprint,
                publicKey: publicKey,
                addedAt: addedAt,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnownHostRowsTable, KnownHostRow>(table),
                  BaseReferences<
                    _$TerminoDatabase,
                    $KnownHostRowsTable,
                    KnownHostRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnownHostRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$TerminoDatabase,
      $KnownHostRowsTable,
      KnownHostRow,
      $$KnownHostRowsTableFilterComposer,
      $$KnownHostRowsTableOrderingComposer,
      $$KnownHostRowsTableAnnotationComposer,
      $$KnownHostRowsTableCreateCompanionBuilder,
      $$KnownHostRowsTableUpdateCompanionBuilder,
      (
        KnownHostRow,
        BaseReferences<_$TerminoDatabase, $KnownHostRowsTable, KnownHostRow>,
      ),
      KnownHostRow,
      PrefetchHooks Function()
    >;
typedef $$SshIdentityRowsTableCreateCompanionBuilder =
    SshIdentityRowsCompanion Function({
      required String id,
      required String name,
      required String keyType,
      required String publicKey,
      required String fingerprint,
      Value<bool> hasPassphrase,
      Value<bool> requiresBiometrics,
      Value<String?> comment,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SshIdentityRowsTableUpdateCompanionBuilder =
    SshIdentityRowsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> keyType,
      Value<String> publicKey,
      Value<String> fingerprint,
      Value<bool> hasPassphrase,
      Value<bool> requiresBiometrics,
      Value<String?> comment,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SshIdentityRowsTableFilterComposer
    extends Composer<_$TerminoDatabase, $SshIdentityRowsTable> {
  $$SshIdentityRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyType => $composableBuilder(
    column: $table.keyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPassphrase => $composableBuilder(
    column: $table.hasPassphrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresBiometrics => $composableBuilder(
    column: $table.requiresBiometrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SshIdentityRowsTableOrderingComposer
    extends Composer<_$TerminoDatabase, $SshIdentityRowsTable> {
  $$SshIdentityRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyType => $composableBuilder(
    column: $table.keyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPassphrase => $composableBuilder(
    column: $table.hasPassphrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresBiometrics => $composableBuilder(
    column: $table.requiresBiometrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SshIdentityRowsTableAnnotationComposer
    extends Composer<_$TerminoDatabase, $SshIdentityRowsTable> {
  $$SshIdentityRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get keyType =>
      $composableBuilder(column: $table.keyType, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasPassphrase => $composableBuilder(
    column: $table.hasPassphrase,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresBiometrics => $composableBuilder(
    column: $table.requiresBiometrics,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SshIdentityRowsTableTableManager
    extends
        RootTableManager<
          _$TerminoDatabase,
          $SshIdentityRowsTable,
          SshIdentityRow,
          $$SshIdentityRowsTableFilterComposer,
          $$SshIdentityRowsTableOrderingComposer,
          $$SshIdentityRowsTableAnnotationComposer,
          $$SshIdentityRowsTableCreateCompanionBuilder,
          $$SshIdentityRowsTableUpdateCompanionBuilder,
          (
            SshIdentityRow,
            BaseReferences<
              _$TerminoDatabase,
              $SshIdentityRowsTable,
              SshIdentityRow
            >,
          ),
          SshIdentityRow,
          PrefetchHooks Function()
        > {
  $$SshIdentityRowsTableTableManager(
    _$TerminoDatabase db,
    $SshIdentityRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SshIdentityRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SshIdentityRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SshIdentityRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> keyType = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<bool> hasPassphrase = const Value.absent(),
                Value<bool> requiresBiometrics = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SshIdentityRowsCompanion(
                id: id,
                name: name,
                keyType: keyType,
                publicKey: publicKey,
                fingerprint: fingerprint,
                hasPassphrase: hasPassphrase,
                requiresBiometrics: requiresBiometrics,
                comment: comment,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String keyType,
                required String publicKey,
                required String fingerprint,
                Value<bool> hasPassphrase = const Value.absent(),
                Value<bool> requiresBiometrics = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SshIdentityRowsCompanion.insert(
                id: id,
                name: name,
                keyType: keyType,
                publicKey: publicKey,
                fingerprint: fingerprint,
                hasPassphrase: hasPassphrase,
                requiresBiometrics: requiresBiometrics,
                comment: comment,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SshIdentityRowsTable, SshIdentityRow>(table),
                  BaseReferences<
                    _$TerminoDatabase,
                    $SshIdentityRowsTable,
                    SshIdentityRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SshIdentityRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$TerminoDatabase,
      $SshIdentityRowsTable,
      SshIdentityRow,
      $$SshIdentityRowsTableFilterComposer,
      $$SshIdentityRowsTableOrderingComposer,
      $$SshIdentityRowsTableAnnotationComposer,
      $$SshIdentityRowsTableCreateCompanionBuilder,
      $$SshIdentityRowsTableUpdateCompanionBuilder,
      (
        SshIdentityRow,
        BaseReferences<
          _$TerminoDatabase,
          $SshIdentityRowsTable,
          SshIdentityRow
        >,
      ),
      SshIdentityRow,
      PrefetchHooks Function()
    >;

class $TerminoDatabaseManager {
  final _$TerminoDatabase _db;
  $TerminoDatabaseManager(this._db);
  $$SshHostRowsTableTableManager get sshHostRows =>
      $$SshHostRowsTableTableManager(_db, _db.sshHostRows);
  $$KnownHostRowsTableTableManager get knownHostRows =>
      $$KnownHostRowsTableTableManager(_db, _db.knownHostRows);
  $$SshIdentityRowsTableTableManager get sshIdentityRows =>
      $$SshIdentityRowsTableTableManager(_db, _db.sshIdentityRows);
}
