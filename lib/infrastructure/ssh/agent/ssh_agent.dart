/// The system SSH agent, where there is one to talk to.
///
/// The agent lives behind a Unix socket, which needs `dart:io`; a plain import
/// would break the web compile rather than fail at runtime. The web resolves to
/// a stub that answers "no agent here", which is the truth — the agent is on
/// the user's own machine, and a relay does not reach it.
library;

export 'ssh_agent_stub.dart' if (dart.library.io) 'ssh_agent_io.dart';
