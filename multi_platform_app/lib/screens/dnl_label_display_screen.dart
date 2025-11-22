import 'package:flutter/material.dart';
import '../services/dnl_data_aggregator.dart';
import '../widgets/dnl_label_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DNLLabelDisplayScreen extends StatefulWidget {
  final String appName;

  const DNLLabelDisplayScreen({super.key, required this.appName});

  @override
  State<DNLLabelDisplayScreen> createState() => _DNLLabelDisplayScreenState();
}

class _DNLLabelDisplayScreenState extends State<DNLLabelDisplayScreen> {
  final DNLDataAggregator _aggregator = DNLDataAggregator();
  Map<String, dynamic>? _aggregatedData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _aggregator.aggregateAppData(widget.appName);
      if (mounted) {
        setState(() {
          _aggregatedData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportAsPDF() async {
    if (_aggregatedData == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF
      final pdf = await _generatePDF();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Print or save
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final data = _aggregatedData!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 3)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Digital Nutrition Facts',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              data['app_name'] ?? 'Unknown App',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              data['os_type'] ?? 'Android',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Version: ${data['version'] ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'For ages ${data['age_rating'] ?? '12+'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Based on ${data['total_submissions']} submissions from ${data['total_testers']} testers',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 2),

                  // Average Daily Interruptions
                  _buildPDFSection(
                    'Average Daily Interruptions',
                    data['avg_interruptions']?.toString() ?? '0',
                  ),

                  // Privacy Section
                  _buildPDFSectionHeader('Privacy'),

                  // Permissions
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Text(
                      'Permissions Requested',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  ..._buildPDFPermissionsList(data['permissions']),

                  // Data Handling
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Text(
                      'Data Handling',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  _buildPDFDataRow(
                    'Data Collection',
                    data['data_collection'] ? 'Yes' : 'No',
                  ),
                  _buildPDFDataRow(
                    'Third Party Sharing',
                    data['third_party_sharing'] ? 'Yes' : 'No',
                  ),

                  // Device Resources
                  _buildPDFSectionHeader('Device Resources'),
                  _buildPDFDataRow(
                    'Battery Impact',
                    data['battery_impact'] ?? 'N/A',
                  ),
                  _buildPDFDataRow('Storage', data['storage'] ?? 'N/A'),

                  // Footer
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Text(
                      '* Based on aggregated data from real user submissions',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFSection(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
      ),
    );
  }

  pw.Widget _buildPDFDataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label), pw.Text(value)],
      ),
    );
  }

  List<pw.Widget> _buildPDFPermissionsList(dynamic permissions) {
    final List<pw.Widget> widgets = [];
    if (permissions is Map<String, dynamic>) {
      permissions.forEach((key, value) {
        final status = value['status'] ?? 'Unknown';
        final percentage = value['percentage'] ?? 0;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text(key), pw.Text('$status ($percentage%)')],
            ),
          ),
        );
      });
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DNL: ${widget.appName}'),
        actions: [
          if (_aggregatedData != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export as PDF',
              onPressed: _exportAsPDF,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Aggregating data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_aggregatedData == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Info Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Data Source',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This label is based on ${_aggregatedData!['total_submissions']} '
                          'submissions from ${_aggregatedData!['total_testers']} unique testers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // DNL Label Widget
                DNLLabelWidget(data: _aggregatedData!),

                const SizedBox(height: 24),

                // Export Buttons
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Export Options',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _exportAsPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export as PDF'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Label'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
