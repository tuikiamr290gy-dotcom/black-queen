import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'bot_player.dart';
import 'game_logic.dart';

const int gamePort = 5050;

String encodeMessage(Map<String, dynamic> message) => '${jsonEncode(message)}\n';

Map<String, dynamic> cardMsg(PlayingCard card) => card.toJson();

PlayingCard cardFromMsg(Map<String, dynamic> json) => PlayingCard.fromJson(json);

/// One seat at the table: who is sitting there.
class SeatInfo {
  final int seat;
  String name;
  bool isBot;
  bool connected;

  SeatInfo(this.seat, {this.name = '', this.isBot = true, this.connected = false});
}

/// Something a screen can send moves to and listen to events from,
/// whether it is the host's own seat or a phone that joined over wifi.
abstract class GameLink {
  Stream<Map<String, dynamic>> get events;
  void play(PlayingCard card);
  void nextDeal();
  void dispose();
}

/// Runs on the host's phone. Holds the real cards and talks to the other phones.
class HostServer {
  final BlackQueenGame game = BlackQueenGame();
  final BotPlayer bot = BotPlayer(level: BotLevel.hard);

  ServerSocket? _server;
  final List<Socket?> _sockets = List.filled(4, null);
  final List<SeatInfo> seats = List.generate(
      4, (i) => SeatInfo(i, name: i == 0 ? 'Host' : 'Bot $i', isBot: i != 0, connected: i == 0));

  final _lobbyController = StreamController<List<SeatInfo>>.broadcast();
  Stream<List<SeatInfo>> get lobbyUpdates => _lobbyController.stream;

  bool _dealStarted = false;

  // The host's own screen listens to this, exactly like a joined phone would.
  late final StreamController<Map<String, dynamic>> _selfController =
      StreamController<Map<String, dynamic>>.broadcast(onListen: _beginIfNeeded);

  Future<String?> start() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, gamePort);
    _server!.listen(_onConnect);
    return _findLocalAddress();
  }

  Future<String?> _findLocalAddress() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return null;
  }

  void _onConnect(Socket socket) {
    final freeSeat = seats.skip(1).firstWhere((s) => !s.connected, orElse: () => SeatInfo(-1));
    if (freeSeat.seat == -1) {
      socket.write(encodeMessage({'type': 'error', 'message': 'Table is full.'}));
      socket.close();
      return;
    }
    final seat = freeSeat.seat;
    _sockets[seat] = socket;

    final lines = socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter());
    lines.listen((line) => _onMessage(seat, line), onDone: () => _onDisconnect(seat));

    socket.write(encodeMessage({'type': 'welcome', 'seat': seat}));
  }

  void _onDisconnect(int seat) {
    _sockets[seat] = null;
    seats[seat]
      ..connected = false
      ..isBot = true
      ..name = 'Bot $seat';
    _lobbyController.add(seats);
  }

  void _onMessage(int seat, String line) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (message['type']) {
      case 'join':
        final name = message['name'] as String?;
        seats[seat]
          ..name = (name != null && name.trim().isNotEmpty) ? name : 'Player $seat'
          ..isBot = false
          ..connected = true;
        _lobbyController.add(seats);
        break;
      case 'play':
        _applyMove(seat, cardFromMsg(message['card'] as Map<String, dynamic>));
        break;
    }
  }

  void playSeat0(PlayingCard card) => _applyMove(0, card);

  GameLink selfLink() => _SelfLink(this);

  void _sendTo(int seat, Map<String, dynamic> message) {
    if (seat == 0) {
      _selfController.add(message);
    } else {
      _sockets[seat]?.write(encodeMessage(message));
    }
  }

  void _broadcast(Map<String, dynamic> message) {
    for (var seat = 0; seat < 4; seat++) {
      _sendTo(seat, message);
    }
  }

  void _beginIfNeeded() {
    if (_dealStarted) return;
    _dealStarted = true;
    _startDeal();
  }

  void _startDeal() {
    game.startDeal();
    _broadcast({
      'type': 'deal_start',
      'dealNumber': game.dealNumber,
      'currentSeat': game.currentSeat,
      'names': seats.map((s) => s.name).toList(),
    });
    for (var seat = 0; seat < 4; seat++) {
      _sendTo(seat, {'type': 'hand', 'hand': game.hands[seat].map(cardMsg).toList()});
    }
    _continue();
  }

  void _applyMove(int seat, PlayingCard card) {
    if (seat != game.currentSeat) return;
    final error = game.playCard(seat, card);
    if (error != null) {
      _sendTo(seat, {'type': 'error', 'message': error});
      return;
    }
    _afterMove();
  }

  void _afterMove() {
    if (game.trick.isNotEmpty) {
      _broadcast({
        'type': 'played',
        'trick': game.trick.map((p) => {'seat': p.seat, 'card': cardMsg(p.card)}).toList(),
        'currentSeat': game.currentSeat,
      });
    } else {
      _broadcast({
        'type': 'trick_result',
        'trick': game.lastTrick.map((p) => {'seat': p.seat, 'card': cardMsg(p.card)}).toList(),
        'winner': game.lastTrickWinner,
        'points': game.lastTrickPoints,
        'scores': game.scores,
        'dealOver': game.dealOver,
        'currentSeat': game.currentSeat,
      });
    }
    _continue();
  }

  void _continue() {
    if (game.dealOver) return;
    final seat = game.currentSeat;
    if (!seats[seat].isBot) return;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (game.dealOver) return;
      _applyMove(seat, bot.chooseCard(game, seat));
    });
  }

  void dispose() {
    _server?.close();
    for (final s in _sockets) {
      s?.close();
    }
    _lobbyController.close();
    _selfController.close();
  }
}

class _SelfLink implements GameLink {
  final HostServer host;
  _SelfLink(this.host);

  @override
  Stream<Map<String, dynamic>> get events => host._selfController.stream;

  @override
  void play(PlayingCard card) => host.playSeat0(card);

  @override
  void nextDeal() => host._startDeal();

  @override
  void dispose() {}
}

/// Runs on a joining phone. Talks to the host over the shared wifi hotspot.
class GameClient implements GameLink {
  Socket? _socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Every message received so far, in order. Used to catch a screen up
  /// on anything it missed while it was still being built.
  final List<Map<String, dynamic>> log = [];

  @override
  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect(String address, String name) async {
    final socket = await Socket.connect(address, gamePort, timeout: const Duration(seconds: 8));
    _socket = socket;
    final lines = socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter());
    lines.listen(
      (line) {
        try {
          final decoded = jsonDecode(line) as Map<String, dynamic>;
          log.add(decoded);
          _controller.add(decoded);
        } catch (_) {}
      },
      onDone: () => _controller.add({'type': 'disconnected'}),
    );
    socket.write(encodeMessage({'type': 'join', 'name': name}));
  }

  @override
  void play(PlayingCard card) => _socket?.write(encodeMessage({'type': 'play', 'card': cardMsg(card)}));

  @override
  void nextDeal() {} // Only the host can start the next deal.

  @override
  void dispose() {
    _socket?.close();
    _controller.close();
  }
}
