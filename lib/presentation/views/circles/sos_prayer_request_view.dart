import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/entities/circle.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../theme/app_theme.dart';

class SOSPrayerRequestView extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;

  const SOSPrayerRequestView({super.key, required this.circleId, required this.members});

  @override
  State<SOSPrayerRequestView> createState() => _SOSPrayerRequestViewState();
}

class _SOSPrayerRequestViewState extends State<SOSPrayerRequestView> {
  final _messageController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSending = false;
  String? _error;
  bool _sentSuccessfully = false;
  int _recipientCount = 0;

  static const _maxRecipients = 20;

  List<CircleMember> get _otherMembers {
    final myId = AuthService.shared.userId;
    return widget.members.where((m) => m.userId != myId).toList();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendSOS() async {
    setState(() { _isSending = true; _error = null; });
    final msg = _messageController.text.trim();
    final finalMsg = msg.isEmpty ? 'Please pray for me' : msg;
    try {
      final count = _selectedIds.length;
      await context.read<CircleRepository>().sendSOS(
          widget.circleId, finalMsg, _selectedIds.toList());
      if (!mounted) return;
      setState(() { _recipientCount = count; _sentSuccessfully = true; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: Text(_sentSuccessfully ? '' : 'SOS Prayer',
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_sentSuccessfully ? 'Done' : 'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        leadingWidth: 80,
      ),
      body: SafeArea(child: _sentSuccessfully ? _successView() : _composeView()),
    );
  }

  Widget _successView() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.sage.withValues(alpha: 0.12)),
        child: const Icon(Icons.back_hand_rounded, size: 36, color: MyWalkColor.sage),
      ),
      const SizedBox(height: 24),
      const Text('Prayer Request Sent',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
      const SizedBox(height: 8),
      Text(
        '$_recipientCount ${_recipientCount == 1 ? 'person has' : 'people have'} been asked to pray for you.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 24),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          '"Bear one another\'s burdens, and so fulfill the law of Christ."',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: MyWalkColor.softGold),
        ),
      ),
      const SizedBox(height: 8),
      Text('Galatians 6:2',
          style: TextStyle(fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.5))),
    ]);
  }

  Widget _composeView() {
    final others = _otherMembers;
    final allSelected = others.isNotEmpty &&
        _selectedIds.length == others.take(_maxRecipients).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Column(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyWalkColor.warmCoral.withValues(alpha: 0.12)),
              child: const Icon(Icons.campaign_rounded, size: 28, color: MyWalkColor.warmCoral),
            ),
            const SizedBox(height: 12),
            const Text('Request Urgent Prayer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
            const SizedBox(height: 4),
            Text('Select up to $_maxRecipients people who will be notified to pray for you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          const Text('Message',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
          const Spacer(),
          Text('${_messageController.text.length}/500',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: _messageController,
          onChanged: (_) => setState(() {}),
          maxLines: 4,
          maxLength: 500,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          style: const TextStyle(color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'Please pray for me...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true, fillColor: MyWalkColor.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: MyWalkColor.cardBorder, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: MyWalkColor.cardBorder, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: MyWalkColor.golden.withValues(alpha: 0.5), width: 1)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Text('Recipients',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
          const Spacer(),
          Text('${_selectedIds.length}/$_maxRecipients',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: _selectedIds.length >= _maxRecipients
                      ? MyWalkColor.warmCoral
                      : Colors.white.withValues(alpha: 0.4))),
        ]),
        const SizedBox(height: 8),
        if (others.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MyWalkColor.cardBackground, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.person_off_rounded, size: 14, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text('No other members in this circle yet.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ]),
          )
        else ...[
          TextButton(
            onPressed: () => setState(() {
              if (allSelected) {
                _selectedIds.clear();
              } else {
                _selectedIds.addAll(others.take(_maxRecipients).map((m) => m.userId));
              }
            }),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(children: [
              Icon(allSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 18,
                  color: allSelected ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text(
                allSelected
                    ? 'Deselect All'
                    : 'Select All (${others.take(_maxRecipients).length})',
                style: const TextStyle(fontSize: 13, color: MyWalkColor.warmWhite),
              ),
            ]),
          ),
          ...others.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _recipientRow(m),
              )),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.warning_amber, size: 14, color: MyWalkColor.warmCoral),
            const SizedBox(width: 6),
            Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral))),
          ]),
        ],
        const SizedBox(height: 24),
        Opacity(
          opacity: _selectedIds.isEmpty ? 0.5 : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedIds.isEmpty || _isSending) ? null : _sendSOS,
              icon: _isSending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Send SOS Prayer Request',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.warmCoral,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _recipientRow(CircleMember m) {
    final isSelected = _selectedIds.contains(m.userId);
    final isDisabled = !isSelected && _selectedIds.length >= _maxRecipients;
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : () => setState(() {
          if (isSelected) {
            _selectedIds.remove(m.userId);
          } else {
            _selectedIds.add(m.userId);
          }
        }),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? MyWalkColor.golden.withValues(alpha: 0.04) : MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? MyWalkColor.golden.withValues(alpha: 0.2) : MyWalkColor.cardBorder,
              width: 0.5,
            ),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? MyWalkColor.golden.withValues(alpha: 0.15) : MyWalkColor.cardBackground),
              child: Icon(Icons.person_rounded, size: 14,
                  color: isSelected ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Member',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite)),
              if (m.role == 'admin')
                const Text('Admin', style: TextStyle(fontSize: 11, color: MyWalkColor.golden)),
            ])),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: isSelected ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.15)),
          ]),
        ),
      ),
    );
  }
}
