import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'sos_prayer_request_view.dart';

class SOSCirclePickerView extends StatefulWidget {
  final List<CircleListItem> circles;
  const SOSCirclePickerView({super.key, required this.circles});

  @override
  State<SOSCirclePickerView> createState() => _SOSCirclePickerViewState();
}

class _SOSCirclePickerViewState extends State<SOSCirclePickerView> {
  CircleListItem? _selectedCircle;
  bool _isLoadingDetail = false;

  Future<void> _selectCircle(CircleListItem circle) async {
    setState(() { _selectedCircle = circle; _isLoadingDetail = true; });
    try {
      final detail = await APIService.shared.getCircleDetail(circle.id);
      if (!mounted) return;
      setState(() => _isLoadingDetail = false);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: TributeColor.charcoal,
        builder: (_) => SOSPrayerRequestView(circleId: detail.id, members: detail.members),
      );
    } catch (_) {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      appBar: AppBar(
        backgroundColor: TributeColor.charcoal,
        title: const Text('Send SOS',
            style: TextStyle(color: TributeColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        leadingWidth: 80,
      ),
      body: SafeArea(
        child: widget.circles.isEmpty ? _emptyState() : _circleList(),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_off_rounded, size: 36, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No circles yet', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Text(
            'Join or create a Prayer Circle first to send SOS requests.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)),
          ),
        ]),
      ),
    );
  }

  Widget _circleList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Choose which circle to send your prayer request to.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        Text('YOUR CIRCLES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ...widget.circles.map((circle) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _circleRow(circle),
            )),
      ],
    );
  }

  Widget _circleRow(CircleListItem circle) {
    final isLoading = _isLoadingDetail && _selectedCircle?.id == circle.id;
    return GestureDetector(
      onTap: isLoading ? null : () => _selectCircle(circle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: TributeDecorations.card,
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: TributeColor.golden.withValues(alpha: 0.1)),
            child: Center(
              child: Text(
                circle.name.isNotEmpty ? circle.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TributeColor.golden),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(circle.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
            Text('${circle.memberCount} members',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
          ])),
          if (isLoading)
            const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.golden))
          else
            Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}
