import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:predixs/core/constants/app_colors.dart';
import 'package:predixs/core/services/paystack_service.dart';

class WithdrawalModal extends StatefulWidget {
  const WithdrawalModal({Key? key}) : super(key: key);

  @override
  State<WithdrawalModal> createState() => _WithdrawalModalState();
}

class _WithdrawalModalState extends State<WithdrawalModal> {
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();

  List<dynamic> _banks = [];
  String? _selectedBankCode;
  String? _selectedBankName;

  String? _resolvedAccountName;
  bool _isResolving = false;
  bool _isLoading = false;
  bool _banksLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchBanks();
    _accountController.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanks() async {
    try {
      final banks = await PaystackService().getBanks();

      // Inject Test Bank manually (Required for testing withdrawals without limits)
      // This ensures code '001' is available as requested by the error message.
      banks.insert(0, {
        'name': 'Paystack Test Bank (Code 001)',
        'code': '001',
        'active': true,
      });

      if (mounted) {
        setState(() {
          _banks = banks;
          _banksLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _banksLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load banks: ${e.toString()}')),
        );
      }
    }
  }

  void _onAccountChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (_accountController.text.length == 10 && _selectedBankCode != null) {
      _debounce = Timer(const Duration(milliseconds: 800), _resolveName);
    } else {
      if (_resolvedAccountName != null) {
        setState(() => _resolvedAccountName = null);
      }
    }
  }

  Future<void> _resolveName() async {
    setState(() => _isResolving = true);
    try {
      final name = await PaystackService().resolveAccount(
        _accountController.text,
        _selectedBankCode!,
      );
      if (mounted) {
        if (name == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account details not found. Please verify."),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() {
          _resolvedAccountName = name;
        });
      }
    } catch (e) {
      debugPrint("Name Resolution Error: $e");
      if (mounted) {
        setState(() {
          _resolvedAccountName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${e.toString().replaceAll("Exception: ", "")}\n(Bank: $_selectedBankCode, Acc: ${_accountController.text})",
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is ₦100')),
      );
      return;
    }
    if (_resolvedAccountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify account details first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PaystackService().withdrawFunds(
        amount: amount,
        bankCode: _selectedBankCode!,
        bankName: _selectedBankName!,
        accountNumber: _accountController.text,
        accountName: _resolvedAccountName!,
      );

      if (mounted) {
        Navigator.pop(context, true); // Success signal
      }
    } catch (e) {
      debugPrint("Withdrawal logic caught error: $e");
      String msg = e.toString();

      // Check for KYC Error (String match from Edge Function response or Exception details)
      if (msg.contains("KYC Verification Required")) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Verification Required 🔒"),
              content: const Text(
                "Your identity verification is incomplete.\n\n"
                "To ensure the security of your funds, you must verify your NIN before making a withdrawal.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Optionally navigate to Verification Screen if it exists
                    // Navigator.pushNamed(context, '/profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    "I Understand",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Generic Clean up
      // Extract "message" from FunctionException if possible, or use raw string
      if (msg.contains("details:")) {
        // Try to regex extract the inner message if it looks like JSON-ish
        final match = RegExp(r'error:\s*([^,}]+)').firstMatch(msg);
        if (match != null) {
          msg = match.group(1) ?? msg;
        }
      }
      msg = msg
          .replaceAll("Exception: ", "")
          .replaceAll("FunctionException", "")
          .trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24, // Keyboard padding
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Withdraw Funds',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Bank Select
          DropdownButtonFormField<String>(
            value: _selectedBankCode,
            decoration: InputDecoration(
              labelText: 'Select Bank',
              labelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            dropdownColor: Theme.of(context).cardColor,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            items: _banks.map((b) {
              return DropdownMenuItem<String>(
                value: b['code'] as String,
                child: SizedBox(
                  width: 250,
                  child: Text(
                    b['name'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                onTap: () {
                  _selectedBankName = b['name'];
                },
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBankCode = val;
                _resolvedAccountName = null;
              });
              // Retrigger resolve if account entered
              _onAccountChanged();
            },
            hint: _banksLoading
                ? Text(
                    "Loading banks...",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  )
                : Text(
                    "Choose Bank",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Account Number
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: 'Account Number',
              labelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              border: const OutlineInputBorder(),
              counterText: "",
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              suffixIcon: _isResolving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _resolvedAccountName != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),

          if (_resolvedAccountName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _resolvedAccountName!,
                style: GoogleFonts.inter(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount to Withdraw (₦)',
              labelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              border: const OutlineInputBorder(),
              prefixStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              prefixText: '₦ ',
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || _resolvedAccountName == null)
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Withdraw Now',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
