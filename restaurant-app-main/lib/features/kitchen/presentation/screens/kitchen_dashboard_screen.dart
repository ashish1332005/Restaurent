import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';

class KitchenDashboardScreen extends StatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  late final Timer _ticker;
  late final TextEditingController _searchController;
  late List<_KitchenTicket> _tickets;
  _KitchenStationFilter _selectedStation = _KitchenStationFilter.all;
  _KitchenSortMode _sortMode = _KitchenSortMode.oldest;
  String _searchQuery = '';
  bool _rushOnly = false;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tickets = [..._ticketsFromLiveOrders(), ..._buildSeedTickets()];
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<_KitchenTicket> _ticketsFromLiveOrders() {
    final orders = LocalStorage.getActiveOrders();
    return orders.map((order) {
      final rawItems = (order['items'] as List?) ?? const [];
      final status = switch (order['status']?.toString()) {
        'Preparing' => _KitchenTicketStatus.preparing,
        'Ready' => _KitchenTicketStatus.ready,
        'Served' || 'Completed' => _KitchenTicketStatus.completed,
        _ => _KitchenTicketStatus.newOrder,
      };
      final createdAt =
          DateTime.tryParse(order['createdAt']?.toString() ?? '') ??
          DateTime.now();
      return _KitchenTicket.seed(
        id: order['id']?.toString() ?? 'qr-${createdAt.millisecondsSinceEpoch}',
        orderId: order['id']?.toString() ?? 'QR Order',
        tableLabel: order['tableNo']?.toString() ?? 'Table QR',
        customerName: order['waiterName']?.toString() ?? 'Customer QR',
        channelLabel: 'QR Order',
        assignedChef: 'Kitchen Team',
        station: _KitchenStation.expo,
        priority: _KitchenPriority.rush,
        status: status,
        placedAt: createdAt,
        slaMinutes: 15,
        kitchenNote: order['notes']?.toString() ?? '',
        items: rawItems.whereType<Map>().map((item) {
          return _KitchenTicketItem(
            name:
                item['name']?.toString() ??
                item['title']?.toString() ??
                'Menu Item',
            quantity:
                (item['qty'] as num?)?.toInt() ??
                (item['quantity'] as num?)?.toInt() ??
                1,
          );
        }).toList(),
      );
    }).toList();
  }

  List<_KitchenTicket> get _activeTickets {
    return _filteredTickets(includeCompleted: false);
  }

  List<_KitchenTicket> get _completedTickets {
    return _filteredTickets(includeCompleted: true)
        .where((ticket) => ticket.status == _KitchenTicketStatus.completed)
        .toList();
  }

  List<_KitchenTicket> _ticketsFor(_KitchenTicketStatus status) {
    final source = status == _KitchenTicketStatus.completed
        ? _completedTickets
        : _activeTickets;
    return source.where((ticket) => ticket.status == status).toList();
  }

  int get _urgentCount {
    return _activeTickets
        .where((ticket) => _elapsedMinutes(ticket) >= ticket.slaMinutes)
        .length;
  }

  int get _readyCount {
    return _ticketsFor(_KitchenTicketStatus.ready).length;
  }

  int get _queueCount {
    return _ticketsFor(_KitchenTicketStatus.newOrder).length;
  }

  int get _completedCount {
    return _tickets
        .where((ticket) => ticket.status == _KitchenTicketStatus.completed)
        .length;
  }

  int get _averageAgeMinutes {
    if (_activeTickets.isEmpty) {
      return 0;
    }

    final totalMinutes = _activeTickets
        .map(_elapsedMinutes)
        .fold<int>(0, (sum, value) => sum + value);
    return (totalMinutes / _activeTickets.length).round();
  }

  int get _fireCount {
    return _activeTickets
        .where((ticket) => ticket.priority == _KitchenPriority.fire)
        .length;
  }

  _KitchenTicket? get _expediteTicket {
    final candidates = _activeTickets.where((ticket) {
      return ticket.status != _KitchenTicketStatus.completed &&
          _elapsedMinutes(ticket) >= ticket.slaMinutes;
    }).toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) => left.placedAt.compareTo(right.placedAt));
    return candidates.first;
  }

  bool get _hasFiltersApplied {
    return _selectedStation != _KitchenStationFilter.all ||
        _searchQuery.trim().isNotEmpty ||
        _rushOnly ||
        _sortMode != _KitchenSortMode.oldest ||
        _showCompleted;
  }

  List<_KitchenBoardColumnData> get _boardColumns {
    return [
      const _KitchenBoardColumnData(
        title: 'New Orders',
        subtitle: 'Accept and start cooking',
        accent: Color(0xFFF97316),
        status: _KitchenTicketStatus.newOrder,
        emptyLabel: 'No new tickets waiting.',
      ),
      const _KitchenBoardColumnData(
        title: 'Preparing',
        subtitle: 'Monitor active prep stations',
        accent: Color(0xFF3B82F6),
        status: _KitchenTicketStatus.preparing,
        emptyLabel: 'Prep line is clear.',
      ),
      const _KitchenBoardColumnData(
        title: 'Ready',
        subtitle: 'Awaiting pickup or service',
        accent: Color(0xFF22C55E),
        status: _KitchenTicketStatus.ready,
        emptyLabel: 'Nothing waiting for handoff.',
      ),
      if (_showCompleted)
        const _KitchenBoardColumnData(
          title: 'Completed',
          subtitle: 'Recent handoffs and reopened items',
          accent: Color(0xFF94A3B8),
          status: _KitchenTicketStatus.completed,
          emptyLabel: 'No completed tickets in this view.',
        ),
    ];
  }

  int _elapsedMinutes(_KitchenTicket ticket) {
    return DateTime.now().difference(ticket.placedAt).inMinutes;
  }

  int _slaDeltaMinutes(_KitchenTicket ticket) {
    return ticket.slaMinutes - _elapsedMinutes(ticket);
  }

  String _formatElapsed(_KitchenTicket ticket) {
    final difference = DateTime.now().difference(ticket.placedAt);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '${minutes}m ${seconds}s';
  }

  String _formatNow(BuildContext context) {
    final now = TimeOfDay.fromDateTime(DateTime.now());
    return now.format(context);
  }

  String _formatClockTime(DateTime time, BuildContext context) {
    return TimeOfDay.fromDateTime(time).format(context);
  }

  List<_KitchenTicket> _filteredTickets({required bool includeCompleted}) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _tickets.where((ticket) {
      if (!includeCompleted &&
          ticket.status == _KitchenTicketStatus.completed) {
        return false;
      }

      final matchesStation =
          _selectedStation == _KitchenStationFilter.all ||
          ticket.station == _selectedStation.station;
      final matchesSearch =
          query.isEmpty ||
          ticket.orderId.toLowerCase().contains(query) ||
          ticket.tableLabel.toLowerCase().contains(query) ||
          ticket.customerName.toLowerCase().contains(query) ||
          ticket.channelLabel.toLowerCase().contains(query) ||
          ticket.assignedChef.toLowerCase().contains(query) ||
          ticket.items.any(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                item.notes.toLowerCase().contains(query),
          );
      final matchesPriority =
          !_rushOnly || ticket.priority != _KitchenPriority.normal;

      return matchesStation && matchesSearch && matchesPriority;
    }).toList()..sort(_compareTickets);

    return filtered;
  }

  int _compareTickets(_KitchenTicket left, _KitchenTicket right) {
    switch (_sortMode) {
      case _KitchenSortMode.oldest:
        return left.placedAt.compareTo(right.placedAt);
      case _KitchenSortMode.slaRisk:
        final riskOrder = _slaDeltaMinutes(
          left,
        ).compareTo(_slaDeltaMinutes(right));
        if (riskOrder != 0) {
          return riskOrder;
        }
        return left.placedAt.compareTo(right.placedAt);
      case _KitchenSortMode.priority:
        final priorityOrder = right.priority.rank.compareTo(left.priority.rank);
        if (priorityOrder != 0) {
          return priorityOrder;
        }
        return left.placedAt.compareTo(right.placedAt);
    }
  }

  void _showActionMessage(
    String message, {
    Color backgroundColor = const Color(0xFF0F172A),
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout from Kitchen?'),
        content: const Text(
          'You will need to sign in again to access the kitchen display.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await LocalStorage.clearToken();
    if (mounted) context.go('/login');
  }

  void _updateTicket(
    _KitchenTicket ticket,
    _KitchenTicket Function(_KitchenTicket current) update, {
    String? message,
    Color? messageColor,
  }) {
    _KitchenTicket? updatedTicket;

    setState(() {
      _tickets = _tickets.map((current) {
        if (current.id != ticket.id) {
          return current;
        }

        updatedTicket = update(current);
        return updatedTicket!;
      }).toList();
    });

    if (message != null && updatedTicket != null) {
      _showActionMessage(
        message,
        backgroundColor: messageColor ?? _statusColor(updatedTicket!.status),
      );
    }
  }

  _KitchenTicket _ticketWithStatus(
    _KitchenTicket current,
    _KitchenTicketStatus status, {
    required String eventTitle,
    required String eventDetail,
  }) {
    final now = DateTime.now();
    DateTime? prepStartedAt = current.prepStartedAt;
    DateTime? readyAt = current.readyAt;
    DateTime? completedAt = current.completedAt;

    switch (status) {
      case _KitchenTicketStatus.newOrder:
        prepStartedAt = null;
        readyAt = null;
        completedAt = null;
        break;
      case _KitchenTicketStatus.preparing:
        prepStartedAt ??= now;
        readyAt = null;
        completedAt = null;
        break;
      case _KitchenTicketStatus.ready:
        prepStartedAt ??= now;
        readyAt = now;
        completedAt = null;
        break;
      case _KitchenTicketStatus.completed:
        prepStartedAt ??= now;
        readyAt ??= now;
        completedAt = now;
        break;
    }

    return current.copyWith(
      status: status,
      prepStartedAt: prepStartedAt,
      readyAt: readyAt,
      completedAt: completedAt,
      timeline: [
        ...current.timeline,
        _KitchenTicketEvent(
          timestamp: now,
          title: eventTitle,
          detail: eventDetail,
        ),
      ],
    );
  }

  void _moveForward(_KitchenTicket ticket) {
    switch (ticket.status) {
      case _KitchenTicketStatus.newOrder:
        _updateTicket(
          ticket,
          (current) => _ticketWithStatus(
            current,
            _KitchenTicketStatus.preparing,
            eventTitle: 'Prep started',
            eventDetail:
                '${current.assignedChef} started work at ${current.station.label}.',
          ),
          message: '${ticket.orderId} moved to preparing.',
          messageColor: const Color(0xFF1D4ED8),
        );
        return;
      case _KitchenTicketStatus.preparing:
        _updateTicket(
          ticket,
          (current) => _ticketWithStatus(
            current,
            _KitchenTicketStatus.ready,
            eventTitle: 'Marked ready',
            eventDetail: 'Order is ready for pass, pickup, or table service.',
          ),
          message: '${ticket.orderId} is ready for service.',
          messageColor: const Color(0xFF15803D),
        );
        return;
      case _KitchenTicketStatus.ready:
        _updateTicket(
          ticket,
          (current) => _ticketWithStatus(
            current,
            _KitchenTicketStatus.completed,
            eventTitle: 'Handoff completed',
            eventDetail: 'Order was handed to service or dispatch.',
          ),
          message: '${ticket.orderId} completed handoff.',
          messageColor: const Color(0xFF334155),
        );
        return;
      case _KitchenTicketStatus.completed:
        _reopenTicket(ticket);
        return;
    }
  }

  void _moveBackward(_KitchenTicket ticket) {
    switch (ticket.status) {
      case _KitchenTicketStatus.newOrder:
        _showActionMessage(
          '${ticket.orderId} is already at the front of the queue.',
          backgroundColor: const Color(0xFF9A3412),
        );
        return;
      case _KitchenTicketStatus.preparing:
        _updateTicket(
          ticket,
          (current) => _ticketWithStatus(
            current,
            _KitchenTicketStatus.newOrder,
            eventTitle: 'Moved back to queue',
            eventDetail:
                'Prep was paused and the ticket was returned to the new orders lane.',
          ),
          message: '${ticket.orderId} moved back to new orders.',
          messageColor: const Color(0xFF9A3412),
        );
        return;
      case _KitchenTicketStatus.ready:
        _updateTicket(
          ticket,
          (current) => _ticketWithStatus(
            current,
            _KitchenTicketStatus.preparing,
            eventTitle: 'Returned to kitchen',
            eventDetail: 'The ready order was sent back for another prep pass.',
          ),
          message: '${ticket.orderId} returned to preparing.',
          messageColor: const Color(0xFF1D4ED8),
        );
        return;
      case _KitchenTicketStatus.completed:
        _reopenTicket(ticket);
        return;
    }
  }

  void _toggleRushOnly(bool value) {
    setState(() {
      _rushOnly = value;
    });
  }

  void _changeStation(_KitchenStationFilter station) {
    setState(() {
      _selectedStation = station;
    });
  }

  void _setSortMode(_KitchenSortMode sortMode) {
    setState(() {
      _sortMode = sortMode;
    });
  }

  void _toggleCompleted(bool value) {
    setState(() {
      _showCompleted = value;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedStation = _KitchenStationFilter.all;
      _rushOnly = false;
      _showCompleted = false;
      _sortMode = _KitchenSortMode.oldest;
    });
    _showActionMessage(
      'Kitchen board filters reset.',
      backgroundColor: const Color(0xFF0F766E),
    );
  }

  void _focusTicket(_KitchenTicket ticket) {
    _searchController.text = ticket.orderId;
    setState(() {
      _searchQuery = ticket.orderId;
      _selectedStation = _KitchenStationFilter.fromStation(ticket.station);
      _showCompleted = ticket.status == _KitchenTicketStatus.completed;
    });
    _showActionMessage(
      'Focused ${ticket.orderId} at ${ticket.station.label}.',
      backgroundColor: const Color(0xFF0EA5E9),
    );
  }

  void _bumpPriority(_KitchenTicket ticket) {
    if (ticket.priority == _KitchenPriority.fire) {
      _showActionMessage(
        '${ticket.orderId} is already at fire priority.',
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }

    final nextPriority = ticket.priority == _KitchenPriority.normal
        ? _KitchenPriority.rush
        : _KitchenPriority.fire;

    _updateTicket(
      ticket,
      (current) => current.copyWith(
        priority: nextPriority,
        timeline: [
          ...current.timeline,
          _KitchenTicketEvent(
            timestamp: DateTime.now(),
            title: 'Priority escalated',
            detail:
                'Ticket escalated to ${nextPriority.label.toLowerCase()} priority.',
          ),
        ],
      ),
      message: '${ticket.orderId} bumped to ${nextPriority.label}.',
      messageColor: _priorityColor(nextPriority),
    );
  }

  void _reopenTicket(_KitchenTicket ticket) {
    _updateTicket(
      ticket,
      (current) => _ticketWithStatus(
        current,
        _KitchenTicketStatus.ready,
        eventTitle: 'Ticket reopened',
        eventDetail:
            'Handoff was reversed and the order was returned to the ready pass.',
      ),
      message: '${ticket.orderId} reopened to ready.',
      messageColor: const Color(0xFF15803D),
    );
  }

  void _handleTicketMenuAction(
    _KitchenTicketMenuAction action,
    _KitchenTicket ticket,
  ) {
    switch (action) {
      case _KitchenTicketMenuAction.details:
        _showTicketDetails(ticket);
        return;
      case _KitchenTicketMenuAction.bumpPriority:
        _bumpPriority(ticket);
        return;
      case _KitchenTicketMenuAction.focus:
        _focusTicket(ticket);
        return;
    }
  }

  void _showTicketDetails(_KitchenTicket ticket) {
    final currentTicket = _tickets.firstWhere(
      (current) => current.id == ticket.id,
      orElse: () => ticket,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final statusColor = _statusColor(currentTicket.status);
        final priorityColor = _priorityColor(currentTicket.priority);

        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentTicket.orderId,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${currentTicket.tableLabel} | ${currentTicket.customerName} | ${currentTicket.channelLabel}',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _LabelChip(
                              label: currentTicket.station.label,
                              background: const Color(0xFFE2E8F0),
                              foreground: const Color(0xFF0F172A),
                            ),
                            _LabelChip(
                              label: currentTicket.priority.label,
                              background: priorityColor.withValues(alpha: 0.14),
                              foreground: priorityColor,
                            ),
                            _LabelChip(
                              label: _statusLabel(currentTicket.status),
                              background: statusColor.withValues(alpha: 0.14),
                              foreground: statusColor,
                            ),
                            _LabelChip(
                              label: currentTicket.assignedChef,
                              background: const Color(0xFFE0F2FE),
                              foreground: const Color(0xFF0369A1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _StageStatCard(
                              label: 'Placed',
                              value: _formatClockTime(
                                currentTicket.placedAt,
                                context,
                              ),
                              accent: const Color(0xFFF97316),
                            ),
                            _StageStatCard(
                              label: 'Prep start',
                              value: currentTicket.prepStartedAt == null
                                  ? 'Pending'
                                  : _formatClockTime(
                                      currentTicket.prepStartedAt!,
                                      context,
                                    ),
                              accent: const Color(0xFF3B82F6),
                            ),
                            _StageStatCard(
                              label: 'Ready at',
                              value: currentTicket.readyAt == null
                                  ? 'Pending'
                                  : _formatClockTime(
                                      currentTicket.readyAt!,
                                      context,
                                    ),
                              accent: const Color(0xFF16A34A),
                            ),
                            _StageStatCard(
                              label: 'Elapsed',
                              value: _formatElapsed(currentTicket),
                              accent: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Items',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...currentTicket.items.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (item.notes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.notes,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (currentTicket.kitchenNote.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'Kitchen note: ${currentTicket.kitchenNote}',
                              style: const TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Timeline',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...currentTicket.timeline.reversed.map(
                          (event) => _TimelineEventTile(
                            title: event.title,
                            detail: event.detail,
                            timeLabel: _formatClockTime(
                              event.timestamp,
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expediteTicket = _expediteTicket;
    final boardColumns = _boardColumns;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KITCHEN DISPLAY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live line view | ${_formatNow(context)}',
              style: const TextStyle(color: Color(0xFF687385), fontSize: 13),
            ),
          ],
        ),
        actions: [
          if (!isCompact)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.wifi_tethering_rounded,
                    color: Color(0xFF5EEAD4),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kitchen online',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 16),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
            final padding = isCompact ? 12.0 : 20.0;
            final content = <Widget>[
              if (expediteTicket != null) ...[
                _ExpediteBanner(
                  ticket: expediteTicket,
                  elapsedLabel: _formatElapsed(expediteTicket),
                  onFocus: () => _focusTicket(expediteTicket),
                ),
                const SizedBox(height: 16),
              ],
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildMetrics(),
              const SizedBox(height: 16),
              _buildStationPulse(),
              const SizedBox(height: 16),
            ];

            if (isCompact) {
              return ListView(
                padding: EdgeInsets.all(padding),
                children: [
                  ...content,
                  ...List.generate(boardColumns.length * 2 - 1, (index) {
                    if (index.isOdd) return const SizedBox(height: 16);
                    final column = boardColumns[index ~/ 2];
                    return _StatusColumn(
                      title: column.title,
                      subtitle: column.subtitle,
                      accent: column.accent,
                      tickets: _ticketsFor(column.status),
                      emptyLabel: column.emptyLabel,
                      ticketBuilder: _buildTicketCard,
                      scrollable: false,
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  ...content,
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 1120) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              boardColumns.length * 2 - 1,
                              (index) {
                                if (index.isOdd) {
                                  return const SizedBox(width: 16);
                                }

                                final column = boardColumns[index ~/ 2];
                                return Expanded(
                                  child: _StatusColumn(
                                    title: column.title,
                                    subtitle: column.subtitle,
                                    accent: column.accent,
                                    tickets: _ticketsFor(column.status),
                                    emptyLabel: column.emptyLabel,
                                    ticketBuilder: _buildTicketCard,
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        return ListView(
                          children: List.generate(boardColumns.length * 2 - 1, (
                            index,
                          ) {
                            if (index.isOdd) {
                              return const SizedBox(height: 16);
                            }

                            final column = boardColumns[index ~/ 2];
                            return _StatusColumn(
                              title: column.title,
                              subtitle: column.subtitle,
                              accent: column.accent,
                              tickets: _ticketsFor(column.status),
                              emptyLabel: column.emptyLabel,
                              ticketBuilder: _buildTicketCard,
                              scrollable: false,
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 280,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search order, table, guest, item',
                    hintStyle: const TextStyle(color: Color(0xFF687385)),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: _searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFFBFCFE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),
              ),
              FilterChip(
                selected: _rushOnly,
                onSelected: _toggleRushOnly,
                avatar: Icon(
                  Icons.local_fire_department_rounded,
                  color: _rushOnly ? Colors.white : const Color(0xFFF97316),
                  size: 18,
                ),
                selectedColor: const Color(0xFF9A3412),
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                side: BorderSide.none,
                label: const Text('Rush orders'),
                labelStyle: const TextStyle(color: Color(0xFF111827)),
              ),
              FilterChip(
                selected: _showCompleted,
                onSelected: _toggleCompleted,
                avatar: Icon(
                  Icons.archive_rounded,
                  color: _showCompleted
                      ? Colors.white
                      : const Color(0xFFCBD5E1),
                  size: 18,
                ),
                selectedColor: const Color(0xFF334155),
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                side: BorderSide.none,
                label: Text('Completed ($_completedCount)'),
                labelStyle: const TextStyle(color: Color(0xFF111827)),
              ),
              ActionChip(
                onPressed: _hasFiltersApplied ? _clearFilters : null,
                avatar: const Icon(
                  Icons.restart_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                backgroundColor: _hasFiltersApplied
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF1E293B),
                disabledColor: const Color(0xFFF3F4F6),
                side: BorderSide.none,
                label: const Text(
                  'Clear filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.kitchen_rounded,
                      color: Color(0xFF687385),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Expo + grill synchronized',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _KitchenStationFilter.values.map((station) {
              final selected = station == _selectedStation;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => _changeStation(station),
                label: Text(station.label),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: const Color(0xFFFF4D0A),
                backgroundColor: Colors.white,
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Sort by',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              ..._KitchenSortMode.values.map((sortMode) {
                final selected = sortMode == _sortMode;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => _setSortMode(sortMode),
                  label: Text(sortMode.label),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: const Color(0xFF16A34A),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          title: 'Queue',
          value: '$_queueCount',
          detail: 'Tickets waiting to start',
          accent: const Color(0xFFF97316),
          icon: Icons.schedule_send_rounded,
        ),
        _MetricCard(
          title: 'Urgent',
          value: '$_urgentCount',
          detail: 'Beyond target cook time',
          accent: const Color(0xFFEF4444),
          icon: Icons.warning_amber_rounded,
        ),
        _MetricCard(
          title: 'Ready',
          value: '$_readyCount',
          detail: 'Awaiting service pickup',
          accent: const Color(0xFF22C55E),
          icon: Icons.room_service_rounded,
        ),
        _MetricCard(
          title: 'Completed',
          value: '$_completedCount',
          detail: _showCompleted
              ? 'Archive column visible'
              : 'Open archive to inspect',
          accent: const Color(0xFF94A3B8),
          icon: Icons.task_alt_rounded,
        ),
        _MetricCard(
          title: 'Average Age',
          value: '${_averageAgeMinutes}m',
          detail: 'Across active kitchen tickets',
          accent: AppTheme.primaryColor,
          icon: Icons.timer_outlined,
        ),
        _MetricCard(
          title: 'Fire Alerts',
          value: '$_fireCount',
          detail: 'Immediate chef attention needed',
          accent: const Color(0xFFF43F5E),
          icon: Icons.local_fire_department_rounded,
        ),
      ],
    );
  }

  Widget _buildStationPulse() {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.equalizer_rounded, color: Color(0xFF38BDF8)),
              SizedBox(width: 10),
              Text(
                'Station pulse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'A quick read of which stations are flowing smoothly and where attention is tightening.',
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _KitchenStation.values.map((station) {
              final stationTickets = _activeTickets
                  .where((ticket) => ticket.station == station)
                  .toList();
              final urgent = stationTickets
                  .where(
                    (ticket) => _elapsedMinutes(ticket) >= ticket.slaMinutes,
                  )
                  .length;
              final color = urgent > 0
                  ? const Color(0xFFF97316)
                  : stationTickets.isEmpty
                  ? const Color(0xFF64748B)
                  : const Color(0xFF22C55E);

              return Container(
                width: isCompact ? double.infinity : 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${stationTickets.length} active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      urgent > 0
                          ? '$urgent urgent ticket${urgent == 1 ? '' : 's'}'
                          : stationTickets.isEmpty
                          ? 'No current load'
                          : 'Within target window',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(_KitchenTicket ticket) {
    final elapsedMinutes = _elapsedMinutes(ticket);
    final overdue = elapsedMinutes >= ticket.slaMinutes;
    final statusColor = _statusColor(ticket.status);
    final priorityColor = _priorityColor(ticket.priority);
    final isCompleted = ticket.status == _KitchenTicketStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.orderId,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.tableLabel} | ${ticket.customerName} | ${ticket.channelLabel}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assigned to ${ticket.assignedChef}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_KitchenTicketMenuAction>(
                  onSelected: (action) =>
                      _handleTicketMenuAction(action, ticket),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _KitchenTicketMenuAction.details,
                      child: Text('View details'),
                    ),
                    PopupMenuItem(
                      value: _KitchenTicketMenuAction.bumpPriority,
                      child: Text('Escalate priority'),
                    ),
                    PopupMenuItem(
                      value: _KitchenTicketMenuAction.focus,
                      child: Text('Focus this ticket'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6, right: 8, top: 2),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: overdue && !isCompleted
                        ? const Color(0xFFFEE2E2)
                        : statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isCompleted && ticket.completedAt != null
                            ? _formatClockTime(ticket.completedAt!, context)
                            : _formatElapsed(ticket),
                        style: TextStyle(
                          color: overdue && !isCompleted
                              ? const Color(0xFFB91C1C)
                              : statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isCompleted ? 'Completed' : 'SLA ${ticket.slaMinutes}m',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LabelChip(
                  label: ticket.station.label,
                  background: const Color(0xFFE2E8F0),
                  foreground: const Color(0xFF0F172A),
                ),
                _LabelChip(
                  label: ticket.priority.label,
                  background: priorityColor.withValues(alpha: 0.15),
                  foreground: priorityColor,
                ),
                _LabelChip(
                  label: _statusLabel(ticket.status),
                  background: statusColor.withValues(alpha: 0.12),
                  foreground: statusColor,
                ),
                _LabelChip(
                  label: ticket.assignedChef,
                  background: const Color(0xFFE0F2FE),
                  foreground: const Color(0xFF0369A1),
                ),
                if (ticket.allergyTags.isNotEmpty)
                  ...ticket.allergyTags.map(
                    (tag) => _LabelChip(
                      label: tag,
                      background: const Color(0xFFFFEDD5),
                      foreground: const Color(0xFFC2410C),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ...ticket.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.notes.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.notes,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ticket.kitchenNote.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Kitchen note: ${ticket.kitchenNote}',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final detailsButton = OutlinedButton.icon(
                  onPressed: () => _showTicketDetails(ticket),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Details'),
                );
                final canMoveBack =
                    !isCompleted &&
                    ticket.status != _KitchenTicketStatus.newOrder;
                final backButton = OutlinedButton.icon(
                  onPressed: () => _moveBackward(ticket),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                );
                final forwardButton = ElevatedButton.icon(
                  onPressed: () => _moveForward(ticket),
                  icon: Icon(_nextActionIcon(ticket.status)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: Text(
                    _nextActionLabel(ticket.status),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                );

                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [detailsButton, if (canMoveBack) backButton],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: forwardButton),
                    ],
                  );
                }

                return Row(
                  children: [
                    detailsButton,
                    if (canMoveBack) ...[const SizedBox(width: 10), backButton],
                    const SizedBox(width: 10),
                    Expanded(child: forwardButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(_KitchenTicketStatus status) {
    switch (status) {
      case _KitchenTicketStatus.newOrder:
        return const Color(0xFFF97316);
      case _KitchenTicketStatus.preparing:
        return const Color(0xFF3B82F6);
      case _KitchenTicketStatus.ready:
        return const Color(0xFF16A34A);
      case _KitchenTicketStatus.completed:
        return const Color(0xFF475569);
    }
  }

  Color _priorityColor(_KitchenPriority priority) {
    switch (priority) {
      case _KitchenPriority.normal:
        return const Color(0xFF475569);
      case _KitchenPriority.rush:
        return const Color(0xFFF97316);
      case _KitchenPriority.fire:
        return const Color(0xFFDC2626);
    }
  }

  String _nextActionLabel(_KitchenTicketStatus status) {
    switch (status) {
      case _KitchenTicketStatus.newOrder:
        return 'Start prep';
      case _KitchenTicketStatus.preparing:
        return 'Mark ready';
      case _KitchenTicketStatus.ready:
        return 'Complete handoff';
      case _KitchenTicketStatus.completed:
        return 'Reopen ticket';
    }
  }

  IconData _nextActionIcon(_KitchenTicketStatus status) {
    switch (status) {
      case _KitchenTicketStatus.newOrder:
        return Icons.play_arrow_rounded;
      case _KitchenTicketStatus.preparing:
        return Icons.check_circle_outline_rounded;
      case _KitchenTicketStatus.ready:
        return Icons.done_all_rounded;
      case _KitchenTicketStatus.completed:
        return Icons.undo_rounded;
    }
  }

  String _statusLabel(_KitchenTicketStatus status) {
    switch (status) {
      case _KitchenTicketStatus.newOrder:
        return 'Queued';
      case _KitchenTicketStatus.preparing:
        return 'Preparing';
      case _KitchenTicketStatus.ready:
        return 'Ready';
      case _KitchenTicketStatus.completed:
        return 'Completed';
    }
  }
}

class _ExpediteBanner extends StatelessWidget {
  const _ExpediteBanner({
    required this.ticket,
    required this.elapsedLabel,
    required this.onFocus,
  });

  final _KitchenTicket ticket;
  final String elapsedLabel;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expedite now',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ticket.orderId} | ${ticket.tableLabel} | $elapsedLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ticket.station.label} station is beyond ${ticket.slaMinutes}m target.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: onFocus,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF991B1B),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: const Text('Focus station'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: isCompact ? double.infinity : 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF687385),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(detail, style: const TextStyle(color: Color(0xFF687385))),
        ],
      ),
    );
  }
}

class _StageStatCard extends StatelessWidget {
  const _StageStatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tickets,
    required this.emptyLabel,
    required this.ticketBuilder,
    this.scrollable = true,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<_KitchenTicket> tickets;
  final String emptyLabel;
  final Widget Function(_KitchenTicket ticket) ticketBuilder;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF687385)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tickets.length}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (scrollable)
            Expanded(
              child: tickets.isEmpty
                  ? _EmptyColumnState(label: emptyLabel, accent: accent)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) =>
                          ticketBuilder(tickets[index]),
                    ),
            )
          else
            tickets.isEmpty
                ? _EmptyColumnState(label: emptyLabel, accent: accent)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) =>
                        ticketBuilder(tickets[index]),
                  ),
        ],
      ),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({
    required this.title,
    required this.detail,
    required this.timeLabel,
  });

  final String title;
  final String detail;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0EA5E9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: Color(0xFF687385))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timeLabel,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumnState extends StatelessWidget {
  const _EmptyColumnState({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_rounded, color: accent, size: 28),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF687385),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KitchenBoardColumnData {
  const _KitchenBoardColumnData({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.status,
    required this.emptyLabel,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final _KitchenTicketStatus status;
  final String emptyLabel;
}

enum _KitchenTicketStatus { newOrder, preparing, ready, completed }

enum _KitchenPriority {
  normal('Normal'),
  rush('Rush'),
  fire('Fire');

  const _KitchenPriority(this.label);

  final String label;
  int get rank {
    switch (this) {
      case _KitchenPriority.normal:
        return 0;
      case _KitchenPriority.rush:
        return 1;
      case _KitchenPriority.fire:
        return 2;
    }
  }
}

enum _KitchenSortMode {
  oldest('Oldest first'),
  slaRisk('SLA risk'),
  priority('Priority');

  const _KitchenSortMode(this.label);

  final String label;
}

enum _KitchenTicketMenuAction { details, bumpPriority, focus }

enum _KitchenStation {
  grill('Grill'),
  curry('Curry'),
  tandoor('Tandoor'),
  pantry('Pantry'),
  expo('Expo');

  const _KitchenStation(this.label);

  final String label;
}

enum _KitchenStationFilter {
  all('All stations', null),
  grill('Grill', _KitchenStation.grill),
  curry('Curry', _KitchenStation.curry),
  tandoor('Tandoor', _KitchenStation.tandoor),
  pantry('Pantry', _KitchenStation.pantry),
  expo('Expo', _KitchenStation.expo);

  const _KitchenStationFilter(this.label, this.station);

  final String label;
  final _KitchenStation? station;

  static _KitchenStationFilter fromStation(_KitchenStation station) {
    for (final filter in values) {
      if (filter.station == station) {
        return filter;
      }
    }
    return _KitchenStationFilter.all;
  }
}

class _KitchenTicketItem {
  const _KitchenTicketItem({
    required this.name,
    required this.quantity,
    this.notes = '',
  });

  final String name;
  final int quantity;
  final String notes;
}

class _KitchenTicketEvent {
  const _KitchenTicketEvent({
    required this.timestamp,
    required this.title,
    required this.detail,
  });

  final DateTime timestamp;
  final String title;
  final String detail;
}

class _KitchenTicket {
  const _KitchenTicket({
    required this.id,
    required this.orderId,
    required this.tableLabel,
    required this.customerName,
    required this.channelLabel,
    required this.assignedChef,
    required this.station,
    required this.priority,
    required this.status,
    required this.placedAt,
    required this.slaMinutes,
    required this.items,
    this.kitchenNote = '',
    this.allergyTags = const [],
    this.prepStartedAt,
    this.readyAt,
    this.completedAt,
    this.timeline = const [],
  });

  factory _KitchenTicket.seed({
    required String id,
    required String orderId,
    required String tableLabel,
    required String customerName,
    required String channelLabel,
    required String assignedChef,
    required _KitchenStation station,
    required _KitchenPriority priority,
    required _KitchenTicketStatus status,
    required DateTime placedAt,
    required int slaMinutes,
    required List<_KitchenTicketItem> items,
    String kitchenNote = '',
    List<String> allergyTags = const [],
  }) {
    final now = DateTime.now();
    final prepStartedAt = status.index >= _KitchenTicketStatus.preparing.index
        ? _seedStageTime(
            placedAt,
            now,
            minutesAfterPlaced: status == _KitchenTicketStatus.preparing
                ? 1
                : 2,
          )
        : null;
    final readyAt = status.index >= _KitchenTicketStatus.ready.index
        ? _seedStageTime(
            placedAt,
            now,
            minutesAfterPlaced: status == _KitchenTicketStatus.ready ? 7 : 9,
          )
        : null;
    final completedAt = status == _KitchenTicketStatus.completed
        ? _seedStageTime(placedAt, now, minutesAfterPlaced: slaMinutes)
        : null;

    return _KitchenTicket(
      id: id,
      orderId: orderId,
      tableLabel: tableLabel,
      customerName: customerName,
      channelLabel: channelLabel,
      assignedChef: assignedChef,
      station: station,
      priority: priority,
      status: status,
      placedAt: placedAt,
      slaMinutes: slaMinutes,
      items: items,
      kitchenNote: kitchenNote,
      allergyTags: allergyTags,
      prepStartedAt: prepStartedAt,
      readyAt: readyAt,
      completedAt: completedAt,
      timeline: _buildSeedTimeline(
        orderId: orderId,
        assignedChef: assignedChef,
        station: station,
        status: status,
        placedAt: placedAt,
        prepStartedAt: prepStartedAt,
        readyAt: readyAt,
        completedAt: completedAt,
      ),
    );
  }

  final String id;
  final String orderId;
  final String tableLabel;
  final String customerName;
  final String channelLabel;
  final String assignedChef;
  final _KitchenStation station;
  final _KitchenPriority priority;
  final _KitchenTicketStatus status;
  final DateTime placedAt;
  final int slaMinutes;
  final List<_KitchenTicketItem> items;
  final String kitchenNote;
  final List<String> allergyTags;
  final DateTime? prepStartedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final List<_KitchenTicketEvent> timeline;

  _KitchenTicket copyWith({
    _KitchenTicketStatus? status,
    _KitchenPriority? priority,
    Object? prepStartedAt = _kitchenUnset,
    Object? readyAt = _kitchenUnset,
    Object? completedAt = _kitchenUnset,
    List<_KitchenTicketEvent>? timeline,
  }) {
    return _KitchenTicket(
      id: id,
      orderId: orderId,
      tableLabel: tableLabel,
      customerName: customerName,
      channelLabel: channelLabel,
      assignedChef: assignedChef,
      station: station,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      placedAt: placedAt,
      slaMinutes: slaMinutes,
      items: items,
      kitchenNote: kitchenNote,
      allergyTags: allergyTags,
      prepStartedAt: identical(prepStartedAt, _kitchenUnset)
          ? this.prepStartedAt
          : prepStartedAt as DateTime?,
      readyAt: identical(readyAt, _kitchenUnset)
          ? this.readyAt
          : readyAt as DateTime?,
      completedAt: identical(completedAt, _kitchenUnset)
          ? this.completedAt
          : completedAt as DateTime?,
      timeline: timeline ?? this.timeline,
    );
  }
}

List<_KitchenTicket> _buildSeedTickets() {
  final now = DateTime.now();

  return [
    _KitchenTicket.seed(
      id: 'kt-1',
      orderId: 'Order #2148',
      tableLabel: 'Table T5',
      customerName: 'Amit',
      channelLabel: 'Dine in',
      assignedChef: 'Chef Rohan',
      station: _KitchenStation.tandoor,
      priority: _KitchenPriority.rush,
      status: _KitchenTicketStatus.newOrder,
      placedAt: now.subtract(const Duration(minutes: 4, seconds: 12)),
      slaMinutes: 12,
      kitchenNote: 'Fire naan with mains.',
      items: const [
        _KitchenTicketItem(
          name: 'Paneer Tikka',
          quantity: 1,
          notes: 'Extra char',
        ),
        _KitchenTicketItem(
          name: 'Garlic Naan',
          quantity: 2,
          notes: 'No butter',
        ),
      ],
    ),
    _KitchenTicket.seed(
      id: 'kt-2',
      orderId: 'Order #2146',
      tableLabel: 'Table T2',
      customerName: 'Neha',
      channelLabel: 'Dine in',
      assignedChef: 'Chef Asha',
      station: _KitchenStation.curry,
      priority: _KitchenPriority.fire,
      status: _KitchenTicketStatus.preparing,
      placedAt: now.subtract(const Duration(minutes: 18, seconds: 30)),
      slaMinutes: 15,
      kitchenNote: 'Send dal first if biryani slips.',
      allergyTags: const ['No nuts'],
      items: const [
        _KitchenTicketItem(name: 'Veg Biryani', quantity: 1),
        _KitchenTicketItem(
          name: 'Dal Makhani',
          quantity: 1,
          notes: 'Less cream',
        ),
      ],
    ),
    _KitchenTicket.seed(
      id: 'kt-3',
      orderId: 'Order #2145',
      tableLabel: 'Zomato',
      customerName: 'Karan',
      channelLabel: 'Delivery',
      assignedChef: 'Chef Imran',
      station: _KitchenStation.grill,
      priority: _KitchenPriority.normal,
      status: _KitchenTicketStatus.preparing,
      placedAt: now.subtract(const Duration(minutes: 10, seconds: 45)),
      slaMinutes: 18,
      items: const [
        _KitchenTicketItem(name: 'Chicken Seekh Kebab', quantity: 2),
        _KitchenTicketItem(name: 'Mint Chutney', quantity: 2),
      ],
    ),
    _KitchenTicket.seed(
      id: 'kt-4',
      orderId: 'Order #2144',
      tableLabel: 'Table T8',
      customerName: 'Sara',
      channelLabel: 'Dine in',
      assignedChef: 'Chef Meera',
      station: _KitchenStation.pantry,
      priority: _KitchenPriority.rush,
      status: _KitchenTicketStatus.ready,
      placedAt: now.subtract(const Duration(minutes: 13, seconds: 5)),
      slaMinutes: 14,
      items: const [
        _KitchenTicketItem(
          name: 'Caesar Salad',
          quantity: 1,
          notes: 'Dressing on side',
        ),
        _KitchenTicketItem(name: 'Fresh Lime Soda', quantity: 2),
      ],
    ),
    _KitchenTicket.seed(
      id: 'kt-5',
      orderId: 'Order #2143',
      tableLabel: 'Swiggy',
      customerName: 'Ritika',
      channelLabel: 'Takeaway',
      assignedChef: 'Chef Rohan',
      station: _KitchenStation.expo,
      priority: _KitchenPriority.normal,
      status: _KitchenTicketStatus.newOrder,
      placedAt: now.subtract(const Duration(minutes: 2, seconds: 10)),
      slaMinutes: 10,
      kitchenNote: 'Seal bag with cutlery.',
      items: const [
        _KitchenTicketItem(name: 'Masala Fries', quantity: 1),
        _KitchenTicketItem(name: 'Veg Burger', quantity: 1, notes: 'No mayo'),
      ],
    ),
    _KitchenTicket.seed(
      id: 'kt-6',
      orderId: 'Order #2141',
      tableLabel: 'Table T1',
      customerName: 'Dev',
      channelLabel: 'Dine in',
      assignedChef: 'Chef Asha',
      station: _KitchenStation.curry,
      priority: _KitchenPriority.normal,
      status: _KitchenTicketStatus.ready,
      placedAt: now.subtract(const Duration(minutes: 9, seconds: 40)),
      slaMinutes: 16,
      items: const [
        _KitchenTicketItem(name: 'Butter Chicken', quantity: 1),
        _KitchenTicketItem(name: 'Jeera Rice', quantity: 2),
      ],
    ),
  ];
}

const Object _kitchenUnset = Object();

DateTime _seedStageTime(
  DateTime placedAt,
  DateTime now, {
  required int minutesAfterPlaced,
}) {
  final latestAllowed = now.subtract(const Duration(seconds: 20));
  final candidate = placedAt.add(Duration(minutes: minutesAfterPlaced));
  if (candidate.isAfter(latestAllowed)) {
    return latestAllowed.isBefore(placedAt) ? placedAt : latestAllowed;
  }
  return candidate;
}

List<_KitchenTicketEvent> _buildSeedTimeline({
  required String orderId,
  required String assignedChef,
  required _KitchenStation station,
  required _KitchenTicketStatus status,
  required DateTime placedAt,
  required DateTime? prepStartedAt,
  required DateTime? readyAt,
  required DateTime? completedAt,
}) {
  final events = <_KitchenTicketEvent>[
    _KitchenTicketEvent(
      timestamp: placedAt,
      title: 'Order queued',
      detail: '$orderId entered the ${station.label.toLowerCase()} queue.',
    ),
  ];

  if (prepStartedAt != null) {
    events.add(
      _KitchenTicketEvent(
        timestamp: prepStartedAt,
        title: 'Prep started',
        detail: '$assignedChef started the first prep pass.',
      ),
    );
  }

  if (readyAt != null) {
    events.add(
      _KitchenTicketEvent(
        timestamp: readyAt,
        title: 'Marked ready',
        detail: 'The order reached the ready pass.',
      ),
    );
  }

  if (completedAt != null || status == _KitchenTicketStatus.completed) {
    events.add(
      _KitchenTicketEvent(
        timestamp: completedAt ?? DateTime.now(),
        title: 'Handoff completed',
        detail: 'The order was handed to service or dispatch.',
      ),
    );
  }

  return events;
}
