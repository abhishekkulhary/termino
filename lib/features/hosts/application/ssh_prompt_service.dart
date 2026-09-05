import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/features/hosts/presentation/host_key_dialogs.dart';
import 'package:termino/features/hosts/presentation/ssh_prompt_dialogs.dart';

part 'ssh_prompt_service.g.dart';

/// Everything an SSH connection may need to ask a human.
///
/// An interface rather than direct dialog calls so that tests — and, later, a
/// headless mode — can answer without a widget tree. The default
/// implementation shows dialogs on the root navigator.
abstract class SshPromptService {
  /// Asks whether to trust a host key that is not on record.
  Future<bool> confirmHostKey(HostKeyCheck check);

  /// Tells the user a key has changed. Never offers to connect.
  Future<HostKeyMismatchChoice> reportHostKeyMismatch(HostKeyCheck check);

  /// Asks for a login password.
  Future<String?> requestPassword(SshHost host);

  /// Asks for the passphrase protecting a private key.
  Future<String?> requestPassphrase(SshIdentity identity);

  /// Answers a keyboard-interactive challenge.
  Future<List<String>?> requestUserInfo(
    SshHost host,
    SSHUserInfoRequest request,
  );
}

/// The navigator dialogs are shown on.
///
/// Held here so that a connection, which has no `BuildContext` of its own, can
/// still ask the user something.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shows real dialogs.
class DialogSshPromptService implements SshPromptService {
  /// Creates a prompt service driving [navigatorKey].
  const new(this.navigatorKey);

  /// The navigator to present on.
  final GlobalKey<NavigatorState> navigatorKey;

  BuildContext? get _context => navigatorKey.currentContext;

  @override
  Future<bool> confirmHostKey(HostKeyCheck check) async {
    final context = _context;
    // No UI attached means nobody can answer, and the safe answer is no.
    if (context == null) return false;
    return await showTrustHostKeyDialog(context, check);
  }

  @override
  Future<HostKeyMismatchChoice> reportHostKeyMismatch(
    HostKeyCheck check,
  ) async {
    final context = _context;
    if (context == null) return HostKeyMismatchChoice.cancel;
    return await showHostKeyMismatchDialog(context, check);
  }

  @override
  Future<String?> requestPassword(SshHost host) async {
    final context = _context;
    if (context == null) return null;
    return await showSecretPromptDialog(
      context,
      title: 'Password',
      message: 'Enter the password for ${host.target}.',
      label: 'Password',
    );
  }

  @override
  Future<String?> requestPassphrase(SshIdentity identity) async {
    final context = _context;
    if (context == null) return null;
    return await showSecretPromptDialog(
      context,
      title: 'Key passphrase',
      message: '${identity.name} is protected by a passphrase.',
      label: 'Passphrase',
    );
  }

  @override
  Future<List<String>?> requestUserInfo(
    SshHost host,
    SSHUserInfoRequest request,
  ) async {
    final context = _context;
    if (context == null) return null;
    return await showUserInfoDialog(context, host: host, request: request);
  }
}

/// The prompt service in use. Overridden in tests.
@Riverpod(keepAlive: true)
SshPromptService sshPromptService(Ref ref) =>
    DialogSshPromptService(rootNavigatorKey);
