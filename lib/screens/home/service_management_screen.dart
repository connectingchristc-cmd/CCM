import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/notification_service.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState
    extends State<ServiceManagementScreen> {
  Future<void> _deleteService(
    String serviceId,
    String serviceName,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "$serviceName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Service deleted successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting service: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleServiceStatus(
    String serviceId,
    bool currentStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .update({
        'enabled': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Service ${!currentStatus ? 'enabled' : 'disabled'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating service: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ccmRed,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('services')
                    .snapshots(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ccmRed,
                      ),
                    );
                  }

                  final services =
                      snapshot.data?.docs ?? [];

                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[300],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'No services yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: ccmRed,
                            ),
                            onPressed:
                                _showAddServiceDialog,
                            icon:
                                const Icon(Icons.add),
                            label: const Text(
                              'Create Service',
                              style: TextStyle(
                                color: ccmWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount: services.length,
                    itemBuilder:
                        (context, index) {
                      final service =
                          services[index].data()
                              as Map<String, dynamic>;

                      final serviceId =
                          services[index].id;

                      final isEnabled =
                          service['enabled'] ?? true;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: isEnabled
                                ? ccmRed
                                : Colors.grey[400],
                          ),

                          title: Text(
                            service['title'] ??
                                'Service',
                          ),

                          subtitle: Text(
                            '${service['location'] ?? ''} • '
                            '${service['time'] ?? ''}',
                          ),

                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isEnabled
                                      ? Icons.visibility
                                      : Icons
                                          .visibility_off,
                                  color: isEnabled
                                      ? ccmBlue
                                      : Colors.grey[400],
                                ),
                                onPressed: () =>
                                    _toggleServiceStatus(
                                  serviceId,
                                  isEnabled,
                                ),
                                tooltip: isEnabled
                                    ? 'Disable'
                                    : 'Enable',
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteService(
                                  serviceId,
                                  service['title'] ??
                                      'Service',
                                ),
                              ),
                            ],
                          ),

                          onTap: () =>
                              _showEditServiceDialog(
                            serviceId,
                            service,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ccmRed,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _showAddServiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add New Service',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color: ccmWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServiceDialog() {
    final titleController =
        TextEditingController();

    final locationController =
        TextEditingController();

    final timeController =
        TextEditingController();

    bool sendNotification = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) =>
            AlertDialog(
          title:
              const Text('Add New Service'),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextField(
                  controller:
                      titleController,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Service Title',
                    hintText:
                        'e.g., Sunday Service',
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      borderSide:
                          const BorderSide(
                        color: ccmRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      locationController,
                  decoration:
                      InputDecoration(
                    labelText: 'Location',
                    hintText:
                        'e.g., Konnembattu',
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      borderSide:
                          const BorderSide(
                        color: ccmRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      timeController,
                  decoration:
                      InputDecoration(
                    labelText: 'Time',
                    hintText:
                        'e.g., 10:30 AM',
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      borderSide:
                          const BorderSide(
                        color: ccmRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                CheckboxListTile(
                  value:
                      sendNotification,

                  onChanged: (val) =>
                      setDialogState(
                    () {
                      sendNotification =
                          val ?? false;
                    },
                  ),

                  title: const Text(
                    'Send notification to members',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  activeColor: ccmRed,

                  contentPadding:
                      EdgeInsets.zero,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: ccmRed,
              ),

              onPressed: () async {
                final title =
                    titleController.text
                        .trim();

                final loc =
                    locationController.text
                        .trim();

                final time =
                    timeController.text
                        .trim();

                if (title.isEmpty ||
                    loc.isEmpty ||
                    time.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill all fields',
                      ),
                      backgroundColor:
                          Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore
                      .instance
                      .collection(
                        'services',
                      )
                      .add({
                    'title': title,
                    'location': loc,
                    'time': time,
                    'enabled': true,
                    'created_at':
                        FieldValue
                            .serverTimestamp(),
                  });

                  if (sendNotification) {
                    await sendNotificationRecord(
                      title:
                          'New Service Scheduled',
                      body:
                          '$title at $loc on $time',
                      category:
                          'service',
                    );
                  }

                  if (mounted) {
                    Navigator.pop(
                      context,
                    );

                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Service created successfully!',
                        ),
                        backgroundColor:
                            Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: $e',
                        ),
                        backgroundColor:
                            Colors.red,
                      ),
                    );
                  }
                }
              },

              child: const Text(
                'Create',
                style: TextStyle(
                  color: ccmWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(
    String serviceId,
    Map<String, dynamic> service,
  ) {
    final titleController =
        TextEditingController(
      text: service['title'] ?? '',
    );

    final locationController =
        TextEditingController(
      text: service['location'] ?? '',
    );

    final timeController =
        TextEditingController(
      text: service['time'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Edit Service'),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller:
                    titleController,
                decoration:
                    InputDecoration(
                  labelText:
                      'Service Title',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    borderSide:
                        const BorderSide(
                      color: ccmRed,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    locationController,
                decoration:
                    InputDecoration(
                  labelText: 'Location',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    borderSide:
                        const BorderSide(
                      color: ccmRed,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    timeController,
                decoration:
                    InputDecoration(
                  labelText: 'Time',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    borderSide:
                        const BorderSide(
                      color: ccmRed,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Cancel'),
          ),

          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor: ccmRed,
            ),

            onPressed: () async {
              final title =
                  titleController.text
                      .trim();

              final location =
                  locationController.text
                      .trim();

              final time =
                  timeController.text
                      .trim();

              if (title.isEmpty ||
                  location.isEmpty ||
                  time.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill all fields',
                    ),
                    backgroundColor:
                        Colors.red,
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore
                    .instance
                    .collection(
                      'services',
                    )
                    .doc(serviceId)
                    .update({
                  'title': title,
                  'location': location,
                  'time': time,
                });

                if (mounted) {
                  Navigator.pop(
                    context,
                  );

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Service updated successfully!',
                      ),
                      backgroundColor:
                          Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error updating service: $e',
                      ),
                      backgroundColor:
                          Colors.red,
                    ),
                  );
                }
              }
            },

            child: const Text(
              'Update',
              style: TextStyle(
                color: ccmWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}