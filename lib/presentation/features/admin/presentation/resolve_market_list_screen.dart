import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/exception_extension.dart';

class ResolveMarketListScreen extends ConsumerStatefulWidget {
  const ResolveMarketListScreen({super.key});

  @override
  ConsumerState<ResolveMarketListScreen> createState() =>
      _ResolveMarketListScreenState();
}

class _ResolveMarketListScreenState
    extends ConsumerState<ResolveMarketListScreen> {
  List<Map<String, dynamic>> _markets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveMarkets();
  }

  Future<void> _fetchActiveMarkets() async {
    try {
      final res = await Supabase.instance.client
          .from('markets')
          .select()
          .eq('is_resolved', false)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _markets = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveMarket(String id, String outcome) async {
    try {
      await Supabase.instance.client.rpc(
        'resolve_market',
        params: {'p_market_id': id, 'p_outcome': outcome},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Market Resolved! Payouts processed. 💸'),
          ),
        );
        _fetchActiveMarkets(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toUserFriendlyMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showResolveDialog(Map<String, dynamic> market) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Market'),
        content: Text('Who won "${market['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              _resolveMarket(market['id'], 'Yes');
            },
            child: const Text('YES Won'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _resolveMarket(market['id'], 'No');
            },
            child: const Text('NO Won'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Resolve Markets',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).iconTheme.color),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _markets.isEmpty
          ? const Center(child: Text('No active markets'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _markets.length,
              itemBuilder: (context, index) {
                final m = _markets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Theme.of(context).cardColor,
                  child: ListTile(
                    title: Text(
                      m['title'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      'Ends: ${m['end_date'].split('T')[0]}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    trailing: const Icon(Icons.gavel, color: Colors.orange),
                    onTap: () => _showResolveDialog(m),
                  ),
                );
              },
            ),
    );
  }
}
