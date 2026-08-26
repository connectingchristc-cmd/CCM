import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import 'service_management_screen.dart';
import 'add_daily_bread_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.isAdmin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _dailyBreadIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'CONNECTING CHRIST MINISTRIES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: ccmRed,
        elevation: 0,
        toolbarHeight: 56,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ccmRed.withValues(alpha: 0.05),
              ccmWhite,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ================= SERVICES =================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SERVICES @ CCM',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                                color: ccmRed,
                                fontSize: 18,
                              ),
                        ),
                        if (widget.isAdmin)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ccmRed,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  8,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ServiceManagementScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.settings,
                              size: 16,
                            ),
                            label: const Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 11,
                                color: ccmWhite,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore
                          .instance
                          .collection('services')
                          .snapshots(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        final services =
                            snapshot.data?.docs ?? [];

                        final visibleServices =
                            services.where((doc) {
                          final data =
                              doc.data()
                                  as Map<String, dynamic>;

                          final isEnabled =
                              data['enabled'] ?? true;

                          return widget.isAdmin ||
                              isEnabled;
                        }).toList();

                        if (visibleServices
                            .isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                            child: Center(
                              child: Text(
                                'No services available',
                                style:
                                    Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (
                              int i = 0;
                              i <
                                  visibleServices.length;
                              i++
                            ) ...[
                              _buildServiceCardFromData(
                                context,
                                visibleServices[i]
                                        .data()
                                    as Map<String,
                                        dynamic>,
                                widget.isAdmin,
                              ),

                              if (i <
                                  visibleServices
                                          .length -
                                      1)
                                const SizedBox(
                                  height: 12,
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ================= DAILY BREAD =================
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAILY BREAD',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                                color: ccmBlue,
                                fontSize: 18,
                              ),
                        ),
                        if (widget.isAdmin)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ccmBlue,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  8,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddDailyBreadScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                            ),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 12,
                                color: ccmWhite,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore
                          .instance
                          .collection('daily_bread')
                          .orderBy(
                            'created_at',
                            descending: true,
                          )
                          .snapshots(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        final docs =
                            snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return _buildEmptyDailyBread();
                        }

                        if (_dailyBreadIndex >=
                            docs.length) {
                          _dailyBreadIndex =
                              docs.length - 1;
                        }

                        final item =
                            docs[_dailyBreadIndex]
                                    .data()
                                as Map<String,
                                    dynamic>;

                        return _buildDailyBreadCard(
                          context,
                          item,
                          docs.length,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SERVICE CARD =================

  Widget _buildServiceCardFromData(
    BuildContext context,
    Map<String, dynamic> service,
    bool isAdmin,
  ) {
    final bool isEnabled =
        service['enabled'] ?? true;

    final opacity =
        isEnabled ? 1.0 : 0.5;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ccmRed.withValues(
              alpha: 0.9 * opacity,
            ),
            ccmBlue.withValues(
              alpha: 0.7 * opacity,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.1 * opacity,
            ),
            blurRadius: 8,
          ),
        ],
      ),
      padding:
          const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ccmWhite.withValues(
                alpha: 0.2 * opacity,
              ),
            ),
            padding:
                const EdgeInsets.all(12),
            child: Icon(
              Icons.calendar_today,
              color: ccmWhite.withValues(
                alpha: opacity,
              ),
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service['title'] ??
                            'Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              ccmWhite.withValues(
                            alpha: opacity,
                          ),
                        ),
                      ),
                    ),

                    if (!isEnabled && isAdmin)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey[400],
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                        child: const Text(
                          'Disabled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  service['location'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        ccmWhite.withValues(
                      alpha: 0.9 * opacity,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                service['time'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      ccmWhite.withValues(
                    alpha: opacity,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= DAILY BREAD CARD =================

  Widget _buildDailyBreadCard(
    BuildContext context,
    Map<String, dynamic> item,
    int totalCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ccmBlue.withValues(
              alpha: 0.9,
            ),
            ccmRed.withValues(
              alpha: 0.7,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.1,
            ),
            blurRadius: 8,
          ),
        ],
      ),
      padding:
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (item['imageUrl'] != null &&
              item['imageUrl']
                  .toString()
                  .isNotEmpty)
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(8),
              child: Image.network(
                item['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    height: 200,
                    color: ccmLightGray,
                    child: const Center(
                      child: Icon(
                        Icons
                            .image_not_supported,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          Text(
            'Bible Verse',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: ccmWhite,
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            item['verse'] ??
                'No verse text',
            style: TextStyle(
              fontSize: 16,
              color:
                  ccmWhite.withValues(
                alpha: 0.95,
              ),
              fontStyle:
                  FontStyle.italic,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          if (item['reference'] != null)
            Text(
              '- ${item['reference']}',
              style: TextStyle(
                fontSize: 14,
                color:
                    ccmWhite.withValues(
                  alpha: 0.9,
                ),
                fontWeight:
                    FontWeight.w600,
              ),
            ),

          if (totalCount > 1) ...[
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: ccmWhite,
                  ),
                  onPressed: () {
                    setState(() {
                      _dailyBreadIndex =
                          (_dailyBreadIndex -
                                  1 +
                                  totalCount) %
                              totalCount;
                    });
                  },
                ),

                Text(
                  '${_dailyBreadIndex + 1} of $totalCount',
                  style: const TextStyle(
                    color: ccmWhite,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: ccmWhite,
                  ),
                  onPressed: () {
                    setState(() {
                      _dailyBreadIndex =
                          (_dailyBreadIndex + 1) %
                              totalCount;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ================= EMPTY DAILY BREAD =================

  Widget _buildEmptyDailyBread() {
    return Container(
      decoration: BoxDecoration(
        color: ccmLightGray,
        borderRadius:
            BorderRadius.circular(12),
      ),
      padding:
          const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.grey[400],
          ),

          const SizedBox(height: 16),

          Text(
            'No Daily Bread Yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(height: 8),

          Text(
            'Check back soon for today\'s bible verse',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }
}