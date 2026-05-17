import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/shared_fund.dart';
import '../../providers/shared_fund_provider.dart';
import '../../utils/formatters.dart';
import 'create_fund_screen.dart';
import 'fund_detail_screen.dart';
import '../../l10n/app_localizations.dart';

class SharedFundsScreen extends StatefulWidget {
  const SharedFundsScreen({super.key});

  @override
  State<SharedFundsScreen> createState() => _SharedFundsScreenState();
}

class _SharedFundsScreenState extends State<SharedFundsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SharedFundProvider>().loadFunds();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SharedFundProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.sharedFund),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFundScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.funds.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.funds.length,
                  itemBuilder: (_, i) => _buildFundCard(provider.funds[i]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.people, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            context.l10n.noFundsYet,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.add),
            label: Text(context.l10n.createFund),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2F80ED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFundScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundCard(SharedFund fund) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FundDetailScreen(fundId: fund.id)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xff2F80ED).withValues(alpha: 0.1),
                    child: const Icon(Iconsax.people, color: Color(0xff2F80ED)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fund.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${fund.memberCount} ${context.l10n.members}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fund.isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fund.isCompleted ? context.l10n.fundCompleted : context.l10n.contribute,
                      style: TextStyle(
                        color: fund.isCompleted ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// PROGRESS BAR
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fund.currentAmount > fund.targetAmount ? 1.0 : fund.progress,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    fund.currentAmount > fund.targetAmount
                        ? const Color(0xffF59E0B)
                        : fund.isCompleted
                            ? Colors.green
                            : const Color(0xff2F80ED),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),

              /// AMOUNT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(fund.currentAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: fund.currentAmount > fund.targetAmount
                          ? const Color(0xffF59E0B)
                          : const Color(0xff2F80ED),
                    ),
                  ),
                  Text(
                    '${context.l10n.fundTarget}: ${Formatters.currency(fund.targetAmount)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              if (fund.currentAmount > fund.targetAmount) ...[  
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xffF59E0B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${context.l10n.fundExceeded}: +${Formatters.currency(fund.currentAmount - fund.targetAmount)}',
                      style: const TextStyle(
                        color: Color(0xffF59E0B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],

              /// DEADLINE
              if (fund.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Iconsax.calendar, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${context.l10n.deadline}: ${Formatters.date(fund.deadline!)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
