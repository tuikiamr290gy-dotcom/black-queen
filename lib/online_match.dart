import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'game_logic.dart';
import 'card_view.dart';
import 'scoreboard_storage.dart';
import 'account_storage.dart';

class OnlineMatchPage extends StatefulWidget {
  const OnlineMatchPage({super.key});

  @override
  State<OnlineMatchPage> createState() => _OnlineMatchPageState();
}

class _OnlineMatchPageState extends State<OnlineMatchPage> {
  static const String serverUrl =
      'wss://black-queen-server.onrender.com';

  final TextEditingController _nameController =
      TextEditingController();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  String _status = 'Enter your name';

  int _playersWaiting = 0;
  List<String> _waitingNames = [];

  bool _searching = false;
  bool _connected = false;
  bool _inGame = false;

  int _mySeat = 0;
  int _currentSeat = 0;
  int _dealNumber = 0;

  List<String> _playerNames = [
    'Player 1',
    'Player 2',
    'Player 3',
    'Player 4',
  ];


  List<PlayingCard> _myHand = [];

  List<Map<String, dynamic>> _trick = [];

  // True while the completed trick is still displayed.
  // During this state the next trick has not started yet,
  // so the next player must be allowed to play ANY card.
  bool _trickComplete = false;

  List<int> _scores = [
    0,
    0,
    0,
    0,
  ];

  PlayingCard? _pendingCard;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  Future<void> _loadSavedName() async {
    final savedName = await AccountStorage.loadName();
    if (!mounted || savedName == null) return;
    setState(() {
      _nameController.text = savedName;
    });
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    _subscription?.cancel();
    _channel?.sink.close();
    _nameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CONNECTION / MATCHMAKING
  // ------------------------------------------------------------

  void _findMatch() {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _status = 'Please enter your name';
      });
      return;
    }

    unawaited(AccountStorage.saveGuestName(name));

    setState(() {
      _searching = true;
      _status = 'Connecting to server...';
      _playersWaiting = 0;
      _waitingNames = [];
    });

    try {
      final channel =
          WebSocketChannel.connect(
        Uri.parse(serverUrl),
      );

      _channel = channel;

      _subscription =
          channel.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _searching = false;
            _connected = false;
            _status = 'Connection error';
          });
        },
        onDone: () {
          if (!mounted) return;

          if (!_inGame) {
            setState(() {
              _searching = false;
              _connected = false;
              _status =
                  'Disconnected from server';
            });
          }
        },
      );

      setState(() {
        _connected = true;
      });

      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (!mounted || _channel == null) {
            return;
          }

          _send({
            'type': 'find_match',
            'name': name,
          });
        },
      );
    } catch (e) {
      setState(() {
        _searching = false;
        _connected = false;
        _status =
            'Could not connect to server';
      });
    }
  }

  void _send(
    Map<String, dynamic> data,
  ) {
    _channel?.sink.add(
      jsonEncode(data),
    );
  }

  void _cancelSearch() {
    _send({
      'type': 'cancel_search',
    });

    _channel?.sink.close();

    setState(() {
      _searching = false;
      _connected = false;
      _playersWaiting = 0;
      _waitingNames = [];
      _status = 'Search cancelled';
    });
  }

  // ------------------------------------------------------------
  // SERVER MESSAGES
  // ------------------------------------------------------------

  void _handleMessage(dynamic message) {
    try {
      final data =
          jsonDecode(message.toString());

      switch (data['type']) {
        case 'connected':
          if (!mounted) return;

          setState(() {
            _connected = true;
          });
          break;

        case 'searching':
          if (!mounted) return;

          setState(() {
            _searching = true;

            _playersWaiting =
                (data['playersWaiting'] ?? 1) as int;

            final rawNames = data['playerNames'] as List?;
            _waitingNames = rawNames == null
                ? <String>[]
                : rawNames.map((e) => e.toString()).toList();

            _status = 'Waiting for players...';
          });
          break;

        case 'match_found':
          _handleMatchFound(data);
          break;

        case 'hand':
          _handleHand(data);
          break;

        case 'deal_start':
          _handleDealStart(data);
          break;

        case 'played':
          _handlePlayed(data);
          break;

        case 'trick_result':
          _handleTrickResult(data);
          break;

        case 'error':
          _handleServerError(data);
          break;

        case 'game_over':
          _handleGameOver(data);
          break;

        case 'disconnected':
          if (!mounted) return;

          setState(() {
            _status =
                'A player disconnected.';
          });

          _showDisconnected(
            data['message']?.toString() ??
                'A player disconnected.',
          );
          break;

        case 'search_cancelled':
          if (!mounted) return;

          setState(() {
            _searching = false;
            _playersWaiting = 0;
            _waitingNames = [];
            _status = 'Search cancelled';
          });
          break;
      }
    } catch (e) {
      // Ignore invalid messages.
    }
  }

  // ------------------------------------------------------------
  // MATCH FOUND
  // ------------------------------------------------------------

  void _handleMatchFound(
    Map<String, dynamic> data,
  ) {
    if (!mounted) return;

    final players =
        data['players'] as List? ?? [];

    final names = <String>[];

    for (final item in players) {
      final player =
          Map<String, dynamic>.from(
        item as Map,
      );

      final name =
          player['name']?.toString() ??
              'Player';

      names.add(name);

    }

    while (names.length < 4) {
      names.add(
        'Player ${names.length + 1}',
      );

    }

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    setState(() {
      _searching = false;
      _inGame = true;
      _status = 'Match found!';

      _mySeat =
          (data['seat'] ?? 0) as int;

      _playerNames =
          names.take(4).toList();


      _playersWaiting = 4;

      _scores = [0, 0, 0, 0];

      _myHand = [];

      _trick = [];
      _trickComplete = false;
    });

    _showMatchFound(data);
  }

  // ------------------------------------------------------------
  // HAND
  // ------------------------------------------------------------

  void _handleHand(
    Map<String, dynamic> data,
  ) {
    final rawHand =
        data['hand'] as List? ?? [];

    final hand =
        rawHand.map((item) {
      return PlayingCard.fromJson(
        Map<String, dynamic>.from(
          item as Map,
        ),
      );
    }).toList();

    // Sort only for display.
    // This does NOT restrict which card can be played.
    Rules.sortHand(hand);

    if (!mounted) return;

    setState(() {
      _myHand = hand;
      _pendingCard = null;
    });
  }

  // ------------------------------------------------------------
  // DEAL START
  // ------------------------------------------------------------

  void _handleDealStart(
    Map<String, dynamic> data,
  ) {
    final names =
        data['names'] as List?;


    if (!mounted) return;

    setState(() {
      _dealNumber =
          (data['dealNumber'] ?? 1) as int;

      _currentSeat =
          (data['currentSeat'] ?? 0) as int;

      _trick = [];
      _trickComplete = false;

      _pendingCard = null;

      if (names != null &&
          names.length >= 4) {
        _playerNames =
            names
                .take(4)
                .map(
                  (e) => e.toString(),
                )
                .toList();
      }


      _updateTurnStatus();
    });
  }

  // ------------------------------------------------------------
  // CARD PLAYED
  // ------------------------------------------------------------

  void _handlePlayed(
    Map<String, dynamic> data,
  ) {
    final rawTrick =
        data['trick'] as List? ?? [];

    final trick =
        rawTrick.map((item) {
      return Map<String, dynamic>.from(
        item as Map,
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      _trick = trick;
      _trickComplete = false;

      _currentSeat =
          (data['currentSeat'] ?? 0) as int;

      _pendingCard = null;

      _updateTurnStatus();
    });
  }

  // ------------------------------------------------------------
  // TRICK RESULT
  // ------------------------------------------------------------

  void _handleTrickResult(
    Map<String, dynamic> data,
  ) {
    final rawTrick =
        data['trick'] as List? ?? [];

    final trick =
        rawTrick.map((item) {
      return Map<String, dynamic>.from(
        item as Map,
      );
    }).toList();

    final scores =
        (data['scores'] as List? ?? [])
            .map(
              (e) => (e as num).toInt(),
            )
            .toList();

    if (!mounted) return;

    setState(() {
      // Keep the completed trick visible.
      _trick = trick;
      _trickComplete = true;

      if (scores.length >= 4) {
        _scores =
            scores.take(4).toList();
      }

      _currentSeat =
          (data['currentSeat'] ?? 0) as int;

      _pendingCard = null;

      _updateTurnStatus();
    });
  }

  // ------------------------------------------------------------
  // PLAY CARD
  // ------------------------------------------------------------

  bool _isLegalCard(
    PlayingCard card,
  ) {
    if (_currentSeat != _mySeat) {
      return false;
    }

    // No active trick, or the previous trick has just finished.
    // The next trick starter may play ANY card.
    if (_trick.isEmpty || _trickComplete) {
      return true;
    }

    final firstCard = _trick.first['card'];

    if (firstCard is! Map) {
      return true;
    }

    final suitIndex = firstCard['s'];

    if (suitIndex is! int) {
      return true;
    }

    if (suitIndex < 0 ||
        suitIndex >= Suit.values.length) {
      return true;
    }

    final ledSuit = Suit.values[suitIndex];

    // Use the exact same rule as game_logic.dart.
    final legalCards =
        Rules.legalCards(
      _myHand,
      ledSuit,
    );

    return legalCards.contains(card);
  }

  void _playCard(
    PlayingCard card,
  ) {
    if (!_inGame) return;

    // Only ONE card can be submitted at a time.
    // This prevents a fast double-tap from sending
    // two play messages before the server responds.
    if (_pendingCard != null) {
      return;
    }

    if (_currentSeat != _mySeat) {
      return;
    }

    if (!_isLegalCard(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must follow the lead suit if you have one.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _myHand.remove(card);
      _pendingCard = card;
      _status =
          'Waiting for other players...';
    });

    _send({
      'type': 'play',
      'card': card.toJson(),
    });
  }

  // ------------------------------------------------------------
  // SERVER ERROR
  // ------------------------------------------------------------

  void _handleServerError(
    Map<String, dynamic> data,
  ) {
    final message =
        data['message']?.toString() ??
            'Invalid move.';

    // If the server rejected the card,
    // put it back into our hand.
    if (_pendingCard != null) {
      final card = _pendingCard!;

      if (!_myHand.contains(card)) {
        setState(() {
          _myHand.add(card);
          Rules.sortHand(_myHand);
        });
      }

      _pendingCard = null;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    _updateTurnStatus();
  }

  // ------------------------------------------------------------
  // GAME OVER
  // ------------------------------------------------------------

  void _handleGameOver(
    Map<String, dynamic> data,
  ) {
    if (!mounted) return;

    final scores =
        (data['scores'] as List? ?? [])
            .map(
              (e) => (e as num).toInt(),
            )
            .toList();

    final winnerName =
        data['winnerName']?.toString() ??
            'Player';

    final players =
        data['players'] as List?;

    if (scores.length >= 4) {
      _scores =
          scores.take(4).toList();
    }

    if (players != null &&
        players.length >= 4) {
      _playerNames =
          players
              .map((item) {
                final map =
                    Map<String, dynamic>.from(
                  item as Map,
                );

                return map['name']
                        ?.toString() ??
                    'Player';
              })
              .take(4)
              .toList();
    }

    final savedPlayers =
        List<String>.from(_playerNames);

    unawaited(
      ScoreboardStorage.saveGame(
        mode: 'Online',
        myName:
            _mySeat < savedPlayers.length
                ? savedPlayers[_mySeat]
                : 'You',
        myScore:
            _mySeat < _scores.length
                ? _scores[_mySeat]
                : 0,
        players: savedPlayers,
        scores: List<int>.from(_scores),
      ),
    );

    setState(() {
      _status = 'Game Over';
    });

    _showGameOver(
      winnerName,
      _scores,
    );
  }

  // ------------------------------------------------------------
  // TURN STATUS
  // ------------------------------------------------------------

  void _updateTurnStatus() {
    if (_currentSeat == _mySeat) {
      _status = 'Your turn';
    } else if (_currentSeat >= 0 &&
        _currentSeat <
            _playerNames.length) {
      _status =
          '${_playerNames[_currentSeat]} is playing';
    } else {
      _status = 'Waiting...';
    }
  }

  // ------------------------------------------------------------
  // MATCH FOUND DIALOG
  // ------------------------------------------------------------

  void _showMatchFound(
    Map<String, dynamic> data,
  ) {
    final players =
        data['players'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Text('Match Found!'),
            ],
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                '4 players have been matched.',
              ),
              const SizedBox(height: 16),
              for (final player
                  in players)
                ListTile(
                  dense: true,
                  leading:
                      const Icon(
                    Icons.person,
                  ),
                  title: Text(
                    player['name']
                            ?.toString() ??
                        'Player',
                  ),
                  subtitle: Text(
                    'Seat ${(player['seat'] ?? 0) + 1}',
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('CONTINUE'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // GAME OVER DIALOG
  // ------------------------------------------------------------

  void _showGameOver(
    String winnerName,
    List<int> scores,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
              ),
              SizedBox(width: 10),
              Text('GAME OVER'),
            ],
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                'Winner: $winnerName',
                style:
                    const TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              for (int i = 0;
                  i < scores.length;
                  i++)
                ListTile(
                  dense: true,
                  leading:
                      const Icon(
                    Icons.person,
                  ),
                  title: Text(
                    i <
                            _playerNames
                                .length
                        ? _playerNames[i]
                        : 'Player ${i + 1}',
                  ),
                  trailing: Text(
                    '${scores[i]} points',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'The player with the lowest score wins.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'BACK TO HOME',
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DISCONNECTED
  // ------------------------------------------------------------

  void _showDisconnected(
    String message,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Player Disconnected',
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // OPPONENT
  // ------------------------------------------------------------

  Widget _buildOpponent(
    int seat,
  ) {
    final isCurrent =
        _currentSeat == seat;

    final name =
        seat < _playerNames.length
            ? _playerNames[seat]
            : 'Player';

    final score =
        seat < _scores.length
            ? _scores[seat]
            : 0;

    return Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.amber
                : Colors.black54,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            '$name  •  $score',
            style:
                TextStyle(
              color: isCurrent
                  ? Colors.black
                  : Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize:
              MainAxisSize.min,
          children: List.generate(
            5,
            (_) => Container(
              width: 27,
              height: 40,
              margin:
                  const EdgeInsets
                      .symmetric(
                horizontal: 2,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.blue.shade900,
                borderRadius:
                    BorderRadius.circular(
                  4,
                ),
                border: Border.all(
                  color: Colors.white54,
                ),
              ),
              child: const Center(
                child: Text(
                  '♠',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // CARD ON TABLE
  // ------------------------------------------------------------

  Widget _buildTrickCard(
    int seat,
  ) {
    for (final played
        in _trick) {
      final playedSeat =
          (played['seat'] ?? -1)
              as int;

      if (playedSeat == seat) {
        final card =
            PlayingCard.fromJson(
          Map<String, dynamic>.from(
            played['card'] as Map,
          ),
        );

        return CardView(
          card: card,
          width: 52,
          height: 74,
        );
      }
    }

    return const SizedBox(
      width: 52,
      height: 74,
    );
  }

  // ------------------------------------------------------------
  // MY HAND
  // ------------------------------------------------------------

  Widget _buildHand() {
    // Disable the entire hand immediately after one card is tapped.
    // It becomes active again when the server confirms the play
    // (or sends an error and the card is returned).
    final canPlay =
        _currentSeat == _mySeat &&
        _pendingCard == null;

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        itemCount:
            _myHand.length,
        itemBuilder:
            (context, index) {
          final card =
              _myHand[index];

          final legal =
              canPlay &&
              _isLegalCard(card);

          return Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 2,
            ),
            child: CardView(
              card: card,
              width: 52,
              height: 74,
              dimmed: !legal,
              onTap: legal
                  ? () => _playCard(card)
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // TRICK AREA
  // ------------------------------------------------------------

  Widget _buildTrickArea() {
    return Stack(
      alignment:
          Alignment.center,
      children: [
        Align(
          alignment:
              const Alignment(
            0,
            0.75,
          ),
          child:
              _buildTrickCard(
            _mySeat,
          ),
        ),
        Align(
          alignment:
              const Alignment(
            0.75,
            0,
          ),
          child:
              _buildTrickCard(
            (_mySeat + 1) % 4,
          ),
        ),
        Align(
          alignment:
              const Alignment(
            0,
            -0.75,
          ),
          child:
              _buildTrickCard(
            (_mySeat + 2) % 4,
          ),
        ),
        Align(
          alignment:
              const Alignment(
            -0.75,
            0,
          ),
          child:
              _buildTrickCard(
            (_mySeat + 3) % 4,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // GAME TABLE
  // ------------------------------------------------------------

  Widget _buildTable() {
    return Scaffold(
      backgroundColor:
          Colors.green.shade900,
      appBar: AppBar(
        title: Text(
          'Black Queen • Deal $_dealNumber',
        ),
        automaticallyImplyLeading:
            false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 8,
            ),

            // SCORE BAR
            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
              ),
              child: Row(
                children: [
                  for (int i = 0;
                      i < 4;
                      i++)
                    Container(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            i == _mySeat
                                ? Colors
                                    .amber
                                : Colors
                                    .black54,
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child: Text(
                        '${_playerNames[i]}: ${_scores[i]}',
                        style:
                            TextStyle(
                          color:
                              i == _mySeat
                                  ? Colors
                                      .black
                                  : Colors
                                      .white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _status,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // TOP PLAYER
            _buildOpponent(
              (_mySeat + 2) % 4,
            ),

            const SizedBox(
              height: 8,
            ),

            // TABLE
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child:
                          _buildOpponent(
                        (_mySeat + 3) % 4,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Container(
                      margin:
                          const EdgeInsets
                              .all(8),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.green.shade800,
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                        border:
                            Border.all(
                          color: Colors
                              .white24,
                        ),
                      ),
                      child:
                          _buildTrickArea(),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child:
                          _buildOpponent(
                        (_mySeat + 1) % 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MY PLAYER
            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 4,
              ),
              child: Column(
                children: [
                  Text(
                    '${_playerNames[_mySeat]}  •  ${_scores[_mySeat]} points',
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  _buildHand(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_inGame) {
      return _buildTable();
    }

    return Scaffold(
      backgroundColor:
          Colors.green.shade900,
      appBar: AppBar(
        title:
            const Text('Find Match'),
      ),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.public,
                    size: 80,
                    color: Colors.white,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'FIND MATCH',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    _status,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  TextField(
                    controller:
                        _nameController,
                    enabled:
                        !_searching,
                    onChanged: (_) {
                      if (mounted) setState(() {});
                    },
                    textInputAction:
                        TextInputAction
                            .done,
                    decoration:
                        InputDecoration(
                      filled: true,
                      fillColor:
                          Colors.white,
                      labelText:
                          'Your Name',
                      hintText:
                          'Enter your name',
                      prefixIcon:
                          const Icon(
                        Icons.person,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  if (_searching) ...[
                    const CircularProgressIndicator(
                      color:
                          Colors.white,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'PLAYERS WAITING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < 4; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Icon(
                                    i < _waitingNames.length
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: i < _waitingNames.length
                                        ? Colors.greenAccent
                                        : Colors.white54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      i < _waitingNames.length
                                          ? _waitingNames[i]
                                          : 'Waiting for player ${i + 1}...',
                                      style: TextStyle(
                                        color: i < _waitingNames.length
                                            ? Colors.white
                                            : Colors.white54,
                                        fontSize: 16,
                                        fontWeight: i < _waitingNames.length
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '$_playersWaiting / 4 players',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          OutlinedButton(
                        onPressed:
                            _cancelSearch,
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              Colors
                                  .white,
                          side:
                              const BorderSide(
                            color:
                                Colors
                                    .white,
                          ),
                        ),
                        child:
                            const Text(
                          'CANCEL SEARCH',
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width:
                          double.infinity,
                      height: 56,
                      child:
                          FilledButton
                              .icon(
                        onPressed: _nameController.text.trim().isEmpty
                            ? null
                            : _findMatch,
                        icon:
                            const Icon(
                          Icons.search,
                        ),
                        label:
                            const Text(
                          'FIND MATCH',
                          style:
                              TextStyle(
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 25,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        _connected
                            ? Icons
                                .cloud_done
                            : Icons
                                .cloud_off,
                        color: _connected
                            ? Colors
                                .greenAccent
                            : Colors
                                .white54,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        _connected
                            ? 'Server connected'
                            : 'Server not connected',
                        style:
                            const TextStyle(
                          color: Colors
                              .white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
